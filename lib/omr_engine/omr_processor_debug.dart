import 'dart:io' as io;
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:instant_grader_pro/omr_engine/detectors/darkness_detector.dart';
import 'package:image/image.dart' as img;
import 'package:instant_grader_pro/omr_engine/models/omr_result.dart';
import 'package:path_provider/path_provider.dart';

img.Image? _decodeImageInBackground(List<int> imageBytes) {
  return img.decodeImage(Uint8List.fromList(imageBytes));
}

class OmrProcessorDebug {
  static Future<List<OmrResult>> processImage(String imagePath) async {
    final imageFile = io.File(imagePath);
    if (!await imageFile.exists()) {
      throw Exception("File not found at path: $imagePath");
    }
    
    final imageBytes = await imageFile.readAsBytes();
    final originalImage = await compute(_decodeImageInBackground, imageBytes);

    if (originalImage == null) {
      throw Exception("Could not decode image from path: $imagePath");
    }

    // Get directory for debug images
    final directory = await getApplicationDocumentsDirectory();
    final debugDir = io.Directory('${directory.path}/omr_debug');
    if (!await debugDir.exists()) {
      await debugDir.create(recursive: true);
    }

    // Save original image
    await _saveDebugImage(originalImage, '${debugDir.path}/1_original.png');

    // Resize if needed
    img.Image image = originalImage;
    const int maxDim = 2000;
    if (image.width > maxDim || image.height > maxDim) {
      final double scale = math.min(
        maxDim / image.width,
        maxDim / image.height,
      );
      final int newWidth = (image.width * scale).round();
      final int newHeight = (image.height * scale).round();
      debugPrint('Resizing image from ${image.width}x${image.height} to ${newWidth}x${newHeight}');
      image = img.copyResize(image, width: newWidth, height: newHeight);
    }

    // Preprocess
    final preprocessedImage = _preprocessImage(image);
    await _saveDebugImage(preprocessedImage, '${debugDir.path}/2_preprocessed.png');
    
    // Adaptive threshold
    final binaryImage = _adaptiveThreshold(preprocessedImage);
    await _saveDebugImage(binaryImage, '${debugDir.path}/3_binary.png');
    
    // Detect bubbles
    final bubbles = _detectBubbles(preprocessedImage);
    
    // Draw bubbles on image
    final bubbleImage = _drawBubbles(image, bubbles);
    await _saveDebugImage(bubbleImage, '${debugDir.path}/4_detected_bubbles.png');
    
    // Organize bubbles
    final organizedBubbles = _organizeBubblesByQuestions(bubbles);
    
    // Draw organized bubbles
    final organizedImage = _drawOrganizedBubbles(image, organizedBubbles);
    await _saveDebugImage(organizedImage, '${debugDir.path}/5_organized_bubbles.png');
    
    // Analyze marked bubbles
    final results = _analyzeMarkedBubbles(organizedBubbles, preprocessedImage);
    
    // Draw results
    final resultImage = _drawResults(image, organizedBubbles, results);
    await _saveDebugImage(resultImage, '${debugDir.path}/6_results.png');
    
    debugPrint("OMR processing complete. Debug images saved to: ${debugDir.path}");
    debugPrint("Found ${results.where((r) => r.isMarked).length} marked bubbles out of ${results.length} total.");
    
    return results;
  }
  
  static Future<void> _saveDebugImage(img.Image image, String path) async {
    final file = io.File(path);
    await file.writeAsBytes(img.encodePng(image));
    debugPrint('Saved debug image: $path');
  }
  
