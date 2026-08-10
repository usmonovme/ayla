import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class TrimesterIndicator extends StatelessWidget {
  final int trimester;

  const TrimesterIndicator({super.key, required this.trimester});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        children: [
          _buildLine(),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.pregnancyPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.pregnancyPrimary.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.preg_trimester_label(trimester),
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.pregnancyPrimary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildLine(),
        ],
      ),
    );
  }

  Widget _buildLine() {
    return Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.pregnancyPrimary.withValues(alpha: 0.0),
              AppTheme.pregnancyPrimary.withValues(alpha: 0.2),
              AppTheme.pregnancyPrimary.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
