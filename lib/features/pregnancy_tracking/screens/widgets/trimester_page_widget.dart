import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/premium_guard.dart';
import '../../data/fetus_development_data.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';
import 'trimester_header.dart';

class TrimesterPageWidget extends StatefulWidget {
  final int trimester;
  final int currentWeek;
  final bool isPremium;
  final AppLocalizations l10n;
  final Animation<double> pulseAnimation;
  final void Function(int week, int currentWeek, bool isPremium) onWeekTap;
  final VoidCallback onFinishTap;

  const TrimesterPageWidget({
    super.key,
    required this.trimester,
    required this.currentWeek,
    required this.isPremium,
    required this.l10n,
    required this.pulseAnimation,
    required this.onWeekTap,
    required this.onFinishTap,
  });

  @override
  State<TrimesterPageWidget> createState() => _TrimesterPageWidgetState();
}

class _TrimesterPageWidgetState extends State<TrimesterPageWidget> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _nodeKeys = {};
  final GlobalKey _containerKey = GlobalKey();
  List<Offset> _nodeCenters = [];
  bool _positionsCalculated = false;

  static const double _nodeSize = 72.0;
  static const double _rowHeight = 135.0;

  static const int _nodesPerRow = 4;

  final Map<int, String> _milestones = {
    5: 'assets/icons/milestone_heart.svg',
    10: 'assets/icons/milestone_wave.svg',
    14: 'assets/icons/milestone_baby.svg',
    20: 'assets/icons/milestone_star.svg',
    24: 'assets/icons/milestone_lungs.svg',
    32: 'assets/icons/milestone_brain.svg',
    37: 'assets/icons/milestone_term.svg',
    40: 'assets/icons/milestone_celebration.svg',
  };

  late int startWeek;
  late int endWeek;

  @override
  void initState() {
    super.initState();
    startWeek = widget.trimester == 1 ? 1 : (widget.trimester == 2 ? 14 : 28);
    endWeek = widget.trimester == 1 ? 13 : (widget.trimester == 2 ? 27 : 40);

    for (int week = startWeek; week <= endWeek; week++) {
      _nodeKeys[week] = GlobalKey();
    }

    // Kick off an initial calculation after the first frame so the painter
    // appears even if SizeChangedLayoutNotification fires before keys attach.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _calculateNodePositions();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _calculateNodePositions() {
    if (!mounted || _containerKey.currentContext == null) return;
    final containerBox =
        _containerKey.currentContext!.findRenderObject() as RenderBox?;
    if (containerBox == null) return;

    final List<Offset> centers = [];
    final int totalWeeks = endWeek - startWeek + 1;

    for (int week = startWeek; week <= endWeek; week++) {
      final key = _nodeKeys[week];
      if (key?.currentContext == null) continue;

      final nodeBox = key!.currentContext!.findRenderObject() as RenderBox?;
      if (nodeBox == null) continue;

      final nodePosition = nodeBox.localToGlobal(
        Offset.zero,
        ancestor: containerBox,
      );
      final center = nodePosition + Offset(nodeBox.size.width / 2, 40);
      centers.add(center);
    }

    if (centers.length == totalWeeks && mounted) {
      bool changed = _nodeCenters.length != centers.length;
      if (!changed) {
        for (int i = 0; i < centers.length; i++) {
          if ((_nodeCenters[i] - centers[i]).distance > 1.0) {
            changed = true;
            break;
          }
        }
      }

      if (changed || !_positionsCalculated) {
        setState(() {
          _nodeCenters = centers;
          _positionsCalculated = true;
        });
      }
    } else if (centers.length < totalWeeks &&
        !_positionsCalculated &&
        mounted) {
      // Some GlobalKeys aren't attached yet — retry next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _calculateNodePositions();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.only(
        bottom: AppConstants.getBottomPadding(context),
        top: 62,
      ),
      child: NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _calculateNodePositions();
          });
          return false;
        },
        child: SizeChangedLayoutNotifier(
          child: Stack(
            key: _containerKey,
            children: [
              if (_positionsCalculated &&
                  _nodeCenters.length == (endWeek - startWeek + 1))
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: widget.pulseAnimation,
                    builder: (context, _) => CustomPaint(
                      painter: _LocalJourneyPathPainter(
                        currentWeek: widget.currentWeek,
                        startWeek: startWeek,
                        nodeCenters: _nodeCenters,
                        animation: widget.pulseAnimation,
                        nodeRadius: 0.0,
                      ),
                    ),
                  ),
                ),
              _buildTrimesterMapLayout(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrimesterMapLayout() {
    final List<Widget> rows = [];
    final int totalWeeks = endWeek - startWeek + 1;
    final int totalRows = (totalWeeks / _nodesPerRow).ceil();

    for (int row = 0; row < totalRows; row++) {
      final List<Widget> rowNodes = [];
      final isReversed = row % 2 == 1;

      for (int col = 0; col < _nodesPerRow; col++) {
        final int batchIndex = isReversed ? (_nodesPerRow - 1 - col) : col;
        final int week = startWeek + (row * _nodesPerRow) + batchIndex;

        if (week > endWeek) {
          rowNodes.add(const SizedBox(width: _nodeSize, height: 110));
        } else {
          rowNodes.add(
            _buildWeekNode(
              week: week,
              isCurrentWeek: week == widget.currentWeek,
              isPast: week < widget.currentWeek,
            ),
          );
        }
      }

      rows.add(
        SizedBox(
          height: _rowHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: rowNodes,
          ),
        ),
      );
    }

    return Column(
      children: [
        TrimesterHeader(
          trimester: widget.trimester,
          currentWeek: widget.currentWeek,
          l10n: widget.l10n,
        ),
        ...rows,
        if (widget.trimester == 3)
          _buildFinishLine(widget.l10n, widget.currentWeek >= 40),
      ],
    );
  }

  Widget _buildWeekNode({
    required int week,
    required bool isCurrentWeek,
    required bool isPast,
  }) {
    final info = FetusDevelopmentData.getInfo(week);
    final trimesterColor = AppTheme.getTrimesterColor(week);
    final milestone = _milestones[week];

    return GestureDetector(
      onTap: () {
        if (week > widget.currentWeek && !widget.isPremium) {
          PremiumGuard.showPremiumDialog(context);
          return;
        }
        widget.onWeekTap(week, widget.currentWeek, widget.isPremium);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: widget.pulseAnimation,
            builder: (context, child) {
              final pulseValue = widget.pulseAnimation.value;
              final scale = isCurrentWeek ? 1.0 + 0.035 * pulseValue : 1.0;

              return Transform.scale(
                scale: scale,
                child: SizedBox(
                  key: _nodeKeys[week],
                  width: _nodeSize + 16,
                  height: 110,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: _buildNodeCircle(
                          info: info,
                          isCurrentWeek: isCurrentWeek,
                          isPast: isPast,
                          pulseValue: pulseValue,
                          trimesterColor: trimesterColor,
                        ),
                      ),
                      Positioned(
                        top: 71,
                        child: _buildWeekLabel(
                          week,
                          isCurrentWeek,
                          isPast,
                          trimesterColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (milestone != null)
            Positioned(
              top: 2,
              right: 2,
              child: _buildMilestoneMarker(
                milestone,
                trimesterColor,
                isCurrentWeek,
                isPast,
              ),
            ),
        ],
      ),
    );
  }

  // ─── Node Circle ────────────────────────────────────────────────────────────

  Widget _buildNodeCircle({
    required FetusDevelopmentInfo info,
    required bool isCurrentWeek,
    required bool isPast,
    required double pulseValue,
    required Color trimesterColor,
  }) {
    if (isCurrentWeek) {
      // Seamless vibrant colored circle node with CustomPainter breathing halo
      return SizedBox(
        width: _nodeSize + 6,
        height: _nodeSize + 6,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Custom-painted dual expanding harmonic ripple aura
            Positioned.fill(
              child: CustomPaint(
                painter: _ActiveNodeHaloPainter(
                  pulseValue: pulseValue,
                  color: trimesterColor,
                ),
              ),
            ),
            // Vibrant Solid Gradient Circle Node
            Container(
              width: _nodeSize + 6,
              height: _nodeSize + 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    trimesterColor,
                    trimesterColor.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: trimesterColor.withValues(
                      alpha: 0.50 + 0.28 * pulseValue,
                    ),
                    blurRadius: 22 + 14 * pulseValue,
                    spreadRadius: 2 + 3 * pulseValue,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.90),
                  width: 2.5,
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: SvgPicture.asset(
                info.assetPath,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      );
    }

    if (isPast) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: _nodeSize,
            height: _nodeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.appSurfaceColor,
            ),
          ),
          Container(
            width: _nodeSize,
            height: _nodeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  trimesterColor.withValues(alpha: 0.22),
                  trimesterColor.withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: trimesterColor.withValues(alpha: 0.72),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: trimesterColor.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Opacity(
              opacity: 0.92,
              child: SvgPicture.asset(info.assetPath, fit: BoxFit.contain),
            ),
          ),
        ],
      );
    }

    // Future node – frosted glass
    return Container(
      width: _nodeSize,
      height: _nodeSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.appSurfaceColor,
        border: Border.all(
          color: context.isDarkMode
              ? Colors.white.withValues(alpha: 0.20)
              : Colors.grey.withValues(alpha: 0.25),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: widget.isPremium
          ? Opacity(
              opacity: 0.38,
              child: SvgPicture.asset(info.assetPath, fit: BoxFit.contain),
            )
          : Icon(
              Icons.lock_outline_rounded,
              size: 20,
              color: Colors.grey.withValues(alpha: 0.35),
            ),
    );
  }

  // ─── Milestone marker ────────────────────────────────────────────────────────

  Widget _buildMilestoneMarker(
    String assetPath,
    Color trimesterColor,
    bool isCurrentWeek,
    bool isPast,
  ) {
    final Color bgColor;
    final Color iconColor;
    final Color borderColor;
    final surfaceColor = context.appSurfaceColor;

    if (isCurrentWeek) {
      bgColor = trimesterColor;
      iconColor = Colors.white;
      borderColor = surfaceColor;
    } else if (isPast) {
      bgColor = Color.alphaBlend(
        trimesterColor.withValues(alpha: 0.18),
        surfaceColor,
      );
      iconColor = trimesterColor;
      borderColor = surfaceColor;
    } else {
      bgColor = surfaceColor;
      iconColor = Colors.grey.shade500;
      borderColor = context.isDarkMode
          ? Colors.white.withValues(alpha: 0.20)
          : Colors.grey.withValues(alpha: 0.25);
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: isPast || isCurrentWeek ? 2.5 : 1.5,
        ),
      ),
      child: SvgPicture.asset(
        assetPath,
        width: 14,
        height: 14,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
    );
  }

  // ─── Week label ──────────────────────────────────────────────────────────────

  Widget _buildWeekLabel(
    int week,
    bool isCurrentWeek,
    bool isPast,
    Color trimesterColor,
  ) {
    final Color bgColor;
    final Color textColor;
    final FontWeight fontWeight;
    final Color borderColor;
    final surfaceColor = context.appSurfaceColor;

    if (isCurrentWeek) {
      bgColor = trimesterColor;
      textColor = Colors.white;
      fontWeight = FontWeight.w800;
      borderColor = surfaceColor;
    } else if (isPast) {
      bgColor = Color.alphaBlend(
        trimesterColor.withValues(alpha: 0.18),
        surfaceColor,
      );
      textColor = trimesterColor;
      fontWeight = FontWeight.w800;
      borderColor = surfaceColor;
    } else {
      bgColor = surfaceColor;
      textColor = Colors.grey.shade500;
      fontWeight = FontWeight.w700;
      borderColor = context.isDarkMode
          ? Colors.white.withValues(alpha: 0.20)
          : Colors.grey.withValues(alpha: 0.25);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isPast || isCurrentWeek ? 2.5 : 1.5,
        ),
      ),
      child: Text(
        '$week',
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: fontWeight,
          color: textColor,
        ),
      ),
    );
  }

  // ─── Finish line ─────────────────────────────────────────────────────────────

  Widget _buildFinishLine(AppLocalizations l10n, bool isReached) {
    const color = AppTheme.trimester3Primary;

    return GestureDetector(
      onTap: isReached ? widget.onFinishTap : null,
      child: Container(
        margin: const EdgeInsets.only(top: 24, bottom: 48),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: isReached
              ? color
              : context.appGlassColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isReached
                ? Colors.white.withValues(alpha: 0.3)
                : color.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isReached
                  ? color.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isReached ? 24 : 8,
              spreadRadius: isReached ? 4 : 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isReached
                  ? Icons.auto_awesome_rounded
                  : Icons.emoji_events_outlined,
              size: 24,
              color: isReached ? Colors.white : color,
            ),
            const SizedBox(width: 8),
            Text(
              isReached ? l10n.preg_baby_born : l10n.preg_due_date_milestone,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isReached ? Colors.white : context.appTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Journey path painter ─────────────────────────────────────────────────────

class _LocalJourneyPathPainter extends CustomPainter {
  final int currentWeek;
  final int startWeek;
  final List<Offset> nodeCenters;
  final Animation<double> animation;
  final double nodeRadius;

  _LocalJourneyPathPainter({
    required this.currentWeek,
    required this.startWeek,
    required this.nodeCenters,
    required this.animation,
    required this.nodeRadius,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (nodeCenters.length < 2) return;

    // ── 1. Future segments – dashed subtle gray ───────────────────────────────
    final Paint futurePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..color = Colors.grey.withValues(alpha: 0.22);

    for (int i = 0; i < nodeCenters.length - 1; i++) {
      final weekNum = startWeek + i;
      if (weekNum >= currentWeek) {
        final raw = _buildSegmentPath(
          nodeCenters[i],
          nodeCenters[i + 1],
          i,
          size.width,
        );
        final path = _trimmedSegment(raw);
        if (path != null) _drawDashedPath(canvas, path, futurePaint);
      }
    }

    // ── 2. Past segments – glow + gradient + white dot markers ────────────────
    final Paint glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final Paint mainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < nodeCenters.length - 1; i++) {
      final weekNum = startWeek + i;
      if (weekNum >= currentWeek) continue;

      final p1 = nodeCenters[i];
      final p2 = nodeCenters[i + 1];
      final color = AppTheme.getTrimesterColor(weekNum);
      final nextColor = AppTheme.getTrimesterColor(weekNum + 1);
      final raw = _buildSegmentPath(p1, p2, i, size.width);
      final segPath = _trimmedSegment(raw);
      if (segPath == null) continue;
      final bounds = Rect.fromPoints(p1, p2);

      // Soft glow behind the path
      glowPaint.color = color.withValues(alpha: 0.22);
      canvas.drawPath(segPath, glowPaint);

      // Gradient-colored main stroke
      mainPaint.shader = LinearGradient(
        colors: [color, nextColor],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bounds);
      canvas.drawPath(segPath, mainPaint);

      // White lane-marker dots along every segment
      _drawLaneMarkers(canvas, segPath, color);
    }

    // ── 3. Traveling particle on the active leading edge ──────────────────────
    final int activeIdx = currentWeek - startWeek - 1;
    if (activeIdx >= 0 && activeIdx < nodeCenters.length - 1) {
      final rawActive = _buildSegmentPath(
        nodeCenters[activeIdx],
        nodeCenters[activeIdx + 1],
        activeIdx,
        size.width,
      );
      final activePath = _trimmedSegment(rawActive);
      if (activePath != null) {
        _drawTravelingParticle(
          canvas,
          activePath,
          AppTheme.getTrimesterColor(currentWeek),
        );
      }
    }
  }

  // ─── Path trimming ────────────────────────────────────────────────────────
  //
  // Skips [nodeRadius] arc-length from both ends of [path] so the drawn
  // segment starts and ends at the node-circle boundary rather than the
  // node center.  For any smooth curve, arc-length ≈ Euclidean distance
  // over small distances, so this reliably keeps paint outside every node.
  Path? _trimmedSegment(Path path) {
    for (final metric in path.computeMetrics()) {
      return metric.extractPath(0, metric.length);
    }
    return null;
  }

  // ─── Dashed path helper ────────────────────────────────────────────────────

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const double dashLen = 7.0;
    const double gapLen = 6.0;

    for (final metric in path.computeMetrics()) {
      double dist = 0;
      bool draw = true;
      while (dist < metric.length) {
        final end = math.min(dist + (draw ? dashLen : gapLen), metric.length);
        if (draw) canvas.drawPath(metric.extractPath(dist, end), paint);
        dist = end;
        draw = !draw;
      }
    }
  }

  // ─── White dot lane markers ────────────────────────────────────────────────

  void _drawLaneMarkers(Canvas canvas, Path path, Color color) {
    const double spacing = 16.0;

    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.70)
      ..style = PaintingStyle.fill;

    // Tiny colored shadow dot for depth
    final shadowDotPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    for (final metric in path.computeMetrics()) {
      final count = (metric.length / spacing).floor();
      for (int d = 1; d < count; d++) {
        final tangent = metric.getTangentForOffset(d * spacing);
        if (tangent == null) continue;
        canvas.drawCircle(tangent.position, 3.2, shadowDotPaint);
        canvas.drawCircle(tangent.position, 2.2, dotPaint);
      }
    }
  }

  // ─── Animated traveling particle ──────────────────────────────────────────

  void _drawTravelingParticle(Canvas canvas, Path path, Color color) {
    for (final metric in path.computeMetrics()) {
      final offset = animation.value * metric.length;
      final tangent = metric.getTangentForOffset(offset);
      if (tangent == null) return;

      final pos = tangent.position;

      // Outermost soft halo
      canvas.drawCircle(
        pos,
        16,
        Paint()
          ..color = color.withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Mid glow ring
      canvas.drawCircle(pos, 9, Paint()..color = color.withValues(alpha: 0.30));

      // Solid main particle
      canvas.drawCircle(pos, 5.5, Paint()..color = color);

      // Bright white center
      canvas.drawCircle(pos, 2.5, Paint()..color = Colors.white);
    }
  }

  // ─── Segment path builder ─────────────────────────────────────────────────

  Path _buildSegmentPath(Offset p1, Offset p2, int index, double canvasWidth) {
    final path = Path();
    path.moveTo(p1.dx, p1.dy);

    // Keep curves at least this far from each edge so they don't clip.
    const double edgeMargin = 18.0;
    final double midX = canvasWidth / 2;

    final dy = (p2.dy - p1.dy).abs();

    if (dy > 100) {
      // Row-transition U-bend — control point pulled inward, clamped to margin.
      final isLeft = p1.dx < midX;
      final double rawCx = isLeft ? p1.dx - 72 : p1.dx + 72;
      final double controlX = rawCx.clamp(edgeMargin, canvasWidth - edgeMargin);
      path.cubicTo(controlX, p1.dy + 85, controlX, p2.dy - 85, p2.dx, p2.dy);
    } else if (dy > 40) {
      // Slight elevation change — clamp each control x individually.
      final isRightSide = p1.dx > midX;
      final controlOffset = isRightSide ? 72.0 : -72.0;
      final double cx1 = (p1.dx + controlOffset).clamp(
        edgeMargin,
        canvasWidth - edgeMargin,
      );
      final double cx2 = (p2.dx + controlOffset).clamp(
        edgeMargin,
        canvasWidth - edgeMargin,
      );
      path.cubicTo(cx1, p1.dy + 32, cx2, p2.dy - 32, p2.dx, p2.dy);
    } else {
      // Horizontal wave (same row)
      final midX = (p1.dx + p2.dx) / 2;
      final midY = (p1.dy + p2.dy) / 2;
      final waveDir = index % 2 == 0 ? 1 : -1;
      path.quadraticBezierTo(midX, midY + 12.0 * waveDir, p2.dx, p2.dy);
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant _LocalJourneyPathPainter oldDelegate) =>
      oldDelegate.currentWeek != currentWeek ||
      oldDelegate.nodeCenters != nodeCenters ||
      oldDelegate.nodeRadius != nodeRadius ||
      oldDelegate.animation.value != animation.value;
}

// ─── Active Node Halo Painter ──────────────────────────────────────────────────

class _ActiveNodeHaloPainter extends CustomPainter {
  final double pulseValue;
  final Color color;

  _ActiveNodeHaloPainter({
    required this.pulseValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (size.width / 2) - 2.0;

    // 1. Ambient Radial Backlight Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.36 + 0.20 * pulseValue),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius + 20.0));
    canvas.drawCircle(center, baseRadius + 20.0, glowPaint);

    // 2. Wave 1: Outermost expanding harmonic wave (fades out as it expands)
    final wave1Radius = baseRadius + 7.0 + 11.0 * pulseValue;
    final wave1Alpha = (0.35 * (1.0 - 0.55 * pulseValue)).clamp(0.0, 1.0);
    final wave1Paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = color.withValues(alpha: wave1Alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawCircle(center, wave1Radius, wave1Paint);

    // 3. Wave 2: Inner harmonic breathing ripple
    final wave2Radius = baseRadius + 3.0 + 4.5 * pulseValue;
    final wave2Alpha = (0.25 + 0.35 * pulseValue).clamp(0.0, 1.0);
    final wave2Paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = color.withValues(alpha: wave2Alpha);
    canvas.drawCircle(center, wave2Radius, wave2Paint);
  }

  @override
  bool shouldRepaint(covariant _ActiveNodeHaloPainter oldDelegate) =>
      oldDelegate.pulseValue != pulseValue || oldDelegate.color != color;
}