  static img.Image _drawBubbles(img.Image image, List<BubbleCandidate> bubbles) {
    final result = img.copyResize(image, width: image.width, height: image.height);
    
    for (final bubble in bubbles) {
      // Draw bounding box
      img.drawRect(
        result,
        x1: bubble.boundingBox.left,
        y1: bubble.boundingBox.top,
        x2: bubble.boundingBox.left + bubble.boundingBox.width,
        y2: bubble.boundingBox.top + bubble.boundingBox.height,
        color: img.ColorRgb8(0, 255, 0),
        thickness: 2,
      );
      
      // Draw center point
      img.fillCircle(
        result,
        x: bubble.centerX.round(),
        y: bubble.centerY.round(),
        radius: 3,
        color: img.ColorRgb8(255, 0, 0),
      );
    }
    
    return result;
  }
  
  static img.Image _drawOrganizedBubbles(img.Image image, Map<int, List<BubbleCandidate>> organizedBubbles) {
    final result = img.copyResize(image, width: image.width, height: image.height);
    
    organizedBubbles.forEach((questionNumber, bubbles) {
      for (int i = 0; i < bubbles.length; i++) {
        final bubble = bubbles[i];
        final optionLetter = String.fromCharCode('A'.codeUnitAt(0) + i);
        
        // Draw bounding box with different colors for each option
        final colors = [
          img.ColorRgb8(255, 0, 0),    // A - Red
          img.ColorRgb8(0, 255, 0),    // B - Green
          img.ColorRgb8(0, 0, 255),    // C - Blue
          img.ColorRgb8(255, 255, 0),  // D - Yellow
        ];
        
        img.drawRect(
          result,
          x1: bubble.boundingBox.left,
          y1: bubble.boundingBox.top,
          x2: bubble.boundingBox.left + bubble.boundingBox.width,
          y2: bubble.boundingBox.top + bubble.boundingBox.height,
          color: colors[i % colors.length],
          thickness: 2,
        );
        
        // Draw question number and option
        img.drawString(
          result,
          'Q$questionNumber-$optionLetter',
          font: img.arial14,
          x: bubble.boundingBox.left,
          y: bubble.boundingBox.top - 15,
          color: colors[i % colors.length],
        );
      }
    });
    
    return result;
  }
  
  static img.Image _drawResults(img.Image image, Map<int, List<BubbleCandidate>> organizedBubbles, List<OmrResult> results) {
    final result = img.copyResize(image, width: image.width, height: image.height);
    
    for (final omrResult in results) {
      final questionNumber = omrResult.rowIndex + 1;
      final optionIndex = omrResult.colIndex;
      
      if (organizedBubbles.containsKey(questionNumber)) {
        final bubbles = organizedBubbles[questionNumber]!;
        if (optionIndex < bubbles.length) {
          final bubble = bubbles[optionIndex];
          
          final color = omrResult.isMarked 
              ? img.ColorRgb8(0, 255, 0)    // Green for marked
              : img.ColorRgb8(255, 0, 0);   // Red for unmarked
          
          img.drawRect(
            result,
            x1: bubble.boundingBox.left,
            y1: bubble.boundingBox.top,
            x2: bubble.boundingBox.left + bubble.boundingBox.width,
            y2: bubble.boundingBox.top + bubble.boundingBox.height,
            color: color,
            thickness: omrResult.isMarked ? 4 : 2,
          );
          
          if (omrResult.isMarked) {
            // Draw checkmark for marked bubbles
            img.drawLine(
              result,
              x1: bubble.boundingBox.left + 5,
              y1: bubble.centerY.round(),
              x2: bubble.centerX.round(),
              y2: bubble.boundingBox.top + bubble.boundingBox.height - 5,
              color: img.ColorRgb8(0, 255, 0),
              thickness: 3,
            );
            img.drawLine(
              result,
              x1: bubble.centerX.round(),
              y1: bubble.boundingBox.top + bubble.boundingBox.height - 5,
              x2: bubble.boundingBox.left + bubble.boundingBox.width - 5,
              y2: bubble.boundingBox.top + 5,
              color: img.ColorRgb8(0, 255, 0),
              thickness: 3,
            );
          }
          
          // Draw confidence score
          img.drawString(
            result,
            '${(omrResult.confidence * 100).toStringAsFixed(0)}%',
            font: img.arial14,
            x: bubble.boundingBox.left + bubble.boundingBox.width + 5,
            y: bubble.centerY.round() - 7,
            color: color,
          );
        }
      }
    }
    
    return result;
  }
  
