import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/platform_wrapper.dart';
import '../data/fetus_development_data.dart';
import '../data/pregnancy_localization_helper.dart';
import '../../../l10n/app_localizations.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';
import 'package:provider/provider.dart';
import '../../gamification/providers/gamification_provider.dart';
import '../../gamification/widgets/badge_celebration.dart';
import '../providers/pregnancy_provider.dart';

class PregnancyOverviewCard extends StatefulWidget {
  final int week;
  final int currentWeek;
  final DateTime dueDate;
  final int daysLeft;
  final FetusDevelopmentInfo info;
  final VoidCallback? onTap;

  const PregnancyOverviewCard({
    super.key,
    required this.week,
    required this.currentWeek,
    required this.dueDate,
    required this.daysLeft,
    required this.info,
    this.onTap,
  });

  @override
  State<PregnancyOverviewCard> createState() => _PregnancyOverviewCardState();
}

class _PregnancyOverviewCardState extends State<PregnancyOverviewCard> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isSharing = false;

  static final _trimesterColors = [
    const _TrimesterTheme(
      primary: AppTheme.trimester1Primary,
      light: AppTheme.trimester1Light,
      medium: AppTheme.trimester1Medium,
    ),
    const _TrimesterTheme(
      primary: AppTheme.trimester2Primary,
      light: AppTheme.trimester2Light,
      medium: AppTheme.trimester2Medium,
    ),
    const _TrimesterTheme(
      primary: AppTheme.trimester3Primary,
      light: AppTheme.trimester3Light,
      medium: AppTheme.trimester3Medium,
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  _TrimesterTheme get _theme {
    if (widget.week <= 13) return _trimesterColors[0];
    if (widget.week <= 27) return _trimesterColors[1];
    return _trimesterColors[2];
  }

  Future<void> _handleShare() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    try {
      // Capture the widget immediately without artificial delays
      final RenderRepaintBoundary? boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) throw Exception('Repaint boundary not found');

      final ui.Image image = await boundary.toImage(
        pixelRatio: 3.0,
      ); // High quality
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null || byteData.lengthInBytes == 0) {
        throw Exception('Failed to generate image data');
      }

      final pngBytes = byteData.buffer.asUint8List();

      // Write to a temporary file, identical to the reliable PDF/CSV approach
      final directory = await getTemporaryDirectory();
      final fileName = 'pregnancy_journey_week_${widget.week}.png';
      final imagePath = '${directory.path}/$fileName';
      final imageFile = File(imagePath);

      await imageFile.writeAsBytes(pngBytes, flush: true);

      if (!mounted) return;

      final box = context.findRenderObject() as RenderBox?;
      final l10n = AppLocalizations.of(context)!;
      final shareText = l10n.preg_share_text(AppConstants.appName, widget.week);

      await PlatformUI.share(
        files: [XFile(imagePath, mimeType: 'image/png')],
        subject: shareText,
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      );

      // Award share badge
      if (mounted) {
        try {
          final gamification = context.read<GamificationProvider>();
          final pregnancyProvider = Provider.of<PregnancyProvider>(
            context,
            listen: false,
          );
          final pregnancyId = pregnancyProvider.pregnancy?.id;
          if (pregnancyId != null) {
            final newBadges = await gamification.awardShareBadge(pregnancyId);
            if (mounted && newBadges.isNotEmpty) {
              await showBadgeCelebration(context, newBadges);
            }
          }
        } catch (_) {
          // Badge awarding is non-critical
        }
      }
    } catch (e) {
      debugPrint('Error sharing image: $e');
      if (mounted) {
        PlatformUI.showMessage(
          context,
          message: 'Failed to share image: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = _theme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          key: _boundaryKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 360;
              final isMediumScreen = constraints.maxWidth < 400;

              // Responsive image circle dimensions - balanced compact proportions
              final double imageCircleSize = isSmallScreen
                  ? 78.0
                  : (isMediumScreen ? 86.0 : 94.0);
              final double svgHeight = isSmallScreen
                  ? 50.0
                  : (isMediumScreen ? 56.0 : 62.0);
              final double horizontalPadding = isSmallScreen
                  ? 14.0
                  : (isMediumScreen ? 16.0 : 18.0);
              final double topPadding = isSmallScreen
                  ? 14.0
                  : (isMediumScreen ? 15.0 : 16.0);
              final double spacingBetween = isSmallScreen ? 12.0 : 16.0;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: context.isDarkMode
                        ? [
                            context.appSurfaceColor.withValues(alpha: 0.8),
                            context.appSurfaceColor.withValues(alpha: 0.6),
                          ]
                        : [
                            theme.light.withValues(alpha: 0.95),
                            Colors.white.withValues(alpha: 0.9),
                            theme.light.withValues(alpha: 0.8),
                          ],
                  ),
                  border: Border.all(
                    color: context.isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.isDarkMode
                          ? Colors.black.withValues(alpha: 0.3)
                          : theme.primary.withValues(alpha: 0.12),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onTap,
                        splashColor: theme.primary.withValues(alpha: 0.05),
                        highlightColor: theme.primary.withValues(alpha: 0.02),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                // Subtle inner glow mesh circles
                                Positioned(
                                  right: -40,
                                  top: -40,
                                  child: Container(
                                    width: 160,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          theme.primary.withValues(alpha: 0.15),
                                          theme.primary.withValues(alpha: 0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: -20,
                                  bottom: -20,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          theme.primary.withValues(alpha: 0.08),
                                          theme.primary.withValues(alpha: 0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    horizontalPadding,
                                    topPadding,
                                    horizontalPadding,
                                    isSmallScreen ? 12.0 : 14.0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      _buildBabyImageWithBadge(
                                        theme,
                                        l10n,
                                        size: imageCircleSize,
                                        svgHeight: svgHeight,
                                        isSmallScreen: isSmallScreen,
                                      ),
                                      SizedBox(width: spacingBetween),
                                      Expanded(
                                        child: _buildInfoStack(
                                          l10n,
                                          theme,
                                          isSmallScreen: isSmallScreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            _buildBottomStatsBar(
                              context,
                              l10n,
                              theme,
                              isSmallScreen: isSmallScreen,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBabyImageWithBadge(
    _TrimesterTheme theme,
    AppLocalizations l10n, {
    required double size,
    required double svgHeight,
    required bool isSmallScreen,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Baby image circle
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.isDarkMode
                    ? context.appSurfaceColor
                    : Colors.white,
                border: Border.all(
                  color: context.isDarkMode
                      ? theme.primary.withValues(alpha: 0.2)
                      : Colors.white,
                  width: isSmallScreen ? 2.0 : 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primary.withValues(
                      alpha: context.isDarkMode ? 0.1 : 0.18,
                    ),
                    blurRadius: isSmallScreen ? 12 : 18,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: theme.primary.withValues(alpha: 0.08),
                    blurRadius: 1,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Container(
                margin: EdgeInsets.all(isSmallScreen ? 2.5 : 3.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.primary.withValues(alpha: 0.15),
                      theme.primary.withValues(alpha: 0.02),
                    ],
                  ),
                ),
                child: Center(
                  child: Hero(
                    tag: 'fetus_image_${widget.week}',
                    child: SvgPicture.asset(
                      widget.info.assetPath,
                      height: svgHeight,
                      width: svgHeight,
                      fit: BoxFit.contain,
                      placeholderBuilder: (context) => SizedBox(
                        height: svgHeight,
                        width: svgHeight,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Week badge - localized
          Positioned(
            top: isSmallScreen ? -1 : 0,
            right: isSmallScreen ? -1 : 0,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 6 : 7,
                vertical: isSmallScreen ? 2.5 : 3.5,
              ),
              decoration: BoxDecoration(
                color: theme.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.primary.withValues(alpha: 0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  l10n.health_chart_week_short(widget.week),
                  style: GoogleFonts.nunito(
                    fontSize: isSmallScreen ? 9.5 : 10.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStack(
    AppLocalizations l10n,
    _TrimesterTheme theme, {
    required bool isSmallScreen,
  }) {
    final fruitName = getLocalizedSize(l10n, widget.week).isNotEmpty
        ? getLocalizedSize(l10n, widget.week)
        : widget.info.size;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n.preg_size_label,
                style: GoogleFonts.nunito(
                  fontSize: isSmallScreen ? 9.5 : 10.5,
                  fontWeight: FontWeight.w600,
                  color: context.appTextSecondary,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 4),
            // Share Button
            GestureDetector(
              onTap: _handleShare,
              child: Container(
                padding: EdgeInsets.all(isSmallScreen ? 4 : 5),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: _isSharing
                    ? SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.primary,
                        ),
                      )
                    : Icon(
                        Icons.share_rounded,
                        size: isSmallScreen ? 12 : 13,
                        color: theme.primary,
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 5 : 6),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.spa_rounded,
                size: isSmallScreen ? 14 : 16,
                color: theme.primary,
              ),
            ),
            SizedBox(width: isSmallScreen ? 6 : 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  fruitName,
                  style: GoogleFonts.nunito(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.w800,
                    color: context.appTextPrimary,
                    height: 1.1,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 5 : 6),
        // Grouped Measurements
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 10,
            vertical: isSmallScreen ? 4.5 : 5.5,
          ),
          decoration: BoxDecoration(
            color: context.appGlassColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.isDarkMode
                  ? context.appGlassBorderColor
                  : theme.primary.withValues(alpha: 0.1),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSmallMeasurement(
                  Icons.straighten_rounded,
                  widget.info.height,
                  theme,
                  fontSize: isSmallScreen ? 11 : 12,
                  iconSize: isSmallScreen ? 11 : 12,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 5 : 7,
                  ),
                  child: Container(
                    width: 1,
                    height: 11,
                    color: theme.primary.withValues(alpha: 0.2),
                  ),
                ),
                _buildSmallMeasurement(
                  Icons.scale_rounded,
                  widget.info.weight,
                  theme,
                  fontSize: isSmallScreen ? 11 : 12,
                  iconSize: isSmallScreen ? 11 : 12,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallMeasurement(
    IconData icon,
    String value,
    _TrimesterTheme theme, {
    double fontSize = 12,
    double iconSize = 12,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: theme.primary),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: context.appTextPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildBottomStatsBar(
    BuildContext context,
    AppLocalizations l10n,
    _TrimesterTheme theme, {
    required bool isSmallScreen,
  }) {
    final dateFormat = DateFormat.MMMd(l10n.localeName);
    const totalWeeks = 40;
    const t1End = 13;
    const t2End = 27;

    final progress = (widget.week / totalWeeks).clamp(0.0, 1.0);
    final currentProgress = (widget.currentWeek / totalWeeks).clamp(0.0, 1.0);

    int viewedTrimester = 1;
    if (widget.week > t2End) {
      viewedTrimester = 3;
    } else if (widget.week > t1End) {
      viewedTrimester = 2;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 14 : 18,
        vertical: isSmallScreen ? 11 : 14,
      ),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? context.appSurfaceColor.withValues(alpha: 0.8)
            : Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        border: Border(
          top: BorderSide(
            color: context.isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : theme.primary.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Simplified Stats Row - Evenly distributed
          Row(
            children: [
              Expanded(
                child: Center(
                  child: _buildStatItem(
                    Icons.calendar_today_rounded,
                    l10n.legend_expected,
                    dateFormat.format(widget.dueDate),
                    theme,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
              ),
              _buildStatDivider(theme),
              Expanded(
                child: Center(
                  child: _buildStatItem(
                    Icons.hourglass_bottom_rounded,
                    l10n.preg_days_left,
                    l10n.period_days_left(widget.daysLeft),
                    theme,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isSmallScreen ? 9 : 12),

          // Progress Bar
          _buildProgressBar(
            l10n,
            progress,
            currentProgress,
            viewedTrimester,
            theme,
            isSmallScreen: isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(_TrimesterTheme theme) {
    return Container(
      width: 1,
      height: 22,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.primary.withValues(alpha: 0.0),
            theme.primary.withValues(alpha: 0.15),
            theme.primary.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    _TrimesterTheme theme, {
    required bool isSmallScreen,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: isSmallScreen ? 13 : 15, color: theme.primary),
        SizedBox(width: isSmallScreen ? 5 : 7),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: isSmallScreen ? 9 : 10,
                  fontWeight: FontWeight.w600,
                  color: context.appTextSecondary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.nunito(
                    fontSize: isSmallScreen ? 12.5 : 13.5,
                    fontWeight: FontWeight.w800,
                    color: context.appTextPrimary,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(
    AppLocalizations l10n,
    double progress,
    double currentProgress,
    int viewedTrimester,
    _TrimesterTheme theme, {
    required bool isSmallScreen,
  }) {
    const totalWeeks = 40;
    const t1End = 13;
    const t2End = 27;

    return Column(
      children: [
        SizedBox(
          height: 5,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final t1Width = width * (t1End / totalWeeks);
              final t2Width = width * ((t2End - t1End) / totalWeeks);
              final t3Width = width * ((totalWeeks - t2End) / totalWeeks);
              const gap = 2.0;

              return Stack(
                children: [
                  // Background segments
                  Row(
                    children: [
                      _buildSegment(
                        t1Width - gap,
                        _trimesterColors[0].primary.withValues(alpha: 0.2),
                        true,
                        false,
                      ),
                      const SizedBox(width: gap),
                      _buildSegment(
                        t2Width - gap,
                        _trimesterColors[1].primary.withValues(alpha: 0.2),
                        false,
                        false,
                      ),
                      const SizedBox(width: gap),
                      _buildSegment(
                        t3Width,
                        _trimesterColors[2].primary.withValues(alpha: 0.2),
                        false,
                        true,
                      ),
                    ],
                  ),
                  // Progress overlay
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    width: width * progress,
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.horizontal(
                        left: const Radius.circular(2.5),
                        right: progress >= 1.0
                            ? const Radius.circular(2.5)
                            : const Radius.circular(2),
                      ),
                    ),
                  ),
                  // Current week indicator
                  if (widget.week != widget.currentWeek)
                    Positioned(
                      left: (width * currentProgress) - 4,
                      top: -1.5,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? context.appSurfaceColor
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.primary, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        SizedBox(height: isSmallScreen ? 5 : 6),
        // Trimester Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTrimesterLabelText(
              l10n.preg_trimester_1_short,
              1,
              viewedTrimester,
              _trimesterColors[0].primary,
              isSmallScreen: isSmallScreen,
            ),
            _buildTrimesterLabelText(
              l10n.preg_trimester_2_short,
              2,
              viewedTrimester,
              _trimesterColors[1].primary,
              isSmallScreen: isSmallScreen,
            ),
            _buildTrimesterLabelText(
              l10n.preg_trimester_3_short,
              3,
              viewedTrimester,
              _trimesterColors[2].primary,
              isSmallScreen: isSmallScreen,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSegment(double width, Color color, bool isFirst, bool isLast) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.horizontal(
          left: isFirst ? const Radius.circular(2.5) : Radius.zero,
          right: isLast ? const Radius.circular(2.5) : Radius.zero,
        ),
      ),
    );
  }

  Widget _buildTrimesterLabelText(
    String label,
    int trimester,
    int currentTrimester,
    Color color, {
    required bool isSmallScreen,
  }) {
    final isActive = trimester == currentTrimester;
    final isPast = trimester < currentTrimester;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isSmallScreen ? 4.5 : 5,
          height: isSmallScreen ? 4.5 : 5,
          decoration: BoxDecoration(
            color: isActive
                ? color
                : (isPast
                      ? color.withValues(alpha: 0.6)
                      : color.withValues(alpha: 0.3)),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: isSmallScreen ? 3 : 4),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: isSmallScreen ? 9.5 : 10.5,
              fontWeight: FontWeight.w800,
              color: isActive
                  ? color
                  : (isPast ? context.appTextSecondary : AppTheme.textHint),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class _TrimesterTheme {
  final Color primary;
  final Color light;
  final Color medium;

  const _TrimesterTheme({
    required this.primary,
    required this.light,
    required this.medium,
  });
}
