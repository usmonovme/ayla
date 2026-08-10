import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/string_utils.dart';
import '../../../l10n/app_localizations.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';

class HealthDateBadge extends StatelessWidget {
  final DateTime date;
  final bool isPrimary;

  const HealthDateBadge({
    super.key,
    required this.date,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final monthColor = isPrimary
        ? AppTheme.primaryColor
        : context.appTextSecondary;
    final dayColor = isPrimary
        ? context.appTextPrimary
        : context.appTextPrimary;

    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: context.appSurfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appDividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('MMM', l10n.localeName).format(date).capitalize(),
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: monthColor,
            ),
          ),
          Text(
            date.day.toString(),
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: dayColor,
            ),
          ),
        ],
      ),
    );
  }
}
