import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/platform_wrapper.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/route_constants.dart';
import '../providers/pregnancy_provider.dart';
import '../providers/labor_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'kick_counter_tab.dart';
import 'weight_tracker_tab.dart';
import 'contraction_timer_tab.dart';
import 'appointments_tab.dart';
import '../../../core/widgets/section_header.dart';

class PregnancyQuickTools extends StatelessWidget {
  const PregnancyQuickTools({super.key});

  void _openHealthSubScreen(BuildContext context, String title, Widget child) {
    final l10n = AppLocalizations.of(context)!;
    final List<String>? keywords;
    if (title == l10n.kick_counter_title) {
      keywords = const ['kick'];
    } else if (title == l10n.contraction_timer_title) {
      keywords = const ['contraction', 'timer', 'labor'];
    } else if (title == l10n.health_weight) {
      keywords = const ['weight', 'gain'];
    } else if (title == l10n.health_appointments) {
      keywords = const ['appointment', 'doctor'];
    } else {
      keywords = null;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => Container(
          decoration: BoxDecoration(gradient: context.appBackgroundGradient),
          child: PlatformScaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: Colors.transparent,
            appBar: BrandedAppBar(
              title: Text(title),
              isPregnancy: true,
              helpKeywords: keywords,
            ),
            body: SafeArea(bottom: false, child: child),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer3<PregnancyProvider, LaborProvider, AuthProvider>(
      builder: (context, pregnancyProvider, laborProvider, authProvider, _) {
        // ── Live data extraction ─────────────────────────────────────────
        final kickSessions = pregnancyProvider.kickSessions;
        final todayKicks = kickSessions
            .where((s) {
              final now = DateTime.now();
              return s.startTime.year == now.year &&
                  s.startTime.month == now.month &&
                  s.startTime.day == now.day;
            })
            .fold<int>(0, (sum, s) => sum + s.count);
        final totalKickSessions = kickSessions.length;

        final contractions = laborProvider.contractions;
        final isContractionActive = laborProvider.isActive;

        final weights = pregnancyProvider.weights;
        final currentWeight = weights.isNotEmpty
            ? weights.first.weightValue
            : pregnancyProvider.pregnancy?.initialWeight;
        final weightUnit = authProvider.userProfile?.preferences.weightUnit.name.toLowerCase() ?? 'kg';

        final upcomingAppointmentsCount = pregnancyProvider.appointments
            .where((a) => a.date.isAfter(DateTime.now()))
            .length;

        const double spacing = 12;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: l10n.health_title),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _PressableActionCard(
                      onTap: () => _openHealthSubScreen(
                        context,
                        l10n.kick_counter_title,
                        const KickCounterTab(),
                      ),
                      child: _buildTallCardContent(
                        context,
                        icon: AppTheme.kickIcon,
                        color: AppTheme.trimester1Primary,
                        title: l10n.kick_counter_title,
                        subtitle: l10n.kick_counter_subtitle,
                        statLabel: totalKickSessions > 0
                            ? (todayKicks > 0
                                ? '$todayKicks ${l10n.kick_counter_kicks}'
                                : '$totalKickSessions ${l10n.kick_counter_total_sessions}')
                            : null,
                        statIcon: Icons.touch_app_rounded,
                        isEmpty: totalKickSessions == 0,
                        emptyLabel: l10n.kick_counter_start,
                      ),
                    ),
                  ),
                  const SizedBox(width: spacing),
                  Expanded(
                    child: _PressableActionCard(
                      onTap: () => _openHealthSubScreen(
                        context,
                        l10n.contraction_timer_title,
                        const ContractionTimerTab(),
                      ),
                      child: _buildTallCardContent(
                        context,
                        icon: AppTheme.contractionIcon,
                        color: AppTheme.trimester2Primary,
                        title: l10n.contraction_timer_title,
                        subtitle: l10n.contraction_timer_subtitle,
                        statLabel: isContractionActive
                            ? l10n.common_ongoing
                            : contractions.isNotEmpty
                                ? '${contractions.length} ${l10n.contraction_timer_history}'
                                : null,
                        statIcon: isContractionActive
                            ? Icons.fiber_manual_record_rounded
                            : Icons.history_rounded,
                        statIsActive: isContractionActive,
                        isEmpty: contractions.isEmpty && !isContractionActive,
                        emptyLabel: l10n.kick_counter_start,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: spacing),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _PressableActionCard(
                      onTap: () => _openHealthSubScreen(
                        context,
                        l10n.health_weight,
                        const WeightTrackerTab(),
                      ),
                      child: _buildTallCardContent(
                        context,
                        icon: AppTheme.weightIcon,
                        color: AppTheme.trimester3Primary,
                        title: l10n.health_weight,
                        subtitle: l10n.health_weight_subtitle,
                        statLabel: currentWeight != null
                            ? '${currentWeight.toStringAsFixed(1)} $weightUnit'
                            : null,
                        statIcon: Icons.monitor_weight_outlined,
                        isEmpty: currentWeight == null,
                        emptyLabel: l10n.add_new,
                      ),
                    ),
                  ),
                  const SizedBox(width: spacing),
                  Expanded(
                    child: _PressableActionCard(
                      onTap: () => _openHealthSubScreen(
                        context,
                        l10n.health_appointments,
                        const AppointmentsTab(),
                      ),
                      child: _buildTallCardContent(
                        context,
                        icon: AppTheme.appointmentIcon,
                        color: AppTheme.primaryColor,
                        title: l10n.health_appointments,
                        subtitle: l10n.health_appt_subtitle,
                        statLabel: upcomingAppointmentsCount > 0
                            ? '$upcomingAppointmentsCount ${l10n.health_appointments}'
                            : null,
                        statIcon: Icons.calendar_today_rounded,
                        isEmpty: upcomingAppointmentsCount == 0,
                        emptyLabel: l10n.add_new,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: spacing),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _PressableActionCard(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pushNamed(context, RouteConstants.nameSwipe);
                      },
                      child: _buildTallCardContent(
                        context,
                        icon: AppTheme.nameFinderIcon,
                        color: AppTheme.fertileColor,
                        title: l10n.preg_name_finder_title,
                        subtitle: l10n.preg_name_finder_subtitle,
                        statLabel: l10n.preg_name_finder_stat_label,
                        statIcon: AppTheme.nameFinderIcon,
                        isEmpty: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTallCardContent(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    String? statLabel,
    IconData? statIcon,
    bool statIsActive = false,
    bool isEmpty = false,
    String? emptyLabel,
  }) {
    final isDark = context.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isDark ? 0.2 : 0.15),
            color.withValues(alpha: isDark ? 0.05 : 0.02),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -24,
            child: Icon(
              icon,
              size: 140,
              color: color.withValues(alpha: isDark ? 0.12 : 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.appTextPrimary,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.appTextSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                const SizedBox(height: 12),
                if (statLabel != null && !isEmpty)
                  _buildStatChip(
                    context,
                    label: statLabel,
                    icon: statIcon,
                    color: color,
                    isActive: statIsActive,
                  )
                else if (isEmpty && emptyLabel != null)
                  _buildEmptyChip(context, label: emptyLabel, color: color)
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required String label,
    IconData? icon,
    required Color color,
    bool isActive = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isActive ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: isActive ? 0.4 : 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 11,
              color: isActive ? color : color.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive ? color : color.withValues(alpha: 0.85),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChip(
    BuildContext context, {
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: context.appBorderColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.appBorderColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_rounded,
            size: 11,
            color: color.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.appTextSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PressableActionCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _PressableActionCard({required this.onTap, required this.child});

  @override
  State<_PressableActionCard> createState() => _PressableActionCardState();
}

class _PressableActionCardState extends State<_PressableActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.965 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: GlassCard(padding: EdgeInsets.zero, child: widget.child),
      ),
    );
  }
}
