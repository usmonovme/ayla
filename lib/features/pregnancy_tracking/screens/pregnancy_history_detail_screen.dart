import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/platform_wrapper.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/pregnancy_model.dart';
import '../models/weight_entry_model.dart';
import '../models/kick_session_model.dart';
import '../models/contraction_model.dart';
import '../services/weight_gain_calculator.dart';
import '../widgets/kick_log_card.dart';
import '../widgets/contraction_log_card.dart';
import '../widgets/weight_log_card.dart';
import '../widgets/pregnancy_weight_dashboard_card.dart';
import '../../../core/data/repositories/weight_repository.dart';
import '../../../core/data/repositories/kick_repository.dart';
import '../../../core/data/repositories/contraction_repository.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';
import '../providers/pregnancy_provider.dart';
import '../utils/pregnancy_report_generator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/widgets/ambient_bottom_scrim.dart';

class PregnancyHistoryDetailScreen extends StatefulWidget {
  final Pregnancy pregnancy;
  const PregnancyHistoryDetailScreen({super.key, required this.pregnancy});

  @override
  State<PregnancyHistoryDetailScreen> createState() =>
      _PregnancyHistoryDetailScreenState();
}

class _PregnancyHistoryDetailScreenState
    extends State<PregnancyHistoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<WeightEntry> _weights = [];
  List<KickSession> _kicks = [];
  List<ContractionEntry> _contractions = [];
  bool _isLoading = true;
  bool _isExportingPdf = false;

  // Signature AppTheme Feature Colors
  static const Color _kickFeatureColor = AppTheme.trimester1Primary;
  static const Color _contractionFeatureColor = AppTheme.trimester2Primary;
  static const Color _weightFeatureColor = AppTheme.trimester3Primary;
  static const Color _primaryAccent = AppTheme.primaryColor;

  // Defined AppTheme intensity & status colors
  static const Color _intensityMild = AppTheme.successColor;
  static const Color _intensityModerate = AppTheme.trimester2Primary;
  static const Color _intensityStrong = AppTheme.errorColor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final weightRepo = context.read<WeightRepository>();
      final kickRepo = context.read<KickRepository>();
      final contractionRepo = context.read<ContractionRepository>();

      final results = await Future.wait([
        weightRepo.getWeightEntries(widget.pregnancy.id),
        kickRepo.getKickSessions(widget.pregnancy.id),
        contractionRepo.getContractions(widget.pregnancy.id),
      ]);

      if (mounted) {
        setState(() {
          _weights = results[0] as List<WeightEntry>;
          _kicks = results[1] as List<KickSession>;
          _contractions = results[2] as List<ContractionEntry>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        PlatformUI.showMessage(context, message: e.toString(), isError: true);
      }
    }
  }

  Future<void> _exportPdf() async {
    if (_isExportingPdf) return;
    HapticFeedback.mediumImpact();
    setState(() => _isExportingPdf = true);

    try {
      await PregnancyReportGenerator.generateAndShare(
        context,
        pregnancy: widget.pregnancy,
        weights: _weights,
        kicks: _kicks,
        contractions: _contractions,
      );
    } catch (e) {
      if (mounted) {
        PlatformUI.showMessage(
          context,
          message: 'PDF export failed: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingPdf = false);
      }
    }
  }

  void _onDelete() {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.heavyImpact();
    PlatformUI.showDeleteDialog(
      context,
      itemType: l10n.preg_history_title,
      onDelete: () async {
        try {
          await context.read<PregnancyProvider>().deletePregnancyHistory(
            widget.pregnancy.id,
            widget.pregnancy.userId,
          );
          if (mounted) {
            Navigator.pop(context);
            PlatformUI.showMessage(context, message: l10n.common_success);
          }
        } catch (e) {
          if (mounted) {
            PlatformUI.showMessage(
              context,
              message: e.toString(),
              isError: true,
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = widget.pregnancy;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: BrandedAppBar(
        isPregnancy: true,
        title: Text(p.babyName ?? l10n.preg_baby_default_name),
        actions: [
          IconButton(
            icon: _isExportingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.white,
                  ),
            tooltip: 'Download Keepsake PDF',
            onPressed: _isExportingPdf ? null : _exportPdf,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
            ),
            tooltip: l10n.common_delete,
            onPressed: _onDelete,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.appBackgroundGradient),
        child: SafeArea(
          bottom: false,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Modern Tab Bar at top
                    ModernTabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabs: [
                        l10n.insights_tab_overview,
                        l10n.kick_counter_kicks,
                        l10n.contraction_timer_history,
                        l10n.health_weight,
                      ],
                    ),

                    // Tab Views
                    Expanded(
                      child: Stack(
                        children: [
                          TabBarView(
                            controller: _tabController,
                            children: [
                              _buildOverviewTab(),
                              _buildKicksTab(),
                              _buildLaborTab(),
                              _buildWeightTab(),
                            ],
                          ),
                          const AmbientBottomScrim(),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: OVERVIEW & KEEPSAKE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.paddingOf(context).bottom + 60.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Keepsake Banner
          _buildHeroCard(),
          const SizedBox(height: 14),

          // Key Journey Timeline (LMP -> EDD -> Arrival)
          _buildJourneyTimelineCard(),
          const SizedBox(height: 14),

          // Journey Highlights Bento Grid (2+1 layout)
          _buildJourneyMilestonesBento(),
          const SizedBox(height: 14),

          // Birth Details & Delivery Notes (if recorded)
          _buildBirthDetails(),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    final p = widget.pregnancy;
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;

    final birthDateStr = p.birthDate != null
        ? DateFormat.yMMMMd(l10n.localeName).format(p.birthDate!)
        : DateFormat.yMMMMd(l10n.localeName).format(p.updatedAt);

    final isBoy =
        p.babyGender?.toLowerCase() == 'boy' ||
        p.babyGender?.toLowerCase() ==
            l10n.preg_history_gender_boy.toLowerCase();
    final isGirl =
        p.babyGender?.toLowerCase() == 'girl' ||
        p.babyGender?.toLowerCase() ==
            l10n.preg_history_gender_girl.toLowerCase();

    final Color genderAccent = isBoy
        ? AppTheme.primaryColor
        : (isGirl ? AppTheme.trimester1Primary : _primaryAccent);

    final IconData genderIcon = isBoy
        ? Icons.male_rounded
        : (isGirl ? Icons.female_rounded : Icons.child_care_rounded);

    final String genderLabel = isBoy
        ? l10n.preg_gender_boy
        : (isGirl ? l10n.preg_gender_girl : (p.babyGender ?? ''));

    final end = p.birthDate ?? p.updatedAt;
    final totalDays = end.difference(p.lastPeriodDate).inDays;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  genderAccent.withValues(alpha: isDark ? 0.35 : 0.2),
                  genderAccent.withValues(alpha: isDark ? 0.1 : 0.05),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: genderAccent.withValues(alpha: isDark ? 0.4 : 0.28),
                width: 1.5,
              ),
            ),
            child: Icon(genderIcon, color: genderAccent, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.babyName ?? l10n.preg_baby_default_name,
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: context.appTextPrimary,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      p.birthDate != null
                          ? Icons.cake_rounded
                          : Icons.calendar_today_rounded,
                      size: 13,
                      color: genderAccent,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        birthDateStr,
                        style: GoogleFonts.nunito(
                          fontSize: 12.5,
                          color: context.appTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (genderLabel.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: genderAccent.withValues(
                            alpha: isDark ? 0.18 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          genderLabel,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: genderAccent,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryAccent.withValues(
                          alpha: isDark ? 0.18 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p.getDuration(
                          l10n.unit_weeks_short,
                          l10n.unit_days_short,
                        ),
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _primaryAccent,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: _contractionFeatureColor.withValues(
                          alpha: isDark ? 0.18 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 11,
                            color: _contractionFeatureColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$totalDays ${l10n.insights_unit_days}',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _contractionFeatureColor,
                            ),
                          ),
                        ],
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

  Widget _buildJourneyTimelineCard() {
    final p = widget.pregnancy;
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;

    final lmpStr = DateFormat.MMMd(l10n.localeName).format(p.lastPeriodDate);
    final eddStr = DateFormat.MMMd(l10n.localeName).format(p.estimatedDueDate);
    final arrivalDate = p.birthDate ?? p.updatedAt;
    final arrivalStr = DateFormat.MMMd(l10n.localeName).format(arrivalDate);

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline_rounded,
                size: 15,
                color: context.appTextSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Journey Timeline',
                style: GoogleFonts.nunito(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: context.appTextSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // 1. LMP Start Node
              Expanded(
                child: _buildTimelineNode(
                  title: 'LMP (Start)',
                  date: lmpStr,
                  icon: Icons.play_arrow_rounded,
                  color: _primaryAccent,
                  isDark: isDark,
                ),
              ),

              // Divider 1
              _buildTimelineConnector(isDark),

              // 2. EDD Estimated Due Date Node
              Expanded(
                child: _buildTimelineNode(
                  title: 'Due Date',
                  date: eddStr,
                  icon: Icons.event_available_rounded,
                  color: _contractionFeatureColor,
                  isDark: isDark,
                ),
              ),

              // Divider 2
              _buildTimelineConnector(isDark),

              // 3. Arrival / Birth Node
              Expanded(
                child: _buildTimelineNode(
                  title: p.birthDate != null ? 'Arrival' : 'Completed',
                  date: arrivalStr,
                  icon: p.birthDate != null
                      ? Icons.cake_rounded
                      : Icons.check_circle_outline_rounded,
                  color: _kickFeatureColor,
                  isDark: isDark,
                  isHighlight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineConnector(bool isDark) {
    return Container(
      width: 18,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: context.appDividerColor.withValues(alpha: isDark ? 0.4 : 0.6),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildTimelineNode({
    required String title,
    required String date,
    required IconData icon,
    required Color color,
    required bool isDark,
    bool isHighlight = false,
  }) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isHighlight
                ? color
                : color.withValues(alpha: isDark ? 0.18 : 0.12),
            border: isHighlight
                ? null
                : Border.all(
                    color: color.withValues(alpha: isDark ? 0.35 : 0.25),
                    width: 1.2,
                  ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 16,
              color: isHighlight ? Colors.white : color,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: context.appTextSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        Text(
          date,
          style: GoogleFonts.nunito(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: context.appTextPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildJourneyMilestonesBento() {
    final l10n = AppLocalizations.of(context)!;
    final p = widget.pregnancy;

    // Kicks Summary
    final totalKicks = _kicks.fold<int>(0, (sum, s) => sum + s.count);

    // Contractions Summary
    final totalContractions = _contractions.length;
    final avgSecs = _contractions.isNotEmpty
        ? (_contractions.fold<int>(0, (sum, c) => sum + c.duration.inSeconds) /
                _contractions.length)
            .round()
        : 0;

    // Weight Summary
    final startWeight = p.initialWeight;
    final latestWeight = _weights.isNotEmpty
        ? _weights.first.weightValue
        : startWeight;
    final totalGain = (latestWeight != null && startWeight != null)
        ? latestWeight - startWeight
        : 0.0;

    return Column(
      children: [
        // Top 2 cards: Little Kicks + Labor Contractions
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                title: l10n.kick_counter_kicks,
                mainValue: '$totalKicks',
                subValue: '${_kicks.length} ${l10n.kick_counter_total_sessions}',
                icon: AppTheme.kickIcon,
                color: _kickFeatureColor,
                onTap: () => _tabController.animateTo(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoCard(
                title: l10n.contraction_timer_title,
                mainValue: '$totalContractions',
                subValue: avgSecs > 0 ? '${avgSecs}s avg duration' : '--',
                icon: AppTheme.contractionIcon,
                color: _contractionFeatureColor,
                onTap: () => _tabController.animateTo(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Bottom full-width card: Mom's Weight Progress
        _buildWeightBentoCard(
          title: l10n.health_weight,
          gainText:
              '${totalGain > 0 ? '+' : ''}${totalGain.toStringAsFixed(1)} ${l10n.unit_kg}',
          startWeight: startWeight,
          latestWeight: latestWeight,
          logsCount: _weights.length,
          unitSuffix: l10n.unit_kg,
          onTap: () => _tabController.animateTo(3),
        ),
      ],
    );
  }

  Widget _buildBentoCard({
    required String title,
    required String mainValue,
    required String subValue,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.22 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: context.appTextSecondary.withValues(alpha: 0.6),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              mainValue,
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: context.appTextPrimary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subValue,
              style: GoogleFonts.nunito(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: context.appTextSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightBentoCard({
    required String title,
    required String gainText,
    required double? startWeight,
    required double? latestWeight,
    required int logsCount,
    required String unitSuffix,
    VoidCallback? onTap,
  }) {
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 22,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _weightFeatureColor.withValues(
                  alpha: isDark ? 0.22 : 0.12,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppTheme.weightIcon,
                size: 22,
                color: _weightFeatureColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _weightFeatureColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        gainText,
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: context.appTextPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _weightFeatureColor.withValues(
                            alpha: isDark ? 0.18 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$logsCount logs',
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _weightFeatureColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${startWeight?.toStringAsFixed(1) ?? '--'} $unitSuffix → ${latestWeight?.toStringAsFixed(1) ?? '--'} $unitSuffix',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: context.appTextSecondary.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBirthDetails() {
    final p = widget.pregnancy;
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;

    final hasStats = p.birthWeight != null || p.birthLength != null;
    final hasNotes =
        p.deliveryNotes != null && p.deliveryNotes!.trim().isNotEmpty;

    if (!hasStats && !hasNotes) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        borderRadius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _primaryAccent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.crib_rounded,
                    size: 16,
                    color: _primaryAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.preg_history_birth_details,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: context.appTextPrimary,
                  ),
                ),
              ],
            ),
            if (hasStats) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (p.birthWeight != null)
                    _buildMetricStat(
                      label: l10n.preg_weight,
                      value: '${p.birthWeight} ${l10n.unit_kg}',
                      icon: AppTheme.weightIcon,
                      color: _weightFeatureColor,
                    ),
                  if (p.birthWeight != null && p.birthLength != null)
                    Container(
                      height: 32,
                      width: 1,
                      color: context.appDividerColor,
                    ),
                  if (p.birthLength != null)
                    _buildMetricStat(
                      label: l10n.preg_length,
                      value: '${p.birthLength} ${l10n.unit_cm}',
                      icon: Icons.straighten_rounded,
                      color: _primaryAccent,
                    ),
                ],
              ),
            ],
            if (hasNotes) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (isDark ? AppTheme.darkSurfaceColor : Colors.white)
                      .withValues(alpha: isDark ? 0.35 : 0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.appGlassBorderColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      size: 18,
                      color: _contractionFeatureColor.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.deliveryNotes!,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: context.appTextSecondary,
                          height: 1.45,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              value,
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: context.appTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.nunito(
            fontSize: 10,
            color: context.appTextSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: LITTLE KICKS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildKicksTab() {
    final l10n = AppLocalizations.of(context)!;

    // Calculate peak time of day for kicks
    int morningKicks = 0;
    int afternoonKicks = 0;
    int eveningKicks = 0;
    for (final k in _kicks) {
      final hour = k.startTime.hour;
      if (hour >= 5 && hour < 12) {
        morningKicks += k.count;
      } else if (hour >= 12 && hour < 18) {
        afternoonKicks += k.count;
      } else {
        eveningKicks += k.count;
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.paddingOf(context).bottom + 60.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time-of-Day Rhythm Card (if kicks recorded)
          if (_kicks.isNotEmpty) ...[
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kick Activity Rhythm',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: context.appTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTimeRhythmBadge(
                        label: 'Morning',
                        icon: Icons.wb_sunny_outlined,
                        count: morningKicks,
                        color: _intensityModerate,
                      ),
                      Container(
                        height: 26,
                        width: 1,
                        color: context.appDividerColor,
                      ),
                      _buildTimeRhythmBadge(
                        label: 'Afternoon',
                        icon: Icons.wb_sunny_rounded,
                        count: afternoonKicks,
                        color: _kickFeatureColor,
                      ),
                      Container(
                        height: 26,
                        width: 1,
                        color: context.appDividerColor,
                      ),
                      _buildTimeRhythmBadge(
                        label: 'Evening',
                        icon: Icons.nightlight_round,
                        count: eveningKicks,
                        color: _primaryAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Detailed Kick Sessions List Header with Total Count
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _kickFeatureColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppTheme.kickIcon,
                  size: 15,
                  color: _kickFeatureColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${l10n.kick_counter_history} (${_kicks.length})',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.appTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_kicks.isEmpty)
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 24),
              borderRadius: 18,
              child: _buildEmptySection(l10n.kick_counter_empty),
            )
          else
            ..._kicks.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: KickLogCard(session: s),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeRhythmBadge({
    required String label,
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count kicks',
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: context.appTextPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: context.appTextSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3: LABOR & CONTRACTIONS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLaborTab() {
    final l10n = AppLocalizations.of(context)!;
    final total = _contractions.length;

    int mild = 0;
    int moderate = 0;
    int strong = 0;
    for (final c in _contractions) {
      if (c.intensity == ContractionIntensity.mild) mild++;
      if (c.intensity == ContractionIntensity.moderate) moderate++;
      if (c.intensity == ContractionIntensity.strong) strong++;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.paddingOf(context).bottom + 60.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intensity Breakdown
          if (total > 0) ...[
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Intensity Breakdown',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: context.appTextPrimary,
                        ),
                      ),
                      Text(
                        '$total recorded',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          if (mild > 0)
                            Expanded(
                              flex: mild,
                              child: Container(color: _intensityMild),
                            ),
                          if (moderate > 0)
                            Expanded(
                              flex: moderate,
                              child: Container(color: _intensityModerate),
                            ),
                          if (strong > 0)
                            Expanded(
                              flex: strong,
                              child: Container(color: _intensityStrong),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIntensityLegend('Mild', mild, _intensityMild),
                      _buildIntensityLegend('Moderate', moderate, _intensityModerate),
                      _buildIntensityLegend('Strong', strong, _intensityStrong),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Detailed Contractions Timeline List Header with Total Count
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _contractionFeatureColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppTheme.contractionIcon,
                  size: 15,
                  color: _contractionFeatureColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${l10n.contraction_timer_history} (${_contractions.length})',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.appTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_contractions.isEmpty)
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 24),
              borderRadius: 18,
              child: _buildEmptySection(l10n.contraction_timer_empty),
            )
          else
            ...List.generate(_contractions.length, (i) {
              final c = _contractions[i];
              final prev = i + 1 < _contractions.length ? _contractions[i + 1] : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ContractionLogCard(
                  contraction: c,
                  prevContraction: prev,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildIntensityLegend(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: $count',
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: context.appTextSecondary,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 4: MOM'S WEIGHT PROGRESS (Using existing PregnancyWeightDashboardCard)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWeightTab() {
    final l10n = AppLocalizations.of(context)!;
    final authPrefs = context.watch<AuthProvider>().userProfile?.preferences;
    final unitSuffix =
        (authPrefs?.weightUnit ?? WeightUnit.kg).name.toLowerCase();
    final p = widget.pregnancy;

    if (_weights.isEmpty && p.initialWeight == null) {
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.paddingOf(context).bottom + 60.0),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 24),
          borderRadius: 18,
          child: _buildEmptySection(l10n.preg_history_no_weight_data),
        ),
      );
    }

    final currentWeight = _weights.isNotEmpty
        ? _weights.first.weightValue
        : (p.initialWeight ?? 0.0);
    final initialWeight = p.initialWeight;
    final totalGain = initialWeight != null
        ? currentWeight - initialWeight
        : null;

    String? status;
    List<double>? gainRange;
    double? bmi;
    final end = p.birthDate ?? p.updatedAt;
    final gestationalDays = end.difference(p.lastPeriodDate).inDays;

    if (totalGain != null && authPrefs != null) {
      gainRange = WeightGainCalculator.getRecommendedWeightGainRange(
        gestationalDays: gestationalDays,
        initialWeight: initialWeight,
        height: p.height,
        preferences: authPrefs,
      );
      status = WeightGainCalculator.getStatusLabel(totalGain, gainRange);
      bmi = WeightGainCalculator.calculateBMI(
        initialWeight: initialWeight,
        height: p.height,
        preferences: authPrefs,
      );
    }

    double? weeklyRate;
    if (_weights.length >= 2) {
      final diff = _weights[0].weightValue - _weights[1].weightValue;
      final days = _weights[0].date.difference(_weights[1].date).inDays;
      if (days > 0) weeklyRate = (diff / days) * 7;
    }

    List<FlSpot> chartSpots = [];
    List<FlSpot> chartMinBand = [];
    List<FlSpot> chartMaxBand = [];
    double chartMinX = 0, chartMaxX = 0, chartMinY = 0, chartMaxY = 0;

    if (_weights.length >= 2 || (_weights.isNotEmpty && initialWeight != null)) {
      final Map<int, List<double>> byDay = {};
      if (initialWeight != null) byDay[0] = [initialWeight];
      for (final w in _weights) {
        final day = w.date.difference(p.lastPeriodDate).inDays;
        byDay.putIfAbsent(day, () => []).add(w.weightValue);
      }
      final sortedDays = byDay.keys.toList()..sort();
      for (final day in sortedDays) {
        final ws = byDay[day]!;
        chartSpots.add(
          FlSpot(day.toDouble(), ws.reduce((a, b) => a + b) / ws.length),
        );
      }

      if (chartSpots.length >= 2) {
        chartMinX = (chartSpots.first.x / 7).floor() * 7.0;
        chartMaxX = (chartSpots.last.x / 7).ceil() * 7.0;
        if (chartMaxX - chartMinX < 14) chartMaxX = chartMinX + 14;
      }

      if (chartSpots.length >= 2 &&
          authPrefs != null &&
          initialWeight != null &&
          p.height != null) {
        for (int day = 0; day <= chartMaxX.toInt(); day += 7) {
          final gr = WeightGainCalculator.getRecommendedWeightGainRange(
            gestationalDays: day,
            initialWeight: initialWeight,
            height: p.height,
            preferences: authPrefs,
          );
          chartMinBand.add(FlSpot(day.toDouble(), initialWeight + gr[0]));
          chartMaxBand.add(FlSpot(day.toDouble(), initialWeight + gr[1]));
        }
      }

      if (chartSpots.length >= 2) {
        chartMinY = chartSpots.map((e) => e.y).reduce(min);
        chartMaxY = chartSpots.map((e) => e.y).reduce(max);
        if (chartMinBand.isNotEmpty) {
          chartMinY = min(
            chartMinY,
            chartMinBand.map((e) => e.y).reduce(min),
          );
          chartMaxY = max(
            chartMaxY,
            chartMaxBand.map((e) => e.y).reduce(max),
          );
        }
        final buf = max((chartMaxY - chartMinY) * 0.15, 1.5);
        chartMinY -= buf;
        chartMaxY += buf;
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.paddingOf(context).bottom + 60.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Existing standardized PregnancyWeightDashboardCard
          PregnancyWeightDashboardCard(
            currentWeight: currentWeight,
            totalGain: totalGain,
            status: status,
            gainRange: gainRange,
            weeklyRate: weeklyRate,
            unitSuffix: unitSuffix,
            bmi: bmi,
            isCompact: false,
            chartSpots: chartSpots.length >= 2 ? chartSpots : null,
            chartMinBand: chartMinBand.isNotEmpty ? chartMinBand : null,
            chartMaxBand: chartMaxBand.isNotEmpty ? chartMaxBand : null,
            chartMinX: chartMinX,
            chartMaxX: chartMaxX,
            chartMinY: chartMinY,
            chartMaxY: chartMaxY,
          ),
          const SizedBox(height: 16),

          // Detailed Weight Logs Header with Total Count
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _weightFeatureColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppTheme.weightIcon,
                  size: 15,
                  color: _weightFeatureColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${l10n.health_weight} (${_weights.length})',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.appTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_weights.isEmpty)
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 24),
              borderRadius: 18,
              child: _buildEmptySection(l10n.preg_history_no_weight_data),
            )
          else
            ...List.generate(_weights.length, (i) {
              final w = _weights[i];
              final prevWeight = i + 1 < _weights.length
                  ? _weights[i + 1].weightValue
                  : widget.pregnancy.initialWeight;
              final days =
                  w.date.difference(widget.pregnancy.lastPeriodDate).inDays;
              final week = (days / 7).floor() + 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: WeightLogCard(
                  entry: w,
                  previousWeight: prevWeight,
                  unitSuffix: unitSuffix,
                  gestationalWeek: week,
                  onLongPress: () {},
                ),
              );
            }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REUSABLE HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildEmptySection(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 13,
            color: context.appTextSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
