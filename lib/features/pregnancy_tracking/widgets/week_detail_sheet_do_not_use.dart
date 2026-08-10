import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../data/fetus_development_data.dart';
import '../providers/pregnancy_provider.dart';
import '../data/pregnancy_localization_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/constants/app_constants.dart';
import '../models/weight_entry_model.dart';
import '../models/appointment_model.dart';

/// Beautiful bottom sheet to display week details in the journey map
class WeekDetailSheet extends StatefulWidget {
  final int week;
  final bool isCurrentWeek;
  final bool isPast;
  final VoidCallback? onClose;

  const WeekDetailSheet({
    super.key,
    required this.week,
    required this.isCurrentWeek,
    required this.isPast,
    this.onClose,
  });

  /// Show the week detail sheet
  static Future<void> show(
    BuildContext context, {
    required int week,
    required bool isCurrentWeek,
    required bool isPast,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WeekDetailSheet(
        week: week,
        isCurrentWeek: isCurrentWeek,
        isPast: isPast,
      ),
    );
  }

  @override
  State<WeekDetailSheet> createState() => _WeekDetailSheetState();
}

class _WeekDetailSheetState extends State<WeekDetailSheet>
    with TickerProviderStateMixin {
  late TabController _tabController;

  int get week => widget.week;
  bool get isCurrentWeek => widget.isCurrentWeek;
  bool get isPast => widget.isPast;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = FetusDevelopmentData.getInfo(week);
    final l10n = AppLocalizations.of(context)!;
    final themeColor = AppTheme.getTrimesterColor(week);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppTheme.darkSurfaceColor
        : context.appSurfaceColor;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHandleBar(),
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildSliverHeader(context, info, l10n, themeColor),
                    _buildSliverTabBar(l10n, themeColor, backgroundColor),
                    SliverFillRemaining(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildDevelopmentTab(context, info, l10n, themeColor),
                          _buildHealthTab(context, info, l10n, themeColor),
                          _buildTipsTab(context, info, l10n, themeColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandleBar() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 48,
        height: 5,
        decoration: BoxDecoration(
          color: context.appBorderColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _buildSliverHeader(
    BuildContext context,
    FetusDevelopmentInfo info,
    AppLocalizations l10n,
    Color themeColor,
  ) {
    final themeLight = AppTheme.getTrimesterBackgroundColor(week);
    final themeMedium = AppTheme.getTrimesterMediumColor(week);
    final sizeText = _getLocalizedSize(l10n, week);
    final trimester = week <= 13 ? 1 : (week <= 27 ? 2 : 3);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.paddingMediumLarge,
          AppConstants.spacingSmall,
          AppConstants.paddingMediumLarge,
          AppConstants.spacingSmall,
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              AppConstants.borderRadiusXXLarge,
            ),
            border: Border.all(color: context.appGlassBorderColor),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(AppConstants.paddingMediumLarge),
              decoration: BoxDecoration(
                color: context.appGlassColor,
                gradient: LinearGradient(
                  colors: [
                    themeLight.withValues(
                      alpha: context.isDarkMode ? 0.15 : 0.4,
                    ),
                    themeMedium.withValues(
                      alpha: context.isDarkMode ? 0.05 : 0.2,
                    ),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  _buildEnhancedFetusVisualization(
                    info,
                    themeColor,
                    themeLight,
                  ),
                  const SizedBox(width: AppConstants.spacingMediumLarge),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadiusSmall,
                                ),
                              ),
                              child: Text(
                                l10n
                                    .preg_trimester_label(trimester)
                                    .toUpperCase(),
                                style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: themeColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (isCurrentWeek) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadiusSmall,
                                  ),
                                ),
                                child: Text(
                                  l10n.common_current.toUpperCase(),
                                  style: GoogleFonts.nunito(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.successColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.preg_week(week),
                          style: GoogleFonts.nunito(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: context.appTextPrimary,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          l10n.preg_as_big_as(sizeText).toUpperCase(),
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: context.appTextSecondary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildMiniStat(
                              Icons.straighten_rounded,
                              info.height,
                              themeColor,
                            ),
                            const SizedBox(width: 12),
                            _buildMiniStat(
                              Icons.scale_rounded,
                              info.weight,
                              themeColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: context.appTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedFetusVisualization(
    FetusDevelopmentInfo info,
    Color themeColor,
    Color themeLight,
  ) {
    return Hero(
      tag: 'fetus_week_$week',
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow Layers
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  themeColor.withValues(alpha: 0.25),
                  themeColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: context.isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
          ),
          // Inner Circle
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: context.appSurfaceColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: themeColor.withValues(
                    alpha: context.isDarkMode ? 0.4 : 0.2,
                  ),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(
                color: context.isDarkMode
                    ? themeColor.withValues(alpha: 0.3)
                    : Colors.white,
                width: 3,
              ),
            ),
            child: ClipOval(
              child: Container(
                color: themeLight.withValues(alpha: 0.5),
                padding: const EdgeInsets.all(8),
                child: SvgPicture.asset(
                  info.assetPath,
                  fit: BoxFit.contain,
                  placeholderBuilder: (context) => Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: themeColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverTabBar(
    AppLocalizations l10n,
    Color themeColor,
    Color backgroundColor,
  ) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: context.appBorderColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.all(5),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: context.isDarkMode ? context.appCardColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(
                      alpha: context.isDarkMode ? 0.3 : 0.1,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: themeColor,
              unselectedLabelColor: context.appTextSecondary,
              labelStyle: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(text: l10n.preg_whats_happening),
                Tab(text: l10n.health_title),
                Tab(text: l10n.preg_tips_tab),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== TAB CONTENT ==========

  Widget _buildDevelopmentTab(
    BuildContext context,
    FetusDevelopmentInfo info,
    AppLocalizations l10n,
    Color themeColor,
  ) {
    final description = _getLocalizedDescription(l10n, week);
    final milestones = _getWeekMilestones(week);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingMediumLarge,
        AppConstants.paddingSmall + 2,
        AppConstants.paddingMediumLarge,
        AppConstants.paddingXXLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppConstants.spacingSmall + 2),
          // Insight Highlight
          _buildPremiumInsightCard(
            icon: Icons.auto_awesome_rounded,
            title: l10n.preg_whats_happening,
            content: description,
            themeColor: themeColor,
          ),
          const SizedBox(height: AppConstants.spacingMediumLarge),
          // Milestones
          if (milestones.isNotEmpty)
            _buildMilestonesCard(milestones, themeColor, l10n),

          const SizedBox(height: AppConstants.spacingMediumLarge),
          // Progress Insight
          _buildProgressInsight(themeColor, l10n),
          const SizedBox(height: AppConstants.spacingMediumLarge),
        ],
      ),
    );
  }

  // ========== UI COMPONENTS DESIGN PHILOSOPHY ==========

  Widget _buildPremiumCard({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
    EdgeInsets? padding,
    bool useGlass = false,
  }) {
    final isDark = context.isDarkMode;
    return Container(
      padding: padding ?? const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: useGlass
            ? context.appGlassColor
            : (isDark
                  ? context.appCardColor.withValues(alpha: 0.6)
                  : context.appCardColor),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusXXLarge),
        border: Border.all(
          color: useGlass
              ? context.appGlassBorderColor
              : (isDark
                    ? color.withValues(alpha: 0.15)
                    : color.withValues(alpha: 0.1)),
          width: 1,
        ),
        boxShadow: [
          if (!isDark && !useGlass)
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMediumLarge),
          child,
        ],
      ),
    );
  }

  Widget _buildPremiumInsightCard({
    required IconData icon,
    required String title,
    required String content,
    required Color themeColor,
  }) {
    return _buildPremiumCard(
      icon: icon,
      title: title,
      color: themeColor,
      child: Text(
        content,
        style: GoogleFonts.nunito(
          fontSize: 15,
          color: context.appTextPrimary,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMilestonesCard(
    List<String> milestones,
    Color themeColor,
    AppLocalizations l10n,
  ) {
    return _buildPremiumCard(
      icon: Icons.flag_rounded,
      title: l10n.preg_milestones,
      color: themeColor,
      child: Column(
        children: milestones.map((milestone) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: themeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    milestone,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: context.appTextPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProgressInsight(Color themeColor, AppLocalizations l10n) {
    final progress = (week / 40.0).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [themeColor, themeColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusXXLarge),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.preg_progress,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.preg_weeks_until_due_date(40 - week),
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTab(
    BuildContext context,
    FetusDevelopmentInfo info,
    AppLocalizations l10n,
    Color themeColor,
  ) {
    return Consumer<PregnancyProvider>(
      builder: (context, provider, child) {
        final weeklyWeights = provider.weeklyWeights[week] ?? [];
        final weeklyAppts = provider.weeklyAppointments[week] ?? [];
        final symptoms = _getWeekSymptoms(week);
        final checklist = getLocalizedChecklist(l10n, info.week);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.paddingMediumLarge,
            AppConstants.paddingSmall + 2,
            AppConstants.paddingMediumLarge,
            AppConstants.paddingXXLarge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppConstants.spacingSmall + 2),
              // Symptoms Summary
              _buildSymptomsHealthCard(symptoms, l10n),
              const SizedBox(height: AppConstants.spacingMediumLarge),
              // Records Card
              if (weeklyWeights.isNotEmpty || weeklyAppts.isNotEmpty)
                _buildRecordsCard(weeklyWeights, weeklyAppts, l10n, themeColor),
              const SizedBox(height: AppConstants.spacingMediumLarge),
              // Interactive Checklist
              if (checklist.isNotEmpty)
                _buildModernChecklist(checklist, themeColor, l10n),
              const SizedBox(height: AppConstants.spacingMediumLarge),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSymptomsHealthCard(
    List<String> symptoms,
    AppLocalizations l10n,
  ) {
    return _buildPremiumCard(
      icon: Icons.favorite_rounded,
      title: l10n.preg_moms_health,
      color: Colors.pink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.preg_common_symptoms,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: context.appTextSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: symptoms.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.pink.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.pink.withValues(alpha: 0.1)),
                ),
                child: Text(
                  s,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: Colors.pink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsCard(
    List<dynamic> weights,
    List<dynamic> appts,
    AppLocalizations l10n,
    Color themeColor,
  ) {
    return _buildPremiumCard(
      icon: Icons.assignment_rounded,
      title: l10n.preg_your_records,
      color: context.appTextSecondary,
      child: Column(
        children: [
          ...weights.map(
            (w) => _buildEnhancedRecordItem(
              icon: Icons.monitor_weight_rounded,
              label: l10n.preg_weight_entry,
              value: '${(w as WeightEntry).weightValue}',
              color: themeColor,
            ),
          ),
          ...appts.map(
            (a) => _buildEnhancedRecordItem(
              icon: Icons.event_available_rounded,
              label: (a as Appointment).title,
              value: a.notes ?? l10n.preg_no_notes,
              color: themeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedRecordItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: context.appTextSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    color: context.appTextPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernChecklist(
    List<String> items,
    Color themeColor,
    AppLocalizations l10n,
  ) {
    return _buildPremiumCard(
      icon: Icons.checklist_rounded,
      title: l10n.preg_weekly_checklist,
      color: AppTheme.successColor,
      child: Column(
        children: [
          if (isPast)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.preg_week_completed,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildModernChecklistItem(item, index, themeColor);
          }),
        ],
      ),
    );
  }

  Widget _buildModernChecklistItem(String text, int index, Color themeColor) {
    final checked = isPast;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appSurfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: checked
                ? AppTheme.successColor.withValues(alpha: 0.3)
                : context.appBorderColor.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: checked ? AppTheme.successColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: checked ? AppTheme.successColor : themeColor,
                  width: 2,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: checked ? FontWeight.w600 : FontWeight.w700,
                  color: checked
                      ? context.appTextSecondary
                      : context.appTextPrimary,
                  decoration: checked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsTab(
    BuildContext context,
    FetusDevelopmentInfo info,
    AppLocalizations l10n,
    Color themeColor,
  ) {
    final tip = _getLocalizedTip(l10n, week);
    final doList = _getWeekDos(week);
    final dontList = _getWeekDonts(week);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingMediumLarge,
        AppConstants.paddingSmall + 2,
        AppConstants.paddingMediumLarge,
        AppConstants.paddingXXLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppConstants.spacingSmall + 2),
          // Weekly Tip Large Highlight
          _buildExtraTipCard(tip, themeColor, l10n),
          const SizedBox(height: AppConstants.spacingLarge),
          // Dos and Don'ts
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSimpleListCard(
                  title: l10n.preg_dos,
                  items: doList
                      .take(AppConstants.defaultPeriodLength.clamp(0, 3))
                      .toList(),
                  color: AppTheme.successColor,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: AppConstants.spacingMedium),
              Expanded(
                child: _buildSimpleListCard(
                  title: l10n.preg_donts,
                  items: dontList.take(3).toList(),
                  color: AppTheme.errorColor,
                  icon: Icons.highlight_off_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingLarge),
          _buildHealthAlertCard(l10n),
          const SizedBox(height: AppConstants.paddingXXLarge),
        ],
      ),
    );
  }

  Widget _buildExtraTipCard(
    String tip,
    Color themeColor,
    AppLocalizations l10n,
  ) {
    return _buildPremiumCard(
      icon: Icons.lightbulb_rounded,
      title: l10n.preg_tip_of_the_week,
      color: Colors.amber.shade900,
      child: Text(
        tip,
        style: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: context.appTextPrimary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildSimpleListCard({
    required String title,
    required List<String> items,
    required Color color,
    required IconData icon,
  }) {
    return _buildPremiumCard(
      icon: icon,
      title: title,
      color: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.appTextPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHealthAlertCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              l10n.preg_health_alert_desc,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== HELPER DATA METHODS ==========

  List<String> _getWeekMilestones(int week) {
    // Return development milestones based on week
    // This is a simplified version - you can expand with localized data
    if (week <= 4) {
      return [
        'Fertilization and implantation',
        'Cells begin dividing rapidly',
        'Placenta starts forming',
      ];
    } else if (week <= 8) {
      return [
        'Major organs beginning to form',
        'Heart starts beating',
        'Neural tube development',
      ];
    } else if (week <= 12) {
      return [
        'Fingers and toes forming',
        'Facial features developing',
        'Movement begins (not felt yet)',
      ];
    } else if (week <= 16) {
      return [
        'Gender may be visible on ultrasound',
        'Bones hardening',
        'Hearing developing',
      ];
    } else if (week <= 20) {
      return [
        'You may feel baby move!',
        'Fingerprints forming',
        'Regular sleep patterns',
      ];
    } else if (week <= 24) {
      return [
        'Lungs developing rapidly',
        'Responds to sounds',
        'Taste buds forming',
      ];
    } else if (week <= 28) {
      return [
        'Eyes can open and close',
        'Brain growing rapidly',
        'Regular breathing movements',
      ];
    } else if (week <= 32) {
      return [
        'Gaining weight quickly',
        'Bones fully developed',
        'Practice breathing',
      ];
    } else if (week <= 36) {
      return [
        'Baby dropping into pelvis',
        'Lungs nearly mature',
        'Immune system developing',
      ];
    } else {
      return ['Considered full term', 'Ready for birth', 'Final weight gain'];
    }
  }

  List<String> _getWeekSymptoms(int week) {
    if (week <= 8) {
      return ['Fatigue', 'Nausea', 'Tender breasts', 'Frequent urination'];
    } else if (week <= 16) {
      return [
        'Reduced nausea',
        'Growing belly',
        'Food cravings',
        'Mood changes',
      ];
    } else if (week <= 24) {
      return ['Baby kicks', 'Back pain', 'Leg cramps', 'Stretch marks'];
    } else if (week <= 32) {
      return ['Shortness of breath', 'Heartburn', 'Swelling', 'Braxton Hicks'];
    } else {
      return [
        'Pelvic pressure',
        'Frequent urination',
        'Trouble sleeping',
        'Nesting instinct',
      ];
    }
  }

  List<String> _getWeekDos(int week) {
    return [
      'Stay hydrated with 8-10 glasses of water daily',
      'Take prenatal vitamins as prescribed',
      'Get regular moderate exercise',
      'Eat balanced, nutritious meals',
      'Get plenty of rest and sleep',
    ];
  }

  List<String> _getWeekDonts(int week) {
    return [
      'Avoid alcohol and smoking',
      'Limit caffeine intake',
      'Avoid raw or undercooked foods',
      'Skip hot tubs and saunas',
      'Avoid heavy lifting',
    ];
  }

  // ========== LOCALIZATION HELPERS ==========

  String _getLocalizedSize(AppLocalizations l10n, int week) {
    switch (week) {
      case 1:
        return l10n.preg_week_1_size;
      case 2:
        return l10n.preg_week_2_size;
      case 3:
        return l10n.preg_week_3_size;
      case 4:
        return l10n.preg_week_4_size;
      case 5:
        return l10n.preg_week_5_size;
      case 6:
        return l10n.preg_week_6_size;
      case 7:
        return l10n.preg_week_7_size;
      case 8:
        return l10n.preg_week_8_size;
      case 9:
        return l10n.preg_week_9_size;
      case 10:
        return l10n.preg_week_10_size;
      case 11:
        return l10n.preg_week_11_size;
      case 12:
        return l10n.preg_week_12_size;
      case 13:
        return l10n.preg_week_13_size;
      case 14:
        return l10n.preg_week_14_size;
      case 15:
        return l10n.preg_week_15_size;
      case 16:
        return l10n.preg_week_16_size;
      case 17:
        return l10n.preg_week_17_size;
      case 18:
        return l10n.preg_week_18_size;
      case 19:
        return l10n.preg_week_19_size;
      case 20:
        return l10n.preg_week_20_size;
      case 21:
        return l10n.preg_week_21_size;
      case 22:
        return l10n.preg_week_22_size;
      case 23:
        return l10n.preg_week_23_size;
      case 24:
        return l10n.preg_week_24_size;
      case 25:
        return l10n.preg_week_25_size;
      case 26:
        return l10n.preg_week_26_size;
      case 27:
        return l10n.preg_week_27_size;
      case 28:
        return l10n.preg_week_28_size;
      case 29:
        return l10n.preg_week_29_size;
      case 30:
        return l10n.preg_week_30_size;
      case 31:
        return l10n.preg_week_31_size;
      case 32:
        return l10n.preg_week_32_size;
      case 33:
        return l10n.preg_week_33_size;
      case 34:
        return l10n.preg_week_34_size;
      case 35:
        return l10n.preg_week_35_size;
      case 36:
        return l10n.preg_week_36_size;
      case 37:
        return l10n.preg_week_37_size;
      case 38:
        return l10n.preg_week_38_size;
      case 39:
        return l10n.preg_week_39_size;
      case 40:
        return l10n.preg_week_40_size;
      default:
        return '';
    }
  }

  String _getLocalizedDescription(AppLocalizations l10n, int week) {
    switch (week) {
      case 1:
        return l10n.preg_week_1_desc;
      case 2:
        return l10n.preg_week_2_desc;
      case 3:
        return l10n.preg_week_3_desc;
      case 4:
        return l10n.preg_week_4_desc;
      case 5:
        return l10n.preg_week_5_desc;
      case 6:
        return l10n.preg_week_6_desc;
      case 7:
        return l10n.preg_week_7_desc;
      case 8:
        return l10n.preg_week_8_desc;
      case 9:
        return l10n.preg_week_9_desc;
      case 10:
        return l10n.preg_week_10_desc;
      case 11:
        return l10n.preg_week_11_desc;
      case 12:
        return l10n.preg_week_12_desc;
      case 13:
        return l10n.preg_week_13_desc;
      case 14:
        return l10n.preg_week_14_desc;
      case 15:
        return l10n.preg_week_15_desc;
      case 16:
        return l10n.preg_week_16_desc;
      case 17:
        return l10n.preg_week_17_desc;
      case 18:
        return l10n.preg_week_18_desc;
      case 19:
        return l10n.preg_week_19_desc;
      case 20:
        return l10n.preg_week_20_desc;
      case 21:
        return l10n.preg_week_21_desc;
      case 22:
        return l10n.preg_week_22_desc;
      case 23:
        return l10n.preg_week_23_desc;
      case 24:
        return l10n.preg_week_24_desc;
      case 25:
        return l10n.preg_week_25_desc;
      case 26:
        return l10n.preg_week_26_desc;
      case 27:
        return l10n.preg_week_27_desc;
      case 28:
        return l10n.preg_week_28_desc;
      case 29:
        return l10n.preg_week_29_desc;
      case 30:
        return l10n.preg_week_30_desc;
      case 31:
        return l10n.preg_week_31_desc;
      case 32:
        return l10n.preg_week_32_desc;
      case 33:
        return l10n.preg_week_33_desc;
      case 34:
        return l10n.preg_week_34_desc;
      case 35:
        return l10n.preg_week_35_desc;
      case 36:
        return l10n.preg_week_36_desc;
      case 37:
        return l10n.preg_week_37_desc;
      case 38:
        return l10n.preg_week_38_desc;
      case 39:
        return l10n.preg_week_39_desc;
      case 40:
        return l10n.preg_week_40_desc;
      default:
        return '';
    }
  }

  String _getLocalizedTip(AppLocalizations l10n, int week) {
    switch (week) {
      case 1:
        return l10n.preg_week_1_tip;
      case 2:
        return l10n.preg_week_2_tip;
      case 3:
        return l10n.preg_week_3_tip;
      case 4:
        return l10n.preg_week_4_tip;
      case 5:
        return l10n.preg_week_5_tip;
      case 6:
        return l10n.preg_week_6_tip;
      case 7:
        return l10n.preg_week_7_tip;
      case 8:
        return l10n.preg_week_8_tip;
      case 9:
        return l10n.preg_week_9_tip;
      case 10:
        return l10n.preg_week_10_tip;
      case 11:
        return l10n.preg_week_11_tip;
      case 12:
        return l10n.preg_week_12_tip;
      case 13:
        return l10n.preg_week_13_tip;
      case 14:
        return l10n.preg_week_14_tip;
      case 15:
        return l10n.preg_week_15_tip;
      case 16:
        return l10n.preg_week_16_tip;
      case 17:
        return l10n.preg_week_17_tip;
      case 18:
        return l10n.preg_week_18_tip;
      case 19:
        return l10n.preg_week_19_tip;
      case 20:
        return l10n.preg_week_20_tip;
      case 21:
        return l10n.preg_week_21_tip;
      case 22:
        return l10n.preg_week_22_tip;
      case 23:
        return l10n.preg_week_23_tip;
      case 24:
        return l10n.preg_week_24_tip;
      case 25:
        return l10n.preg_week_25_tip;
      case 26:
        return l10n.preg_week_26_tip;
      case 27:
        return l10n.preg_week_27_tip;
      case 28:
        return l10n.preg_week_28_tip;
      case 29:
        return l10n.preg_week_29_tip;
      case 30:
        return l10n.preg_week_30_tip;
      case 31:
        return l10n.preg_week_31_tip;
      case 32:
        return l10n.preg_week_32_tip;
      case 33:
        return l10n.preg_week_33_tip;
      case 34:
        return l10n.preg_week_34_tip;
      case 35:
        return l10n.preg_week_35_tip;
      case 36:
        return l10n.preg_week_36_tip;
      case 37:
        return l10n.preg_week_37_tip;
      case 38:
        return l10n.preg_week_38_tip;
      case 39:
        return l10n.preg_week_39_tip;
      case 40:
        return l10n.preg_week_40_tip;
      default:
        return '';
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverAppBarDelegate({required this.child});

  @override
  double get minExtent => 74;
  @override
  double get maxExtent => 74;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
