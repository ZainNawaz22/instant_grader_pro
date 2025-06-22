import 'dart:io' as io;
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:instant_grader_pro/omr_engine/detectors/darkness_detector.dart';
import 'package:image/image.dart' as img;
import 'package:instant_grader_pro/omr_engine/models/omr_result.dart';

// This top-level function is required for the `compute` function.
// It decodes the image bytes in a separate isolate.
img.Image? _decodeImageInBackground(List<int> imageBytes) {
  return img.decodeImage(Uint8List.fromList(imageBytes));
}

class OmrProcessor {
  static Future<List<OmrResult>> processImage(String imagePath) async {
    final stopwatch = Stopwatch()..start();
    
    final imageFile = io.File(imagePath);
    if (!await imageFile.exists()) {
      throw Exception("File not found at path: $imagePath");
    }
    
    final imageBytes = await imageFile.readAsBytes();
    final originalImage = await compute(_decodeImageInBackground, imageBytes);

    if (originalImage == null) {
      throw Exception("Could not decode image from path: $imagePath");
    }

    debugPrint('Image loaded in ${stopwatch.elapsedMilliseconds}ms');

    // Resize for processing while maintaining quality
    img.Image image = originalImage;
    const int maxDim = 1200;  // Increased for better corner detection
    if (image.width > maxDim || image.height > maxDim) {
      final double scale = math.min(maxDim / image.width, maxDim / image.height);
      final int newWidth = (image.width * scale).round();
      final int newHeight = (image.height * scale).round();
      debugPrint('Resizing image from ${image.width}x${image.height} to ${newWidth}x${newHeight}');
      image = img.copyResize(image, width: newWidth, height: newHeight);
    }

    debugPrint('Image resized in ${stopwatch.elapsedMilliseconds}ms');

    // Step 1: Detect corner alignment points
    final corners = _detectCornerPoints(image);
    debugPrint('Corner detection done in ${stopwatch.elapsedMilliseconds}ms');
    
    if (corners.length != 4) {
      debugPrint('Warning: Found ${corners.length} corners instead of 4. Using fallback method.');
      return _fallbackGridDetection(image);
    }
    
    // Step 2: Apply perspective correction
    final correctedImage = _correctPerspective(image, corners);
    debugPrint('Perspective correction done in ${stopwatch.elapsedMilliseconds}ms');
    
    // Step 3: Enhanced preprocessing
    final preprocessedImage = _enhancedPreprocess(correctedImage);
    debugPrint('Preprocessing done in ${stopwatch.elapsedMilliseconds}ms');
    
    // Step 4: Precise grid detection on corrected image
    final results = _preciseGridDetection(preprocessedImage);
    debugPrint('Grid detection done in ${stopwatch.elapsedMilliseconds}ms');
    
    _printResults(results, stopwatch.elapsedMilliseconds);
    return results;
  }
  
  static List<Point> _detectCornerPoints(img.Image image) {
    // Convert to grayscale for corner detection
    final grayImage = img.grayscale(image);
    
    // Apply strong contrast for better corner detection
    final contrastImage = img.adjustColor(grayImage, contrast: 2.0);
    
    // Detect dark circular regions (corner markers)
    final corners = <Point>[];
    final binaryImage = _simpleBinaryThreshold(contrastImage, 80); // Lower threshold for dark corners
    
    // Look for corners in each quadrant
    final quadrants = [
      Rectangle(0, 0, image.width ~/ 3, image.height ~/ 3), // Top-left
      Rectangle(image.width * 2 ~/ 3, 0, image.width ~/ 3, image.height ~/ 3), // Top-right
      Rectangle(0, image.height * 2 ~/ 3, image.width ~/ 3, image.height ~/ 3), // Bottom-left
      Rectangle(image.width * 2 ~/ 3, image.height * 2 ~/ 3, image.width ~/ 3, image.height ~/ 3), // Bottom-right
    ];
    
    for (final quadrant in quadrants) {
      final corner = _findCornerInQuadrant(binaryImage, quadrant);
      if (corner != null) {
        corners.add(corner);
      }
    }
    
    debugPrint('Detected ${corners.length} corner points: ${corners.map((c) => '(${c.x}, ${c.y})').join(', ')}');
    return corners;
  }
  
