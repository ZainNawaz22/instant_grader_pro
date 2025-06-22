import 'package:flutter/material.dart';

class OmrDebugWidget extends StatelessWidget {
  final Size imageSize;
  final List<Rect> bubbleRects;
  final List<bool> markedBubbles;
  
  const OmrDebugWidget({
    super.key,
    required this.imageSize,
    required this.bubbleRects,
    required this.markedBubbles,
  });
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: imageSize,
      painter: OmrGridPainter(
        bubbleRects: bubbleRects,
        markedBubbles: markedBubbles,
      ),
    );
  }
}

class OmrGridPainter extends CustomPainter {
  final List<Rect> bubbleRects;
  final List<bool> markedBubbles;
  
  OmrGridPainter({
    required this.bubbleRects,
    required this.markedBubbles,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    for (int i = 0; i < bubbleRects.length; i++) {
      final rect = bubbleRects[i];
      final isMarked = i < markedBubbles.length && markedBubbles[i];
      
      // Set color based on detection result
      paint.color = isMarked ? Colors.green : Colors.red;
      
      // Draw circle for bubble
      canvas.drawCircle(
        Offset(rect.center.dx, rect.center.dy),
        rect.width / 2,
        paint,
      );
      
      // Draw question and option labels
      if (i < 20) {  // 5 questions × 4 options
        final question = (i ~/ 4) + 1;
        final option = String.fromCharCode('A'.codeUnitAt(0) + (i % 4));
        
        final textPainter = TextPainter(
          text: TextSpan(
            text: 'Q$question-$option',
            style: TextStyle(
              color: isMarked ? Colors.green : Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            rect.left - 5,
            rect.top - 15,
          ),
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 