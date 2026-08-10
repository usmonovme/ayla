import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class JourneyProgressLine extends StatelessWidget {
  final bool isPast;
  final bool isCurrent;
  final bool showTopLine;
  final bool showBottomLine;

  const JourneyProgressLine({
    super.key,
    required this.isPast,
    required this.isCurrent,
    this.showTopLine = true,
    this.showBottomLine = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: CustomPaint(
        painter: _JourneyLinePainter(
          isPast: isPast,
          isCurrent: isCurrent,
          showTopLine: showTopLine,
          showBottomLine: showBottomLine,
          primaryColor: AppTheme.pregnancyPrimary,
        ),
      ),
    );
  }
}

class _JourneyLinePainter extends CustomPainter {
  final bool isPast;
  final bool isCurrent;
  final bool showTopLine;
  final bool showBottomLine;
  final Color primaryColor;

  _JourneyLinePainter({
    required this.isPast,
    required this.isCurrent,
    required this.showTopLine,
    required this.showBottomLine,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final dotRadius = isCurrent ? 8.0 : 6.0;

    final paintLine = Paint()
      ..color = isPast ? primaryColor : Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final paintDot = Paint()
      ..color = isCurrent || isPast ? primaryColor : Colors.white
      ..style = isCurrent || isPast ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final paintDotBorder = Paint()
      ..color = isCurrent || isPast
          ? primaryColor
          : Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw top line
    if (showTopLine) {
      canvas.drawLine(
        Offset(centerX, 0),
        Offset(centerX, size.height / 2 - dotRadius - 4),
        paintLine,
      );
    }

    // Draw bottom line
    if (showBottomLine) {
      // Bottom line is colored only if it's PAST (current week's bottom line is grey)
      final bottomPaint = Paint()
        ..color = isPast ? primaryColor : Colors.grey.withValues(alpha: 0.3)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(centerX, size.height / 2 + dotRadius + 4),
        Offset(centerX, size.height),
        bottomPaint,
      );
    }

    // Draw Dot
    canvas.drawCircle(Offset(centerX, size.height / 2), dotRadius, paintDot);
    canvas.drawCircle(
      Offset(centerX, size.height / 2),
      dotRadius,
      paintDotBorder,
    );

    if (isCurrent) {
      // Draw outer glow for current week
      final glowPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(centerX, size.height / 2),
        dotRadius + 6,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
