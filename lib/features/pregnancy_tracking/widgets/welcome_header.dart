import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/theme_extension.dart';
import 'package:provider/provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../gamification/widgets/streak_display.dart';

class WelcomeHeader extends StatelessWidget {
  final String? userName;
  final int currentWeek;
  final int daysLeft;
  final VoidCallback? onNotificationTap;
  final bool showBorder;
  final double bottomPadding;

  const WelcomeHeader({
    super.key,
    this.userName,
    required this.currentWeek,
    required this.daysLeft,
    this.onNotificationTap,
    this.showBorder = false,
    this.bottomPadding = AppConstants.paddingMediumSmall,
  });

  String _getGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.greeting_morning;
    if (hour < 17) return l10n.greeting_afternoon;
    return l10n.greeting_evening;
  }

  String _getFirstName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return '';
    return fullName.split(' ').first;
  }

  String _getMotivationalMessage(AppLocalizations l10n) {
    if (currentWeek <= 13) {
      // First trimester
      if (currentWeek <= 4) return l10n.welcome_preg_trimester1_early;
      if (currentWeek <= 8) return l10n.welcome_preg_trimester1_mid;
      return l10n.welcome_preg_trimester1_late;
    } else if (currentWeek <= 27) {
      // Second trimester
      if (currentWeek <= 20) return l10n.welcome_preg_trimester2_early;
      return l10n.welcome_preg_trimester2_late;
    } else {
      // Third trimester
      if (daysLeft > 60) return l10n.welcome_preg_trimester3_early;
      if (daysLeft > 30) return l10n.welcome_preg_trimester3_mid;
      if (daysLeft > 14) return l10n.welcome_preg_trimester3_late;
      if (daysLeft > 0) return l10n.welcome_preg_trimester3_very_late;
      return l10n.welcome_preg_baby_here;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final greeting = _getGreeting(l10n);
    final firstName = _getFirstName(userName);
    final message = _getMotivationalMessage(l10n);

    return ClipRRect(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 200),
        tween: Tween<double>(begin: 0.0, end: showBorder ? 10.0 : 0.0),
        builder: (context, sigma, child) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: child!,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: context.appBackgroundColor.withValues(
              alpha: showBorder ? 1.0 : 0.0,
            ),
            border: Border(
              bottom: BorderSide(
                color: showBorder
                    ? context.appDividerColor
                    : context.appDividerColor.withValues(alpha: 0.0),
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppConstants.paddingMedium,
              AppConstants.paddingMediumSmall +
                  MediaQuery.of(context).padding.top,
              AppConstants.paddingMedium,
              bottomPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            firstName.isNotEmpty
                                ? l10n.greeting_with_name(greeting, firstName)
                                : greeting,
                            style: GoogleFonts.nunito(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: context.appTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.appTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const StreakDisplay(),
                    const SizedBox(width: 8),
                    // Notification button
                    if (onNotificationTap != null)
                      GestureDetector(
                        onTap: onNotificationTap,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.appBackgroundColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.15,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Consumer<NotificationProvider>(
                            builder: (context, notificationProvider, _) {
                              final hasUnread = notificationProvider.hasUnread;
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.notifications_outlined,
                                    color: AppTheme.primaryColor,
                                    size: 22,
                                  ),
                                  if (hasUnread)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: AppTheme.errorColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: context.appBackgroundColor,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
