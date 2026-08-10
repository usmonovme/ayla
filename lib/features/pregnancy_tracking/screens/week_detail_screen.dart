import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/fetus_development_data.dart';
import '../providers/pregnancy_provider.dart';
import '../providers/labor_provider.dart';
import '../data/pregnancy_localization_helper.dart';
import '../../../l10n/app_localizations.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/section_header.dart';
import '../widgets/weight_log_card.dart';
import '../widgets/appointment_log_card.dart';
import '../widgets/kick_log_card.dart';
import '../widgets/contraction_log_card.dart';
import '../models/weight_entry_model.dart';
import '../../../core/widgets/ambient_bottom_scrim.dart';

class WeekDetailScreen extends StatefulWidget {
  final int week;
  final bool isCurrentWeek;
  final bool isPast;

  const WeekDetailScreen({
    super.key,
    required this.week,
    required this.isCurrentWeek,
    required this.isPast,
  });

  static Future<void> show(
    BuildContext context, {
    required int week,
    required bool isCurrentWeek,
    required bool isPast,
  }) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => WeekDetailScreen(
          week: week,
          isCurrentWeek: isCurrentWeek,
          isPast: isPast,
        ),
      ),
    );
  }

  @override
  State<WeekDetailScreen> createState() => _WeekDetailScreenState();
}

