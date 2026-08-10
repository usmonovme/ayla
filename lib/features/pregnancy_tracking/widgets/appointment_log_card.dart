import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/appointment_model.dart';
import '../../../l10n/app_localizations.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';

class AppointmentLogCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onLongPress;

  const AppointmentLogCard({
    super.key,
    required this.appointment,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final isUpcoming = appointment.date.isAfter(now);
    final isToday =
        appointment.date.year == now.year &&
        appointment.date.month == now.month &&
        appointment.date.day == now.day;

    final accentColor = isUpcoming
        ? AppTheme.primaryColor
        : context.appTextSecondary;

    final dateStr = DateFormat.yMMMd(l10n.localeName).format(appointment.date);
    final timeStr = DateFormat.jm(l10n.localeName).format(appointment.date);

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      borderRadius: 24,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Circular icon badge
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withValues(alpha: 0.08),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          AppTheme.appointmentIcon,
                          color: accentColor,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Info column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title row + status chip
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  appointment.title,
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isUpcoming
                                        ? context.appTextPrimary
                                        : context.appTextSecondary,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isUpcoming) ...[
                                const SizedBox(width: 8),
                                _buildStatusChip(
                                  isToday
                                      ? l10n.health_appt_today
                                      : l10n.health_appt_upcoming,
                                  isToday,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 5),

                          // Date + time
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 13,
                                color: isUpcoming
                                    ? AppTheme.primaryColor
                                    : context.appTextSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$dateStr · $timeStr',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isUpcoming
                                      ? AppTheme.primaryColor
                                      : context.appTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Description
                if (appointment.description != null &&
                    appointment.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    appointment.description!,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: context.appTextPrimary,
                      height: 1.4,
                    ),
                  ),
                ],

                // Notes
                if (appointment.notes != null &&
                    appointment.notes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: context.appBorderColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: context.appBorderColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.sticky_note_2_rounded,
                          size: 14,
                          color: AppTheme.primaryColor.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            appointment.notes!,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              color: context.appTextSecondary,
                              fontStyle: FontStyle.italic,
                              height: 1.3,
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
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isToday) {
    final color = isToday ? AppTheme.trimester2Primary : AppTheme.successColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
