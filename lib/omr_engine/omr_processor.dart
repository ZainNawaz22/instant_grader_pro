import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:instant_grader_pro/omr_engine/detectors/darkness_detector.dart';
import 'package:image/image.dart' as img;
import 'package:instant_grader_pro/omr_engine/core/grid_detector.dart';
import 'package:instant_grader_pro/omr_engine/core/pre_processing.dart';
import 'package:instant_grader_pro/omr_engine/core/sheet_alignment.dart';
import 'package:instant_grader_pro/omr_engine/ensemble.dart';
import 'package:instant_grader_pro/omr_engine/models/omr_result.dart';

// This top-level function is required for the `compute` function.
// It decodes the image bytes in a separate isolate.
img.Image? _decodeImageInBackground(List<int> imageBytes) {
  return img.decodeImage(Uint8List.fromList(imageBytes));
}

class OmrProcessor {
  static Future<List<OmrResult>> processImage(String imagePath) async {
    final imageFile = io.File(imagePath);
    if (!await imageFile.exists()) {
      throw Exception("File not found at path: $imagePath");
    }
    final imageBytes = await imageFile.readAsBytes();
    final image = await compute(_decodeImageInBackground, imageBytes);

    if (image == null) {
      throw Exception("Could not decode image from path: $imagePath");
    }

    // Downscale very large images to reduce RAM and processing time while retaining detail
    const int maxDim = 1600; // pixels
    if (image.width > maxDim || image.height > maxDim) {
      final int newWidth;
      final int newHeight;
      if (image.width >= image.height) {
        newWidth = maxDim;
        newHeight = (image.height * maxDim / image.width).round();
      } else {
        newHeight = maxDim;
        newWidth = (image.width * maxDim / image.height).round();
      }
      debugPrint('Resizing image from ${image.width}x${image.height} '
          'to ${newWidth}x${newHeight} for processing');
      final img.Image resized = img.copyResize(image, width: newWidth, height: newHeight);
      image = resized;
    }

    // --- OMR Pipeline (Simplified for now to avoid OpenCV issues) ---

    // Basic OMR detection based on darkness analysis
    // ------------------------------------------------
    // This is a VERY simplified implementation which assumes the
    // answer bubbles are laid out in a 5x4 uniform grid that spans the
    // entire image.  Each grid cell is analysed individually and a
    // darkness score is computed.  If the score is above a threshold
    // we treat the bubble as filled.

    const int rows = 5;
    const int cols = 4;
    const double fillThreshold = 0.50; // tune as required

    final results = <OmrResult>[];

    final int cellHeight = (image.height / rows).floor();
    final int cellWidth = (image.width / cols).floor();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final int startX = col * cellWidth;
        final int startY = row * cellHeight;

        // Ensure we stay within bounds for the last cell due to integer division
        final int roiWidth = (col == cols - 1)
            ? image.width - startX
            : cellWidth;
        final int roiHeight = (row == rows - 1)
            ? image.height - startY
            : cellHeight;

        final img.Image roi = img.copyCrop(
          image,
          x: startX,
          y: startY,
          width: roiWidth,
          height: roiHeight,
        );

        final double score = DarknessDetector.getScore(roi);
        final bool isMarked = score >= fillThreshold;

        results.add(
          OmrResult(
            rowIndex: row,
            colIndex: col,
            isMarked: isMarked,
            confidence: score,
          ),
        );
      }
    }

    debugPrint(
        "OMR processing complete for $imagePath. Found ${results.where((r) => r.isMarked).length} marked bubbles.");
    return results;
  }
}
