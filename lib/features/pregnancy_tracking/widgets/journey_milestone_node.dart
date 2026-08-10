import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../data/fetus_development_data.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';

/// Interactive milestone node for the pregnancy journey map
class JourneyMilestoneNode extends StatefulWidget {
  final int week;
  final bool isCurrentWeek;
  final bool isPast;
  final bool isSelected;
  final Offset position;
  final VoidCallback onTap;
  final String sizeComparison;

  const JourneyMilestoneNode({
    super.key,
    required this.week,
    required this.isCurrentWeek,
    required this.isPast,
    required this.isSelected,
    required this.position,
    required this.onTap,
    required this.sizeComparison,
  });

  @override
  State<JourneyMilestoneNode> createState() => _JourneyMilestoneNodeState();
}

class _JourneyMilestoneNodeState extends State<JourneyMilestoneNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isCurrentWeek) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(JourneyMilestoneNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentWeek && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isCurrentWeek && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nodeSize = widget.isCurrentWeek
        ? 56.0
        : (widget.isSelected ? 52.0 : 44.0);
    final info = FetusDevelopmentData.getInfo(widget.week);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onTap,
          child: SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow effect for current week
                if (widget.isCurrentWeek)
                  Container(
                    width: nodeSize + 24,
                    height: nodeSize + 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.pregnancyPrimary.withValues(
                            alpha: _glowAnimation.value,
                          ),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),

                // Selection ring
                if (widget.isSelected)
                  Container(
                    width: nodeSize + 12,
                    height: nodeSize + 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.pregnancyPrimary,
                        width: 3,
                      ),
                    ),
                  ),

                // Main node
                Transform.scale(
                  scale: widget.isCurrentWeek ? _scaleAnimation.value : 1.0,
                  child: Container(
                    width: nodeSize,
                    height: nodeSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _getNodeGradient(),
                      boxShadow: [
                        BoxShadow(
                          color: _getNodeColor().withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(child: _buildNodeContent(info, nodeSize)),
                  ),
                ),

                // Week number badge
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isCurrentWeek
                          ? AppTheme.pregnancyPrimary
                          : (widget.isPast
                                ? AppTheme.pregnancyPrimary.withValues(
                                    alpha: 0.8,
                                  )
                                : Colors.white),
                      borderRadius: BorderRadius.circular(
                        20,
                      ), // Changed from 10
                      border: Border.all(
                        color: widget.isCurrentWeek || widget.isPast
                            ? Colors.transparent
                            : AppTheme.pregnancyPrimary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${widget.week}',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: widget.isCurrentWeek || widget.isPast
                            ? Colors.white
                            : context.appTextSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNodeContent(FetusDevelopmentInfo info, double nodeSize) {
    if (widget.isPast || widget.isCurrentWeek) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: SvgPicture.asset(
          info.assetPath,
          fit: BoxFit.contain,
          colorFilter: widget.isPast && !widget.isCurrentWeek
              ? ColorFilter.mode(
                  Colors.white.withValues(alpha: 0.9),
                  BlendMode.srcATop,
                )
              : null,
        ),
      );
    }

    // Future weeks show lock or question mark
    return Icon(
      Icons.lock_outline_rounded,
      size: nodeSize * 0.4,
      color: context.appTextSecondary.withValues(alpha: 0.5),
    );
  }

  LinearGradient _getNodeGradient() {
    if (widget.isCurrentWeek) {
      return LinearGradient(
        colors: [
          AppTheme.pregnancyPrimary,
          AppTheme.pregnancyPrimary.withBlue(255),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (widget.isPast) {
      return LinearGradient(
        colors: [
          AppTheme.pregnancyPrimary.withValues(alpha: 0.7),
          AppTheme.pregnancyPrimary.withValues(alpha: 0.5),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return LinearGradient(
        colors: [Colors.grey.shade100, Colors.grey.shade200],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  Color _getNodeColor() {
    if (widget.isCurrentWeek || widget.isPast) {
      return AppTheme.pregnancyPrimary;
    }
    return Colors.grey.shade300;
  }
}

/// Animated builder helper
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

/// A compact milestone marker for trimester transitions
class TrimesterMarkerNode extends StatelessWidget {
  final int trimester;
  final bool isReached;
  final String label;
  final VoidCallback? onTap;

  const TrimesterMarkerNode({
    super.key,
    required this.trimester,
    required this.isReached,
    required this.label,
    this.onTap,
  });

  IconData get _trimesterIcon {
    switch (trimester) {
      case 1:
        return Icons.egg_outlined;
      case 2:
        return Icons.child_care_outlined;
      case 3:
        return Icons.celebration_outlined;
      default:
        return Icons.flag_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isReached
              ? LinearGradient(
                  colors: [
                    AppTheme.pregnancyPrimary,
                    AppTheme.pregnancyPrimary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isReached ? null : Colors.white,
          borderRadius: BorderRadius.circular(28), // Changed from 24
          border: Border.all(
            color: isReached
                ? Colors.transparent
                : AppTheme.pregnancyPrimary.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isReached
                  ? AppTheme.pregnancyPrimary.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _trimesterIcon,
              size: 20,
              color: isReached ? Colors.white : AppTheme.pregnancyPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isReached ? Colors.white : AppTheme.pregnancyPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Special milestone node for key events (e.g., viability, full term)
class SpecialMilestoneNode extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isReached;
  final Color? color;

  const SpecialMilestoneNode({
    super.key,
    required this.title,
    required this.icon,
    required this.isReached,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final nodeColor = color ?? AppTheme.pregnancyPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isReached
            ? nodeColor.withValues(alpha: 0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20), // Changed from 16
        border: Border.all(
          color: isReached
              ? nodeColor.withValues(alpha: 0.3)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isReached ? nodeColor : Colors.grey),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isReached ? nodeColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