  static img.Image _simpleBinaryThreshold(img.Image image, int threshold) {
    final result = img.Image(width: image.width, height: image.height);
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = img.getLuminance(pixel);
        
        final newPixel = luminance < threshold 
            ? img.ColorRgb8(0, 0, 0) 
            : img.ColorRgb8(255, 255, 255);
        result.setPixel(x, y, newPixel);
      }
    }
    
    return result;
  }
  
  static Point? _findCornerInQuadrant(img.Image binaryImage, Rectangle quadrant) {
    final regions = <CircularRegion>[];
    final visited = List.generate(binaryImage.height, (_) => List<bool>.filled(binaryImage.width, false));
    
    for (int y = quadrant.top; y < quadrant.top + quadrant.height && y < binaryImage.height; y++) {
      for (int x = quadrant.left; x < quadrant.left + quadrant.width && x < binaryImage.width; x++) {
        if (!visited[y][x]) {
          final pixel = binaryImage.getPixel(x, y);
          final luminance = img.getLuminance(pixel);
          
          if (luminance < 128) { // Dark pixel
            final region = _traceRegion(binaryImage, x, y, visited);
            
            // Look for corner markers (circular regions of appropriate size)
            if (region.area >= 50 && region.area <= 500 && _isCircularRegion(region)) {
              regions.add(region);
            }
          }
        }
      }
    }
    
    // Return the largest circular region as the corner point
    if (regions.isNotEmpty) {
      regions.sort((a, b) => b.area.compareTo(a.area));
      final corner = regions.first;
      return Point(corner.centerX.round(), corner.centerY.round());
    }
    
    return null;
  }
  
  static CircularRegion _traceRegion(img.Image image, int startX, int startY, List<List<bool>> visited) {
    final points = <Point>[];
    final queue = <Point>[Point(startX, startY)];
    
    int minX = startX, maxX = startX, minY = startY, maxY = startY;
    
    while (queue.isNotEmpty) {
      final point = queue.removeAt(0);
      
      if (point.x < 0 || point.x >= image.width || point.y < 0 || point.y >= image.height) continue;
      if (visited[point.y][point.x]) continue;
      
      final pixel = image.getPixel(point.x, point.y);
      final luminance = img.getLuminance(pixel);
      
      if (luminance >= 128) continue;
      
      visited[point.y][point.x] = true;
      points.add(point);
      
      minX = math.min(minX, point.x);
      maxX = math.max(maxX, point.x);
      minY = math.min(minY, point.y);
      maxY = math.max(maxY, point.y);
      
      // Add 4-connected neighbors
      queue.add(Point(point.x + 1, point.y));
      queue.add(Point(point.x - 1, point.y));
      queue.add(Point(point.x, point.y + 1));
      queue.add(Point(point.x, point.y - 1));
    }
    
    return CircularRegion(
      points: points,
      centerX: (minX + maxX) / 2,
      centerY: (minY + maxY) / 2,
      width: maxX - minX,
      height: maxY - minY,
      area: points.length,
    );
  }
  
  static bool _isCircularRegion(CircularRegion region) {
    // Check aspect ratio (should be close to 1 for circles)
    final aspectRatio = region.width / region.height;
    if (aspectRatio < 0.7 || aspectRatio > 1.3) return false;
    
    // Check area vs bounding box (circles should fill ~78% of bounding box)
    final boundingBoxArea = region.width * region.height;
    final areaRatio = region.area / boundingBoxArea;
    
    return areaRatio > 0.5 && areaRatio < 0.9; // Relaxed for real-world conditions
  }
  
  static img.Image _correctPerspective(img.Image image, List<Point> corners) {
    if (corners.length != 4) return image;
    
    // Sort corners: top-left, top-right, bottom-right, bottom-left
    final sortedCorners = _sortCorners(corners);
    
    // Define target rectangle (corrected perspective)
    const int targetWidth = 800;
    const int targetHeight = 600;
    
    // Simple perspective correction using bilinear interpolation
    final corrected = img.Image(width: targetWidth, height: targetHeight);
    
    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        // Map target coordinates to source coordinates
        final sourcePoint = _mapToSourceCoordinates(
          x / targetWidth, 
          y / targetHeight, 
          sortedCorners
        );
        
        if (sourcePoint.x >= 0 && sourcePoint.x < image.width && 
            sourcePoint.y >= 0 && sourcePoint.y < image.height) {
          final pixel = image.getPixel(sourcePoint.x.round(), sourcePoint.y.round());
          corrected.setPixel(x, y, pixel);
        } else {
          corrected.setPixel(x, y, img.ColorRgb8(255, 255, 255)); // White background
        }
      }
    }
    
    debugPrint('Perspective corrected to ${targetWidth}x$targetHeight');
    return corrected;
  }
  
  static List<Point> _sortCorners(List<Point> corners) {
    // Sort corners clockwise starting from top-left
    corners.sort((a, b) {
      final angleA = math.atan2(a.y - 300, a.x - 400); // Rough center
      final angleB = math.atan2(b.y - 300, b.x - 400);
      return angleA.compareTo(angleB);
    });
    
    // Find top-left (minimum x + y)
    final topLeft = corners.reduce((a, b) => (a.x + a.y) < (b.x + b.y) ? a : b);
    final startIndex = corners.indexOf(topLeft);
    
    // Reorder starting from top-left
    final sorted = <Point>[];
    for (int i = 0; i < 4; i++) {
      sorted.add(corners[(startIndex + i) % 4]);
    }
    
    return sorted;
  }
  
  static Point _mapToSourceCoordinates(double u, double v, List<Point> corners) {
    // Bilinear interpolation to map normalized coordinates to source
    final topLeft = corners[0];
    final topRight = corners[1];
    final bottomRight = corners[2];
    final bottomLeft = corners[3];
    
    // Interpolate top and bottom edges
    final topX = topLeft.x + u * (topRight.x - topLeft.x);
    final topY = topLeft.y + u * (topRight.y - topLeft.y);
    
    final bottomX = bottomLeft.x + u * (bottomRight.x - bottomLeft.x);
    final bottomY = bottomLeft.y + u * (bottomRight.y - bottomLeft.y);
    
    // Interpolate between top and bottom
    final x = topX + v * (bottomX - topX);
    final y = topY + v * (bottomY - topY);
    
    return Point(x.round(), y.round());
  }
  
  static img.Image _enhancedPreprocess(img.Image image) {
    // Enhanced preprocessing for better bubble detection
    img.Image processed = img.grayscale(image);
    
    // Apply stronger contrast for better bubble separation
    processed = img.adjustColor(processed, contrast: 1.4, brightness: 1.0);
    
    // Apply slight blur to reduce noise
    processed = img.gaussianBlur(processed, radius: 1);
    
    return processed;
  }
  
  static List<OmrResult> _preciseGridDetection(img.Image image) {
    final results = <OmrResult>[];
    
    // More precise grid calculation for corrected image
    const int rows = 5;
    const int cols = 4;
    
    // Adjust margins for the corrected perspective
    final marginX = (image.width * 0.12).round();  // 12% left margin
    final marginY = (image.height * 0.08).round(); // 8% top margin
    
    final rightMargin = (image.width * 0.05).round(); // 5% right margin
    final bottomMargin = (image.height * 0.08).round(); // 8% bottom margin
    
    final gridWidth = image.width - marginX - rightMargin;
    final gridHeight = image.height - marginY - bottomMargin;
    
    final cellWidth = gridWidth ~/ cols;
    final cellHeight = gridHeight ~/ rows;
    
    debugPrint('Precise grid: ${cellWidth}x$cellHeight cells, margins: ($marginX, $marginY)');
    
    // Analyze each bubble with enhanced accuracy
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final x = marginX + col * cellWidth;
        final y = marginY + row * cellHeight;
        
        // Focus on bubble area (center 70% of cell)
        final bubbleMargin = (cellWidth * 0.15).round();
        final bubbleSize = (cellWidth * 0.7).round();
        
        final bubbleX = x + bubbleMargin;
        final bubbleY = y + bubbleMargin;
        final bubbleWidth = math.min(bubbleSize, cellWidth - 2 * bubbleMargin);
        final bubbleHeight = math.min(bubbleSize, cellHeight - 2 * bubbleMargin);
        
        final roi = _extractROI(image, Rectangle(bubbleX, bubbleY, bubbleWidth, bubbleHeight));
        
        // Enhanced darkness analysis
        final darknessScore = _enhancedDarknessAnalysis(roi);
        const double threshold = 0.3; // Adjusted threshold
        final isMarked = darknessScore >= threshold;
        
        results.add(OmrResult(
          rowIndex: row,
          colIndex: col,
          isMarked: isMarked,
          confidence: darknessScore,
        ));
      }
    }
    
    return results;
  }
  
  static double _enhancedDarknessAnalysis(img.Image roi) {
    if (roi.width <= 5 || roi.height <= 5) return 0.0;
    
    // Multi-sample analysis for better accuracy
    final samples = <double>[];
    
    // Center region (most important)
    final centerX = roi.width ~/ 2;
    final centerY = roi.height ~/ 2;
    final centerRadius = math.min(roi.width, roi.height) ~/ 4;
    
    for (int dy = -centerRadius; dy <= centerRadius; dy += 2) {
      for (int dx = -centerRadius; dx <= centerRadius; dx += 2) {
        final x = centerX + dx;
        final y = centerY + dy;
        
        if (x >= 0 && x < roi.width && y >= 0 && y < roi.height) {
          samples.add(_getPixelDarkness(roi, x, y));
        }
      }
    }
    
    if (samples.isEmpty) return 0.0;
    
    // Calculate average with emphasis on darkest pixels
    samples.sort((a, b) => b.compareTo(a)); // Sort by darkness (descending)
    
    // Weight the darkest 60% more heavily
    final cutoff = (samples.length * 0.6).round();
    final topSamples = samples.take(cutoff).toList();
    final bottomSamples = samples.skip(cutoff).toList();
    
    final topAvg = topSamples.isNotEmpty ? topSamples.reduce((a, b) => a + b) / topSamples.length : 0.0;
    final bottomAvg = bottomSamples.isNotEmpty ? bottomSamples.reduce((a, b) => a + b) / bottomSamples.length : 0.0;
    
    // Weighted average (70% from darkest pixels, 30% from rest)
    return 0.7 * topAvg + 0.3 * bottomAvg;
  }
  
  static List<OmrResult> _fallbackGridDetection(img.Image image) {
    debugPrint('Using fallback grid detection');
    // Use the previous grid-based approach when corners aren't detected
    final preprocessedImage = _enhancedPreprocess(image);
    return _preciseGridDetection(preprocessedImage);
  }
  
  static void _printResults(List<OmrResult> results, int processingTime) {
    debugPrint("=== OMR Processing Summary ===");
    debugPrint("Total processing time: ${processingTime}ms");
    debugPrint("Marked bubbles: ${results.where((r) => r.isMarked).length}");
    
    // Group and print results
    final groupedResults = <int, List<OmrResult>>{};
    for (final result in results) {
      final question = result.rowIndex + 1;
      groupedResults[question] ??= [];
      groupedResults[question]!.add(result);
    }
    
    for (int q = 1; q <= groupedResults.length; q++) {
      final questionResults = groupedResults[q] ?? [];
      final markedOptions = questionResults.where((r) => r.isMarked).toList();
      
      if (markedOptions.isNotEmpty) {
        for (final marked in markedOptions) {
          final option = String.fromCharCode('A'.codeUnitAt(0) + marked.colIndex);
          debugPrint("Q$q: $option (confidence: ${marked.confidence.toStringAsFixed(2)})");
        }
      } else {
        debugPrint("Q$q: No answer detected");
      }
    }
    debugPrint("==============================");
  }
  
  // Keep existing helper methods
  static img.Image _extractROI(img.Image image, Rectangle rect) {
    final x = math.max(0, rect.left);
    final y = math.max(0, rect.top);
    final width = math.min(rect.width, image.width - x);
    final height = math.min(rect.height, image.height - y);
    
    if (width <= 0 || height <= 0) {
      return img.Image(width: 10, height: 10);
    }
    
    return img.copyCrop(image, x: x, y: y, width: width, height: height);
  }
  
  static double _getPixelDarkness(img.Image image, int x, int y) {
    if (x >= image.width || y >= image.height || x < 0 || y < 0) return 0.0;
    
    final pixel = image.getPixel(x, y);
    final luminance = img.getLuminance(pixel);
    return 1.0 - (luminance / 255.0);
  }
}

class CircularRegion {
  final List<Point> points;
  final double centerX;
  final double centerY;
  final int width;
  final int height;
  final int area;
  
  CircularRegion({
    required this.points,
    required this.centerX,
    required this.centerY,
    required this.width,
    required this.height,
    required this.area,
  });
}

class Point {
  final int x;
  final int y;
  
  Point(this.x, this.y);
}

class Rectangle {
  final int left;
  final int top;
  final int width;
  final int height;
  
  Rectangle(this.left, this.top, this.width, this.height);
}
