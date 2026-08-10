import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/platform_wrapper.dart';
import '../providers/pregnancy_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/appointment_log_card.dart';
import 'action_link.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/ambient_bottom_scrim.dart';

class AppointmentsTab extends StatelessWidget {
  const AppointmentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<PregnancyProvider>(
      builder: (context, provider, _) {
        final appointments = provider.appointments.toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        if (appointments.isEmpty) {
          return EmptyStateWidget(
            icon: AppTheme.appointmentIcon,
            title: l10n.health_appointments,
            message: l10n.health_empty_appts,
            color: AppTheme.primaryColor,
            action: ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.health_appt_add),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
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
                  Navigator.pushNamed(context, RouteConstants.addAppointment),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SectionHeader(
                        title: l10n.health_appointments,
                        color: AppTheme.primaryColor,
                      ),
                      ActionLink(
                        icon: Icons.add_rounded,
                        label: l10n.health_appt_add,
                        color: AppTheme.primaryColor,
                        onTap: () => Navigator.pushNamed(
                          context,
                          RouteConstants.addAppointment,
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
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appt = appointments[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Dismissible(
                        key: ValueKey(appt.id),
                        direction: DismissDirection.endToStart,
                        background: _buildSwipeBackground(context, l10n),
                        confirmDismiss: (_) async {
                          bool confirmed = false;
                          await PlatformUI.showDeleteDialog(
                            context,
                            itemType: l10n.common_item_appointment,
                            onDelete: () => confirmed = true,
                          );
                          return confirmed;
                        },
                        onDismissed: (_) => _deleteAppt(context, appt.id, l10n),
                        child: AppointmentLogCard(
                          appointment: appt,
                          onLongPress: () => _confirmDelete(context, appt.id),
                        ),
                      ),
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
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    final l10n = AppLocalizations.of(context)!;
    PlatformUI.showDeleteDialog(
      context,
      itemType: l10n.common_item_appointment,
      onDelete: () async {
        try {
          await context.read<PregnancyProvider>().deleteAppointment(id);
          if (context.mounted) {
            PlatformUI.showMessage(
              context,
              message: l10n.health_appt_delete_success,
            );
          }
        } catch (e) {
          if (context.mounted) {
            PlatformUI.showMessage(
              context,
              message: l10n.common_error_deleting(e.toString()),
              isError: true,
            );
          }
        }
      },
    );
  }

  Widget _buildSwipeBackground(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
                ? CupertinoIcons.delete_solid
                : Icons.delete_forever_rounded,
            color: AppTheme.errorColor,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            l10n.common_delete,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAppt(
    BuildContext context,
    String id,
    AppLocalizations l10n,
  ) async {
    try {
      await context.read<PregnancyProvider>().deleteAppointment(id);
      if (context.mounted) {
        PlatformUI.showMessage(
          context,
          message: l10n.health_appt_delete_success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        PlatformUI.showMessage(
          context,
          message: l10n.common_error_deleting(e.toString()),
          isError: true,
        );
      }
    }
  }
}
