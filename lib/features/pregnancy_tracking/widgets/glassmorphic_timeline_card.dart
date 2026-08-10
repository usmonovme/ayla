import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../l10n/app_localizations.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';

class GlassmorphicTimelineCard extends StatelessWidget {
  final int week;
  final String title;
  final String sizeDescription;
  final bool isExpanded;
  final VoidCallback onTap;
  final Widget child;
  final bool isCurrentWeek;

  const GlassmorphicTimelineCard({
    super.key,
    required this.week,
    required this.title,
    required this.sizeDescription,
    required this.isExpanded,
    required this.onTap,
    required this.child,
    this.isCurrentWeek = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: EdgeInsets.zero,
        opacity: isCurrentWeek ? 0.8 : 0.4,
        borderRadius: 28,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: isCurrentWeek
                                      ? AppTheme.pregnancyPrimary
                                      : context.appTextPrimary,
                                ),
                              ),
                              if (isCurrentWeek) ...[
                                const SizedBox(width: 12),
                                _buildCurrentChip(context),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sizeDescription,
                            style: GoogleFonts.nunito(
                              color: context.appTextSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: context.appTextSecondary,
                    ),
                  ],
                ),
              ),
              if (isExpanded) ...[
                const Divider(height: 1),
                Padding(padding: const EdgeInsets.all(16.0), child: child),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.pregnancyPrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        AppLocalizations.of(context)!.preg_current,
        style: GoogleFonts.nunito(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
