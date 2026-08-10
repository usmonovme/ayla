import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/platform_wrapper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../screens/pregnancy_history_screen.dart';
import '../../../l10n/app_localizations.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';

class PostBirthNavigationDialog extends StatelessWidget {
  const PostBirthNavigationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.preg_post_birth_title,
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.preg_post_birth_msg,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.loop),
              label: Text(l10n.preg_post_birth_switch_mode),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.periodColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                context.read<AuthProvider>().setAppMode(AppMode.periodTracking);
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.history_edu),
              label: Text(l10n.preg_post_birth_view_history),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: AppTheme.primaryColor),
                foregroundColor: AppTheme.primaryColor,
              ),
              onPressed: () {
                Navigator.pop(context);
                PlatformUI.pushPage<void>(
                  context,
                  const PregnancyHistoryScreen(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
