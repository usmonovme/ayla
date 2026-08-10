import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/platform_wrapper.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/premium_guard.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/constants/route_constants.dart';
import '../providers/pregnancy_provider.dart';
import '../providers/labor_provider.dart';
import '../models/contraction_model.dart';
import '../../../l10n/app_localizations.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';
import 'action_link.dart';
import '../../../core/widgets/section_header.dart';
import 'contraction_log_card.dart';
import '../../../core/widgets/ambient_bottom_scrim.dart';

class ContractionTimerTab extends StatelessWidget {
  const ContractionTimerTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pregnancyProvider = context.watch<PregnancyProvider>();
    final pregnancy = pregnancyProvider.pregnancy;

    if (pregnancy == null) return const SizedBox.shrink();

    return PremiumGuard(
      featureName: 'contraction_timer',
      message: l10n.contraction_timer_subtitle,
      child: Consumer<LaborProvider>(
        builder: (context, provider, child) {
          if (provider.contractions.isEmpty && !provider.isActive) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: EmptyStateWidget(
                icon: AppTheme.contractionIcon,
                title: l10n.contraction_timer_title,
                message: l10n.kick_counter_instruction,
                color: AppTheme.trimester2Primary,
                action: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.kick_counter_start),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.trimester2Primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () =>
                      _startTimer(context, pregnancy.userId, pregnancy.id),
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildOverviewCard(context, provider, l10n),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SectionHeader(
                          title: l10n.contraction_timer_history,
                          color: AppTheme.trimester2Primary,
                        ),
                        ActionLink(
                          icon: Icons.add_rounded,
                          label: l10n.kick_counter_start,
                          color: AppTheme.trimester2Primary,
                          onTap: () => _startTimer(
                            context,
                            pregnancy.userId,
                            pregnancy.id,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    ListView.builder(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.paddingOf(context).bottom + 60.0),
                  itemCount: provider.contractions.length,
                  itemBuilder: (context, index) {
                    final current = provider.contractions[index];
                    final prevContraction =
                        (index + 1 < provider.contractions.length)
                        ? provider.contractions[index + 1]
                        : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildContractionCard(
                        context,
                        current,
                        l10n,
                        prevContraction: prevContraction,
                      ),
                    );
                    },
                  ),
                  const AmbientBottomScrim(),
                ],
              ),
            ),
          ],
        );
        },
      ),
    );
  }

  void _startTimer(BuildContext context, String userId, String pregnancyId) {
    context.read<LaborProvider>().initialize(userId, pregnancyId);
    Navigator.pushNamed(context, RouteConstants.contractionTimer);
  }

  Widget _buildOverviewCard(
    BuildContext context,
    LaborProvider provider,
    AppLocalizations l10n,
  ) {
    final meetsRule = provider.meets511Rule;
    final accentColor = meetsRule ? Colors.orange : AppTheme.trimester2Primary;
    final contractions = provider.contractions;

    // Compute stats from available data
    final completedContractions = contractions
        .where((c) => c.endTime != null)
        .toList();

    Duration? avgDuration;
    if (completedContractions.isNotEmpty) {
      final totalSecs = completedContractions
          .map((c) => c.duration.inSeconds)
          .reduce((a, b) => a + b);
      avgDuration = Duration(
        seconds: (totalSecs / completedContractions.length).round(),
      );
    }

    Duration? avgInterval;
    if (contractions.length >= 2) {
      int totalIntervalSecs = 0;
      int count = 0;
      for (int i = 0; i < contractions.length - 1; i++) {
        final diff = contractions[i].startTime.difference(
          contractions[i + 1].startTime,
        );

        if (diff.abs() > AppConstants.contractionSessionThreshold) {
          break;
        }

        totalIntervalSecs += diff.inSeconds.abs();
        count++;
      }
      if (count > 0) {
        avgInterval = Duration(seconds: (totalIntervalSecs / count).round());
      }
    }

    String fmtDuration(Duration d) {
      final m = d.inMinutes;
      final s = d.inSeconds % 60;
      if (m > 0 && s > 0) return '${m}m ${s}s';
      if (m > 0) return '${m}m';
      return '${s}s';
    }

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      borderRadius: 20,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCompactStat(
                context,
                icon: Icons.format_list_numbered_rounded,
                label: l10n.contraction_timer_count,
                value: '${contractions.length}',
                color: accentColor,
              ),
              if (avgInterval != null) ...[
                Container(width: 1, height: 36, color: context.appDividerColor),
                _buildCompactStat(
                  context,
                  icon: Icons.timer_outlined,
                  label: l10n.contraction_timer_frequency,
                  value: fmtDuration(avgInterval),
                  color: AppTheme.primaryColor,
                ),
              ],
              if (avgDuration != null) ...[
                Container(width: 1, height: 36, color: context.appDividerColor),
                _buildCompactStat(
                  context,
                  icon: Icons.hourglass_bottom_rounded,
                  label: l10n.contraction_timer_duration,
                  value: fmtDuration(avgDuration),
                  color: AppTheme.trimester3Primary,
                ),
              ],
            ],
          ),
          if (meetsRule) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n.contraction_timer_contact_doctor,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: context.appTextPrimary,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.appTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildContractionCard(
    BuildContext context,
    ContractionEntry contraction,
    AppLocalizations l10n, {
    ContractionEntry? prevContraction,
  }) {
    return ContractionLogCard(
      contraction: contraction,
      prevContraction: prevContraction,
      onDelete: () async {
        try {
          await context.read<LaborProvider>().deleteContraction(
            contraction.id!,
          );
          if (context.mounted) {
            PlatformUI.showMessage(
              context,
              message: l10n.contraction_delete_success,
            );
          }
        } catch (e) {
          if (context.mounted) {
            PlatformUI.showMessage(
              context,
              message: l10n.common_error,
              isError: true,
            );
          }
        }
      },
    );
  }
}
