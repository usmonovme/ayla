import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';

class TrimesterHeader extends StatelessWidget {
  final int trimester;
  final int currentWeek;
  final AppLocalizations l10n;

  const TrimesterHeader({
    super.key,
    required this.trimester,
    required this.currentWeek,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final startWeek = trimester == 1 ? 1 : (trimester == 2 ? 14 : 28);
    final endWeek = trimester == 1 ? 13 : (trimester == 2 ? 27 : 40);
    final isActive = currentWeek >= startWeek && currentWeek <= endWeek;
    final isPast = currentWeek > endWeek;
    final isFuture = currentWeek < startWeek;

    final color = AppTheme.getTrimesterColor(startWeek);
    final title = _getTrimesterTitle(trimester, l10n);
    
    double progress = 0.0;
    String statusText = '';
    
    if (isPast) {
      progress = 1.0;
      statusText = l10n.preg_trimester_status_completed;
    } else if (isActive) {
      progress = (currentWeek - startWeek + 1) / (endWeek - startWeek + 1);
      final weeksLeft = endWeek - currentWeek;
      statusText = weeksLeft > 0 
          ? l10n.preg_trimester_status_weeks_left(weeksLeft) 
          : l10n.preg_trimester_status_final_week;
    } else {
      statusText = trimester == 1 ? '1–13' : (trimester == 2 ? '14–27' : '28–40');
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      height: 64, // Fixed height for a sleek, compact look
      decoration: BoxDecoration(
        color: context.appSurfaceColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withValues(alpha: isActive ? 0.35 : 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isActive ? color : Colors.black).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Subtle Background Detail - Only for past or active
            if (!isFuture)
              Positioned(
                right: -10,
                top: -10,
                child: Opacity(
                  opacity: 0.04,
                  child: SvgPicture.asset(
                    _getTrimesterAsset(trimester),
                    width: 80,
                    height: 80,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  ),
                ),
              ),
            
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Trimester Icon Badge
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isActive ? color : color.withValues(alpha: 0.6),
                          isActive ? color.withValues(alpha: 0.7) : color.withValues(alpha: 0.4),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        if (isActive)
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        _getTrimesterAsset(trimester),
                        width: 20,
                        height: 20,
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  
                  // Title & Status
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: context.appTextPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          statusText,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isActive ? color : context.appTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Progress Ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          value: isFuture ? 0.0 : progress,
                          strokeWidth: 3,
                          backgroundColor: context.appDividerColor.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isFuture ? context.appDividerColor.withValues(alpha: 0.2) : color,
                          ),
                        ),
                      ),
                      if (isPast)
                        Icon(Icons.check_rounded, size: 16, color: color)
                      else
                        Text(
                          '${isFuture ? 0 : (progress * 100).round()}%',
                          style: GoogleFonts.nunito(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: isFuture ? context.appTextSecondary : context.appTextPrimary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTrimesterAsset(int trimester) {
    switch (trimester) {
      case 1:
        return 'assets/icons/trimester_1.svg';
      case 2:
        return 'assets/icons/trimester_2.svg';
      case 3:
        return 'assets/icons/trimester_3.svg';
      default:
        return 'assets/icons/trimester_1.svg';
    }
  }

  String _getTrimesterTitle(int trimester, AppLocalizations l10n) {
    switch (trimester) {
      case 1: return l10n.preg_trimester_1_title;
      case 2: return l10n.preg_trimester_2_title;
      case 3: return l10n.preg_trimester_3_title;
      default: return '';
    }
  }
}
