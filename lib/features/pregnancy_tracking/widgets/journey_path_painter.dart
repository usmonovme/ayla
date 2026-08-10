import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Custom painter that draws a winding journey path like a treasure map
class JourneyPathPainter extends CustomPainter {
  final int totalWeeks;
  final int currentWeek;
  final double scrollOffset;
  final List<Offset> nodePositions;
  final Animation<double>? animation;

  JourneyPathPainter({
    required this.totalWeeks,
    required this.currentWeek,
    required this.scrollOffset,
    required this.nodePositions,
    this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (nodePositions.length < 2) return;

    // Draw the path background (future path - dashed)
    _drawPath(
      canvas,
      nodePositions,
      currentWeek,
      totalWeeks,
      isFuturePath: true,
    );

    // Draw the path foreground (completed path - solid)
    _drawPath(
      canvas,
      nodePositions,
      currentWeek,
      totalWeeks,
      isFuturePath: false,
    );

    // Draw glow effect for current position
    _drawCurrentPositionGlow(canvas, nodePositions, currentWeek);
  }

  void _drawPath(
    Canvas canvas,
    List<Offset> positions,
    int currentWeek,
    int totalWeeks, {
    required bool isFuturePath,
  }) {
    if (positions.isEmpty) return;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (isFuturePath) {
      paint.color = AppTheme.pregnancyPrimary.withValues(alpha: 0.2);
      paint.strokeWidth = 4;
    } else {
      paint.shader = LinearGradient(
        colors: [
          AppTheme.pregnancyPrimary.withValues(alpha: 0.6),
          AppTheme.pregnancyPrimary,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTWH(0, 0, 1000, 5000));
      paint.strokeWidth = 5;
    }

    final Path path = Path();
    path.moveTo(positions.first.dx, positions.first.dy);

    for (int i = 1; i < positions.length; i++) {
      final prev = positions[i - 1];
      final curr = positions[i];

      // Create smooth bezier curves between points
      final controlPoint1 = Offset(
        prev.dx,
        prev.dy + (curr.dy - prev.dy) * 0.5,
      );
      final controlPoint2 = Offset(
        curr.dx,
        prev.dy + (curr.dy - prev.dy) * 0.5,
      );

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        curr.dx,
        curr.dy,
      );
    }

    if (!isFuturePath && currentWeek > 0) {
      // Only draw up to current week
      final metrics = path.computeMetrics().first;
      final progress = (currentWeek / totalWeeks).clamp(0.0, 1.0);
      final extractPath = metrics.extractPath(0, metrics.length * progress);
      canvas.drawPath(extractPath, paint);
    } else if (isFuturePath) {
      canvas.drawPath(path, paint);
    }
  }

  void _drawCurrentPositionGlow(
    Canvas canvas,
    List<Offset> positions,
    int currentWeek,
  ) {
    if (currentWeek <= 0 || currentWeek > positions.length) return;

    final currentPos = positions[currentWeek - 1];
    final animValue = animation?.value ?? 1.0;

    // Pulsing glow effect
    final glowRadius = 24 + (8 * math.sin(animValue * math.pi * 2));

    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.pregnancyPrimary.withValues(alpha: 0.4),
          AppTheme.pregnancyPrimary.withValues(alpha: 0.1),
          AppTheme.pregnancyPrimary.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: currentPos, radius: glowRadius));

    canvas.drawCircle(currentPos, glowRadius, glowPaint);
  }

  @override
  bool shouldRepaint(covariant JourneyPathPainter oldDelegate) {
    return oldDelegate.currentWeek != currentWeek ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.nodePositions != nodePositions;
  }
}

/// Utility class to calculate path positions for the journey map
class JourneyPathCalculator {
  /// Calculate node positions for a winding path layout
  static List<Offset> calculateNodePositions({
    required int totalWeeks,
    required double screenWidth,
    required double startY,
    required double nodeSpacing,
    required double horizontalAmplitude,
  }) {
    final List<Offset> positions = [];
    final centerX = screenWidth / 2;

    for (int week = 1; week <= totalWeeks; week++) {
      // Create a winding path using sine wave
      final progress = (week - 1) / (totalWeeks - 1);
      final wavePhase = progress * math.pi * 4; // 2 complete waves

      // Alternate left and right with smooth curve
      final xOffset = math.sin(wavePhase) * horizontalAmplitude;
      final x = centerX + xOffset;
      final y = startY + (week - 1) * nodeSpacing;

      positions.add(Offset(x, y));
    }

    return positions;
  }

  /// Calculate trimester milestone positions
  static List<TrimesterMilestone> calculateTrimesterMilestones({
    required List<Offset> nodePositions,
  }) {
    if (nodePositions.length < 40) return [];

    return [
      TrimesterMilestone(
        trimester: 1,
        position: nodePositions[0],
        weekRange: '1-13',
        label: 'First Trimester',
      ),
      TrimesterMilestone(
        trimester: 2,
        position: nodePositions[13],
        weekRange: '14-27',
        label: 'Second Trimester',
      ),
      TrimesterMilestone(
        trimester: 3,
        position: nodePositions[27],
        weekRange: '28-40',
        label: 'Third Trimester',
      ),
    ];
  }
}

class TrimesterMilestone {
  final int trimester;
  final Offset position;
  final String weekRange;
  final String label;

  TrimesterMilestone({
    required this.trimester,
    required this.position,
    required this.weekRange,
    required this.label,
  });
}