class _WeekDetailScreenState extends State<WeekDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int get week => widget.week;
  bool get isCurrentWeek => widget.isCurrentWeek;
  bool get isPast => widget.isPast;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(gradient: context.appBackgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: false,
        appBar: BrandedAppBar(
          isPregnancy: true,
          title: Text(l10n.preg_week(week)),
        ),
        body: Consumer2<PregnancyProvider, LaborProvider>(
          builder: (context, provider, laborProvider, child) {
            return Stack(
              children: [
                TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDevelopmentTab(context, info, l10n, themeColor),
                    _buildHealthTab(
                      context,
                      info,
                      l10n,
                      themeColor,
                      provider,
                      laborProvider,
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ModernTabBar(
                    controller: _tabController,
                    tabs: [l10n.preg_tab_development, l10n.health_title],
                  ),
                ),
                const AmbientBottomScrim(),
              ],
            );
          },
        ),
      ),
    );
  }

  TextStyle get _bodyStyle => GoogleFonts.nunito(
    fontSize: 15,
    color: context.appTextPrimary.withValues(alpha: 0.9),
    height: 1.6,
    fontWeight: FontWeight.w500,
  );

  Widget _buildInfoCallout({
    required BuildContext context,
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color.withValues(alpha: 0.95),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    content,
                    style: _bodyStyle.copyWith(
                      fontSize: 14,
                      color: context.appTextPrimary.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevelopmentTab(
    BuildContext context,
    FetusDevelopmentInfo info,
    AppLocalizations l10n,
    Color themeColor,
  ) {
    final description = getLocalizedDescription(l10n, week);
    final tip = getLocalizedTip(l10n, week);
    final babyGrowthDetailed = getLocalizedBabyGrowthDetailed(l10n, week);
    final motherChangesDetailed = getLocalizedMotherChangesDetailed(l10n, week);
    final scientificInsight = getLocalizedScientificInsight(l10n, week);
    final medicalNote = getLocalizedMedicalNote(l10n, week);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        64,
        16,
        MediaQuery.paddingOf(context).bottom + 60.0,
      ),
      children: [
        _buildHeroHeader(context, info, l10n, themeColor),
        const SizedBox(height: 24),

        // CHAPTER 1: THE GROWING LIFE
        SectionHeader(title: l10n.preg_chapter_baby, color: themeColor),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(description, style: _bodyStyle),
              if (babyGrowthDetailed != null) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                Text(
                  l10n.preg_baby_development_detailed_title,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(babyGrowthDetailed, style: _bodyStyle),
              ],
              if (scientificInsight != null) ...[
                const SizedBox(height: 20),
                _buildInfoCallout(
                  context: context,
                  title: l10n.preg_scientific_insight_title,
                  content: scientificInsight,
                  icon: Icons.science_rounded,
                  color: Colors.blueAccent,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 32),

        // CHAPTER 2: YOUR EXPERIENCE
        SectionHeader(title: l10n.preg_moms_health, color: themeColor),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (motherChangesDetailed != null) ...[
                Text(motherChangesDetailed, style: _bodyStyle),
                const SizedBox(height: 20),
              ],
              _buildInfoCallout(
                context: context,
                title: l10n.preg_tip_of_the_week,
                content: tip,
                icon: Icons.lightbulb_rounded,
                color: Colors.amber,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // CHAPTER 3: WEEKLY ROADMAP
        SectionHeader(title: l10n.preg_progress, color: themeColor),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.preg_milestones,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildMilestonesList(info, l10n, themeColor),
              if (medicalNote != null) ...[
                const SizedBox(height: 20),
                _buildInfoCallout(
                  context: context,
                  title: l10n.preg_medical_note_title,
                  content: medicalNote,
                  icon: Icons.medical_services_rounded,
                  color: Colors.redAccent,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroHeader(
    BuildContext context,
    FetusDevelopmentInfo info,
    AppLocalizations l10n,
    Color themeColor,
  ) {
    final sizeText = getLocalizedSize(l10n, week);
    final trimester = (week <= 13)
        ? 1
        : (week <= 27)
        ? 2
        : 3;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: context.isDarkMode
                    ? [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.02)]
                    : [themeColor.withValues(alpha: 0.15), themeColor.withValues(alpha: 0.05)],
              ),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: themeColor.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            child: SvgPicture.asset(
              info.assetPath,
              width: 64,
              height: 64,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _buildTrimesterBadge(l10n, trimester, themeColor),
                    const SizedBox(width: 8),
                    Text(
                      l10n.preg_week(week),
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: themeColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  sizeText,
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: context.appTextPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.straighten_rounded, size: 14, color: themeColor),
                    const SizedBox(width: 4),
                    Text(
                      info.height,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.appTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.scale_rounded, size: 14, color: themeColor),
                    const SizedBox(width: 4),
                    Text(
                      info.weight,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrimesterBadge(
    AppLocalizations l10n,
    int trimester,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        l10n.preg_trimester_badge(trimester),
        style: GoogleFonts.nunito(
          fontSize: 10, // slightly larger since it's not all caps anymore
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMilestonesList(
    FetusDevelopmentInfo info,
    AppLocalizations l10n,
    Color themeColor,
  ) {
    final milestones = _getWeekMilestones(l10n, week);
    if (milestones.isEmpty) return const SizedBox.shrink();

    return Column(
      children: milestones.asMap().entries.map((entry) {
        final i = entry.key;
        final milestone = entry.value;
        final isLast = i == milestones.length - 1;

        return _buildMilestoneItem(milestone, isLast, themeColor);
      }).toList(),
    );
  }

  Widget _buildMilestoneItem(String text, bool isLast, Color themeColor) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: context.isDarkMode 
                        ? context.appSurfaceColor 
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: themeColor, width: 3.5),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 4, bottom: 4),
                      color: themeColor.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Text(
                text,
                style: _bodyStyle,
              ),
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
    PregnancyProvider provider,
    LaborProvider laborProvider,
  ) {
    final preg = provider.pregnancy;

    final weeklyWeights = provider.weights.where((w) {
      if (preg == null) return false;
      final diff = w.date.difference(preg.lastPeriodDate).inDays;
      final wWeek = (diff / 7).floor() + 1;
      return wWeek == week;
    }).toList();

    final weeklyAppts = provider.appointments.where((a) {
      if (preg == null) return false;
      final diff = a.date.difference(preg.lastPeriodDate).inDays;
      final aWeek = (diff / 7).floor() + 1;
      return aWeek == week;
    }).toList();

    final weeklyKicks = provider.kickSessions.where((s) {
      if (preg == null) return false;
      final diff = s.startTime.difference(preg.lastPeriodDate).inDays;
      final sWeek = (diff / 7).floor() + 1;
      return sWeek == week;
    }).toList();

    final weeklyContractions = laborProvider.contractions.where((c) {
      if (preg == null) return false;
      final diff = c.startTime.difference(preg.lastPeriodDate).inDays;
      final cWeek = (diff / 7).floor() + 1;
      return cWeek == week;
    }).toList();

    final weightUnit =
        context.watch<AuthProvider>().userProfile?.preferences.weightUnit ??
        WeightUnit.kg;
    final unitSuffix = weightUnit.name.toLowerCase();

    final hasRecords =
        weeklyWeights.isNotEmpty ||
        weeklyAppts.isNotEmpty ||
        weeklyKicks.isNotEmpty ||
        weeklyContractions.isNotEmpty;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        64,
        16,
        MediaQuery.paddingOf(context).bottom + 60.0,
      ),
      children: [
        SectionHeader(title: l10n.preg_moms_health, color: themeColor),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: _buildSymptomsList(l10n, week, themeColor),
        ),

        if (hasRecords) ...[
          const SizedBox(height: 24),
          SectionHeader(title: l10n.preg_your_records_title, color: themeColor),
          const SizedBox(height: 12),
          ...weeklyWeights.map((w) {
            final sortedAllWeights = List<WeightEntry>.from(provider.weights)
              ..sort((a, b) => b.date.compareTo(a.date));
            final currentIndex = sortedAllWeights.indexWhere(
              (e) => e.id == w.id,
            );
            final previousWeight =
                (currentIndex != -1 &&
                    currentIndex < sortedAllWeights.length - 1)
                ? sortedAllWeights[currentIndex + 1].weightValue
                : provider.pregnancy?.initialWeight;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: WeightLogCard(
                entry: w,
                previousWeight: previousWeight,
                unitSuffix: unitSuffix,
                onLongPress: () {},
                gestationalWeek: week,
              ),
            );
          }),
          ...weeklyAppts.map((a) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppointmentLogCard(appointment: a, onLongPress: () {}),
            );
          }),
          ...weeklyKicks.map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: KickLogCard(session: s),
            );
          }),
          ...weeklyContractions.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            final prevContraction = (i + 1 < weeklyContractions.length)
                ? weeklyContractions[i + 1]
                : null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ContractionLogCard(
                contraction: c,
                prevContraction: prevContraction,
              ),
            );
          }),
        ],

        if (getLocalizedChecklist(l10n, info.week).isNotEmpty) ...[
          const SizedBox(height: 24),
          SectionHeader(
            title: l10n.preg_weekly_checklist_title,
            color: themeColor,
          ),
          const SizedBox(height: 12),
          _buildChecklistSection(info, l10n, themeColor),
        ],
      ],
    );
  }

  Widget _buildChecklistSection(
    FetusDevelopmentInfo info,
    AppLocalizations l10n,
    Color themeColor,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: getLocalizedChecklist(l10n, info.week).asMap().entries.map((
          entry,
        ) {
          final i = entry.key;
          final item = entry.value;
          return _buildChecklistItem(
            item,
            i,
            getLocalizedChecklist(l10n, info.week).length,
            themeColor,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChecklistItem(
    String item,
    int index,
    int total,
    Color themeColor,
  ) {
    final isCompleted = isPast;

    return Padding(
      padding: EdgeInsets.only(bottom: index < total - 1 ? 12 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isCompleted ? AppTheme.successColor : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isCompleted
                    ? AppTheme.successColor
                    : themeColor.withValues(
                        alpha: context.isDarkMode ? 0.5 : 0.35,
                      ),
                width: 1.5,
              ),
            ),
            child: isCompleted
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                item,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: isCompleted
                      ? context.appTextSecondary
                      : context.appTextPrimary,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsList(AppLocalizations l10n, int week, Color color) {
    final symptoms = _getWeekSymptoms(l10n, week);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: symptoms
          .map((symptom) => _buildSymptomChip(symptom, color))
          .toList(),
    );
  }

  Widget _buildSymptomChip(String symptom, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? Colors.white.withValues(alpha: 0.04)
            : color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: color.withValues(alpha: context.isDarkMode ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: Text(
        symptom,
        style: GoogleFonts.nunito(
          fontSize: 13,
          color: context.appTextPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  // ========== HELPER DATA METHODS ==========

  List<String> _getWeekMilestones(AppLocalizations l10n, int week) {
    if (week <= 4) {
      return [
        l10n.preg_milestone_4_1,
        l10n.preg_milestone_4_2,
        l10n.preg_milestone_4_3,
      ];
    } else if (week <= 8) {
      return [
        l10n.preg_milestone_8_1,
        l10n.preg_milestone_8_2,
        l10n.preg_milestone_8_3,
      ];
    } else if (week <= 12) {
      return [
        l10n.preg_milestone_12_1,
        l10n.preg_milestone_12_2,
        l10n.preg_milestone_12_3,
      ];
    } else if (week <= 16) {
      return [
        l10n.preg_milestone_16_1,
        l10n.preg_milestone_16_2,
        l10n.preg_milestone_16_3,
      ];
    } else if (week <= 20) {
      return [
        l10n.preg_milestone_20_1,
        l10n.preg_milestone_20_2,
        l10n.preg_milestone_20_3,
      ];
    } else if (week <= 24) {
      return [
        l10n.preg_milestone_24_1,
        l10n.preg_milestone_24_2,
        l10n.preg_milestone_24_3,
      ];
    } else if (week <= 28) {
      return [
        l10n.preg_milestone_28_1,
        l10n.preg_milestone_28_2,
        l10n.preg_milestone_28_3,
      ];
    } else if (week <= 32) {
      return [
        l10n.preg_milestone_32_1,
        l10n.preg_milestone_32_2,
        l10n.preg_milestone_32_3,
      ];
    } else if (week <= 36) {
      return [
        l10n.preg_milestone_36_1,
        l10n.preg_milestone_36_2,
        l10n.preg_milestone_36_3,
      ];
    } else {
      return [
        l10n.preg_milestone_40_1,
        l10n.preg_milestone_40_2,
        l10n.preg_milestone_40_3,
      ];
    }
  }

  List<String> _getWeekSymptoms(AppLocalizations l10n, int week) {
    if (week <= 8) {
      return [
        l10n.preg_symptom_8_1,
        l10n.preg_symptom_8_2,
        l10n.preg_symptom_8_3,
        l10n.preg_symptom_8_4,
      ];
    } else if (week <= 16) {
      return [
        l10n.preg_symptom_16_1,
        l10n.preg_symptom_16_2,
        l10n.preg_symptom_16_3,
        l10n.preg_symptom_16_4,
      ];
    } else if (week <= 24) {
      return [
        l10n.preg_symptom_24_1,
        l10n.preg_symptom_24_2,
        l10n.preg_symptom_24_3,
        l10n.preg_symptom_24_4,
      ];
    } else if (week <= 32) {
      return [
        l10n.preg_symptom_32_1,
        l10n.preg_symptom_32_2,
        l10n.preg_symptom_32_3,
        l10n.preg_symptom_32_4,
      ];
    } else {
      return [
        l10n.preg_symptom_40_1,
        l10n.preg_symptom_40_2,
        l10n.preg_symptom_40_3,
        l10n.preg_symptom_40_4,
      ];
    }
  }
}