  // Copy all the processing methods from the original processor
  static img.Image _preprocessImage(img.Image image) {
    img.Image processed = img.grayscale(image);
    processed = img.adjustColor(processed, contrast: 1.5, brightness: 1.1);
    processed = img.gaussianBlur(processed, radius: 1);
    return processed;
  }
  
  static List<BubbleCandidate> _detectBubbles(img.Image image) {
    final bubbles = <BubbleCandidate>[];
    final binaryImage = _adaptiveThreshold(image);
    final regions = _findCircularRegions(binaryImage);
    
    for (final region in regions) {
      if (_isBubbleCandidate(region)) {
        bubbles.add(region);
      }
    }
    
    debugPrint('Detected ${bubbles.length} bubble candidates');
    return bubbles;
  }
  
  static img.Image _adaptiveThreshold(img.Image image) {
    final result = img.Image(width: image.width, height: image.height);
    
    const int windowSize = 25;
    const double k = 0.1;
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = img.getLuminance(pixel);
        
        double localMean = 0;
        int count = 0;
        
        for (int dy = -windowSize ~/ 2; dy <= windowSize ~/ 2; dy++) {
          for (int dx = -windowSize ~/ 2; dx <= windowSize ~/ 2; dx++) {
            final nx = x + dx;
            final ny = y + dy;
            
            if (nx >= 0 && nx < image.width && ny >= 0 && ny < image.height) {
              localMean += img.getLuminance(image.getPixel(nx, ny));
              count++;
            }
          }
        }
        
        localMean /= count;
        final threshold = localMean * (1 - k);
        
        final newPixel = luminance < threshold 
            ? img.ColorRgb8(0, 0, 0) 
            : img.ColorRgb8(255, 255, 255);
        result.setPixel(x, y, newPixel);
      }
    }
    
    return result;
  }
  
  static List<BubbleCandidate> _findCircularRegions(img.Image binaryImage) {
    final regions = <BubbleCandidate>[];
    final visited = List.generate(binaryImage.height, (_) => List<bool>.filled(binaryImage.width, false));
    
    const int minBubbleArea = 200;
    const int maxBubbleArea = 3000;
    
    for (int y = 0; y < binaryImage.height; y++) {
      for (int x = 0; x < binaryImage.width; x++) {
        if (!visited[y][x]) {
          final pixel = binaryImage.getPixel(x, y);
          final luminance = img.getLuminance(pixel);
          
          if (luminance < 128) {
            final region = _floodFill(binaryImage, x, y, visited);
            
            if (region.area >= minBubbleArea && region.area <= maxBubbleArea) {
              regions.add(region);
            }
          }
        }
      }
    }
    
    return regions;
  }
  
  static BubbleCandidate _floodFill(img.Image image, int startX, int startY, List<List<bool>> visited) {
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
      
      queue.add(Point(point.x + 1, point.y));
      queue.add(Point(point.x - 1, point.y));
      queue.add(Point(point.x, point.y + 1));
      queue.add(Point(point.x, point.y - 1));
    }
    
    return BubbleCandidate(
      points: points,
      centerX: (minX + maxX) / 2,
      centerY: (minY + maxY) / 2,
      width: maxX - minX,
      height: maxY - minY,
      area: points.length,
      boundingBox: Rectangle(minX, minY, maxX - minX, maxY - minY),
    );
  }
  
  static bool _isBubbleCandidate(BubbleCandidate region) {
    final aspectRatio = region.width / region.height;
    if (aspectRatio < 0.7 || aspectRatio > 1.3) return false;
    
    final expectedArea = math.pi * math.pow(region.width / 2, 2);
    final areaRatio = region.area / expectedArea;
    
    return areaRatio > 0.6 && areaRatio < 1.2;
  }
  
  static Map<int, List<BubbleCandidate>> _organizeBubblesByQuestions(List<BubbleCandidate> bubbles) {
    bubbles.sort((a, b) {
      final yDiff = (a.centerY - b.centerY).abs();
      if (yDiff < 20) {
        return a.centerX.compareTo(b.centerX);
      }
      return a.centerY.compareTo(b.centerY);
    });
    
    final questionGroups = <int, List<BubbleCandidate>>{};
    final rowGroups = <List<BubbleCandidate>>[];
    List<BubbleCandidate> currentRow = [];
    double lastY = -1;
    
    for (final bubble in bubbles) {
      if (lastY == -1 || (bubble.centerY - lastY).abs() < 30) {
        currentRow.add(bubble);
      } else {
        if (currentRow.isNotEmpty) {
          currentRow.sort((a, b) => a.centerX.compareTo(b.centerX));
          rowGroups.add(List.from(currentRow));
        }
        currentRow = [bubble];
      }
      lastY = bubble.centerY;
    }
    
    if (currentRow.isNotEmpty) {
      currentRow.sort((a, b) => a.centerX.compareTo(b.centerX));
      rowGroups.add(currentRow);
    }
    
    for (int i = 0; i < rowGroups.length; i++) {
      final row = rowGroups[i];
      
      const int expectedBubblesPerQuestion = 4;
      
      if (row.length >= expectedBubblesPerQuestion) {
        final List<BubbleCandidate> questionBubbles = [];
        
        for (int j = 0; j < row.length && j < expectedBubblesPerQuestion; j++) {
          questionBubbles.add(row[j]);
        }
        
        questionGroups[i + 1] = questionBubbles;
      }
    }
    
    debugPrint('Organized bubbles into ${questionGroups.length} questions');
    return questionGroups;
  }
  
  static List<OmrResult> _analyzeMarkedBubbles(Map<int, List<BubbleCandidate>> questionGroups, img.Image image) {
    final results = <OmrResult>[];
    
    questionGroups.forEach((questionNumber, bubbles) {
      for (int optionIndex = 0; optionIndex < bubbles.length; optionIndex++) {
        final bubble = bubbles[optionIndex];
        
        final roi = _extractROI(image, bubble);
        
        final darknessScore = DarknessDetector.getScore(roi);
        
        const double markThreshold = 0.4;
        final isMarked = darknessScore >= markThreshold;
        
        results.add(OmrResult(
          rowIndex: questionNumber - 1,
          colIndex: optionIndex,
          isMarked: isMarked,
          confidence: darknessScore,
        ));
        
        if (isMarked) {
          final optionLetter = String.fromCharCode('A'.codeUnitAt(0) + optionIndex);
          debugPrint('Question $questionNumber: Option $optionLetter marked (confidence: ${darknessScore.toStringAsFixed(2)})');
        }
      }
    });
    
    return results;
  }
  
  static img.Image _extractROI(img.Image image, BubbleCandidate bubble) {
    final padding = 3;
    final x = math.max(0, bubble.boundingBox.left - padding);
    final y = math.max(0, bubble.boundingBox.top - padding);
    final width = math.min(image.width - x, bubble.boundingBox.width + 2 * padding);
    final height = math.min(image.height - y, bubble.boundingBox.height + 2 * padding);
    
    return img.copyCrop(image, x: x, y: y, width: width, height: height);
  }
}

class BubbleCandidate {
  final List<Point> points;
  final double centerX;
  final double centerY;
  final int width;
  final int height;
  final int area;
  final Rectangle boundingBox;
  
  BubbleCandidate({
    required this.points,
    required this.centerX,
    required this.centerY,
    required this.width,
    required this.height,
    required this.area,
    required this.boundingBox,
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