import 'package:image/image.dart' as img;

class DarknessDetector {
  /// Analyzes a bubble's Region of Interest (ROI) to determine
  /// if it's filled based on pixel intensity.
  static double getScore(img.Image roi) {
    // This is a simplified implementation of the "Advanced Darkness Analysis".
    
    int pixelCount = 0;
    int darkPixelCount = 0;
    double sumOfIntensities = 0;

    // A simple threshold to determine if a pixel is "dark".
    // This could be made adaptive in a full implementation.
    const int darknessThreshold = 120;

    for (final pixel in roi) {
      // Using a simple luminance calculation.
      final luminance = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).toInt();
      
      sumOfIntensities += luminance;
      pixelCount++;
      
      if (luminance < darknessThreshold) {
        darkPixelCount++;
      }
    }

    if (pixelCount == 0) {
      return 0.0;
    }

    final double meanIntensity = sumOfIntensities / pixelCount;
    final double percentageDark = darkPixelCount / pixelCount;
    
    // The score is a combination of the percentage of dark pixels and the
    // inverse of the average intensity. A higher score means a higher
    // confidence that the bubble is filled.
    // The weights (0.7 and 0.3) can be tuned.
    double score = 0.7 * percentageDark + 0.3 * (1.0 - (meanIntensity / 255.0));

    // Clamp the score between 0 and 1.
    return score.clamp(0.0, 1.0);
  }
} 