import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/platform_wrapper.dart';
import '../providers/pregnancy_provider.dart';
import '../../../l10n/app_localizations.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';
import '../models/kick_session_model.dart';
import '../screens/kick_counter_session_screen.dart';
import 'action_link.dart';
import '../../../core/widgets/section_header.dart';
import 'kick_log_card.dart';
import '../../../core/widgets/ambient_bottom_scrim.dart';

class KickCounterTab extends StatelessWidget {
  const KickCounterTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<PregnancyProvider>(
      builder: (context, provider, child) {
        final sessions = provider.kickSessions;

        if (sessions.isEmpty) {
          return Column(
            children: [
              const SizedBox(height: 64),
              Expanded(
                child: EmptyStateWidget(
                  icon: AppTheme.kickIcon,
                  title: l10n.kick_counter_title,
                  message: l10n.kick_counter_empty,
                  color: AppTheme.trimester1Primary,
                  action: ElevatedButton.icon(
                    onPressed: () => _startSession(context),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.kick_counter_start),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.trimester1Primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
                  _buildOverviewCard(context, sessions, l10n),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SectionHeader(
                        title: l10n.kick_counter_history,
                        color: AppTheme.trimester1Primary,
                      ),
                      ActionLink(
                        onTap: () => _startSession(context),
                        icon: Icons.add_rounded,
                        label: l10n.kick_counter_start,
                        color: AppTheme.trimester1Primary,
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
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      return _buildSessionCard(context, sessions[index], l10n);
                    },
                  ),
                  const AmbientBottomScrim(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    List<KickSession> sessions,
    AppLocalizations l10n,
  ) {
    final avgMinutes = sessions.isEmpty
        ? 0
        : (sessions.map((s) => s.duration.inMinutes).reduce((a, b) => a + b) /
                  sessions.length)
              .round();

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      borderRadius: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCompactStat(
            context,
            icon: Icons.format_list_numbered_rounded,
            label: l10n.kick_counter_total_sessions,
            value: '${sessions.length}',
            color: AppTheme.trimester1Primary,
          ),
          Container(width: 1, height: 36, color: context.appDividerColor),
          _buildCompactStat(
            context,
            icon: Icons.timer_outlined,
            label: l10n.kick_counter_avg_time,
            value: '${avgMinutes}m',
            color: AppTheme.trimester2Primary,
          ),
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

  Widget _buildSessionCard(
    BuildContext context,
    KickSession session,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: KickLogCard(
        session: session,
        onDelete: () async {
          try {
            await context.read<PregnancyProvider>().deleteKickSession(
              session.id!,
            );
            if (context.mounted) {
              PlatformUI.showMessage(
                context,
                message: l10n.kick_counter_delete_success,
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
      ),
    );
  }

  void _startSession(BuildContext context) {
    context.read<PregnancyProvider>().startKickSession();
    PlatformUI.pushPage<void>(context, const KickCounterSessionScreen());
  }
}
