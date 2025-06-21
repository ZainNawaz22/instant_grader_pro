import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:instant_grader_pro/omr_engine/core/grid_detector.dart';
import 'package:instant_grader_pro/omr_engine/core/pre_processing.dart';
import 'package:instant_grader_pro/omr_engine/core/sheet_alignment.dart';
import 'package:instant_grader_pro/omr_engine/ensemble.dart';
import 'package:instant_grader_pro/omr_engine/models/omr_result.dart';

// This top-level function is required for the `compute` function.
// It decodes the image bytes in a separate isolate.
img.Image? _decodeImageInBackground(List<int> imageBytes) {
  return img.decodeImage(imageBytes);
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

    // --- OMR Pipeline ---

    // 2. Pre-process Image (Noise reduction, contrast, etc.)
    final preprocessedMat = await PreProcessing.run(image);

    // 3. Align Sheet (Perspective correction)
    final alignedMat = await SheetAlignment.run(preprocessedMat);

    // 4. Detect Grid (Find bubble locations)
    final grid = await GridDetector.run(alignedMat);

    // 5. Extract Bubble ROIs and Classify
    final results = <OmrResult>[];
    for (int i = 0; i < grid.bubbleRois.length; i++) {
      final roiRect = grid.bubbleRois[i];
      
      // The `opencv_dart` package would need a method to extract a
      // sub-image (ROI) from the main image matrix.
      // final roiMat = alignedMat.getRegion(roiRect);
      
      // For the DarknessDetector, we need an img.Image, not a cv.Mat.
      // This highlights a point of integration between the two libraries.
      // A conversion function from cv.Mat to img.Image would be needed.
      // As a placeholder, we create a small, blank image.
      final roiImg = img.Image(width: 32, height: 32);

      // We assume the grid gives us row/column info, or we calculate it.
      // This part of the logic depends on the Grid implementation.
      final int rowIndex = i ~/ 20; // Placeholder logic
      final int colIndex = i % 20; // Placeholder logic

      final result = await Ensemble.classify(roiImg, rowIndex, colIndex);
      results.add(result);
    }

    debugPrint("OMR processing complete for $imagePath.");
    return results;
  }
}
