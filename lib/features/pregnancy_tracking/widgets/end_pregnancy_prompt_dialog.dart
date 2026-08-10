import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../models/end_pregnancy_option.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';

class EndPregnancyPromptDialog extends StatelessWidget {
  const EndPregnancyPromptDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceColor : context.appSurfaceColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.preg_end_prompt_title,
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: context.appTextPrimary,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.preg_end_prompt_msg,
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: context.appTextSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Option: Save to History
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pop(context, EndPregnancyOption.history),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(l10n.preg_end_option_history),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            const SizedBox(height: 12),

            // Option: Just Remove
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pop(context, EndPregnancyOption.remove),
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(l10n.preg_end_option_remove),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
