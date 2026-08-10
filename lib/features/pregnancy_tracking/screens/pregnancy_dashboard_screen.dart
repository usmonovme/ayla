import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/platform_wrapper.dart';
import '../providers/pregnancy_provider.dart';
import '../providers/labor_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../period_tracking/providers/period_tracking_provider.dart';
import '../../period_tracking/screens/daily_entry_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import 'pregnancy_onboarding_screen.dart';
import 'week_detail_screen.dart';
import '../widgets/pregnancy_daily_log_card.dart';
import '../data/fetus_development_data.dart';
import '../data/pregnancy_localization_helper.dart';
import '../widgets/pregnancy_overview_card.dart';
import '../../../core/widgets/section_header.dart';
import '../widgets/welcome_header.dart';
import '../widgets/baby_born_dialog.dart';
import '../widgets/post_birth_navigation_dialog.dart';
import '../widgets/end_pregnancy_prompt_dialog.dart';
import '../models/end_pregnancy_option.dart';
import '../../../l10n/app_localizations.dart';
import '../../gamification/widgets/badge_celebration.dart';
import 'dart:async';
import '../../../core/services/analytics_service.dart';
import '../../support/widgets/help_guide_callout_card.dart';

class PregnancyDashboardScreen extends StatefulWidget {
  const PregnancyDashboardScreen({super.key});

  @override
  State<PregnancyDashboardScreen> createState() =>
      _PregnancyDashboardScreenState();
}

class _PregnancyDashboardScreenState extends State<PregnancyDashboardScreen> {
  late ScrollController _scrollController;
  bool _showBorder = false;
  int? _navigatedWeek;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    unawaited(AnalyticsService.instance.logViewPregnancyDashboard());
    _checkHelpCallout();
  }

  Future<void> _checkHelpCallout() async {
    final show = await HelpGuideCalloutCard.shouldShow();
    if (mounted && show) {
      debugPrint('Help guide callout should be shown');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              HelpGuideCalloutCard.show(context, onDismiss: () {});
            }
          });
        }
      });
    }
  }

  void _onScroll() {
    final showBorder = _scrollController.offset > 10;
    if (showBorder != _showBorder) {
      setState(() => _showBorder = showBorder);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<PregnancyProvider, AuthProvider, PeriodTrackingProvider>(
      builder:
          (context, pregnancyProvider, authProvider, periodProvider, child) {
            final pregnancy = pregnancyProvider.pregnancy;

            if (pregnancyProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final userName = authProvider.userProfile?.displayName;

            if (pregnancy == null) {
              return Column(
                children: [
                  WelcomeHeader(
                    userName: userName,
                    currentWeek: 0,
                    daysLeft: 0,
                    showBorder: _showBorder,
                    bottomPadding: AppConstants.paddingMediumSmall,
                    onNotificationTap: () => PlatformUI.pushPage<void>(
                      context,
                      const NotificationsScreen(),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        key: const Key('dashboard_list_empty'),
                        padding: EdgeInsets.fromLTRB(
                          AppConstants.paddingMedium,
                          AppConstants.paddingLarge,
                          AppConstants.paddingMedium,
                          AppConstants.getBottomPadding(context),
                        ),
                        child: _buildNoActivePregnancy(context),
                      ),
                    ),
                  ),
                ],
              );
            }

            final currentWeek = pregnancy.currentWeek;
            final displayWeek = _navigatedWeek ?? currentWeek.clamp(1, 40);
            final daysLeft = pregnancy.estimatedDueDate
                .difference(DateTime.now())
                .inDays;

            final fetusInfo = FetusDevelopmentData.getInfo(displayWeek);

            final today = DateTime.now();
            final dateKey = DateTime(today.year, today.month, today.day);
            final todayEntry = periodProvider.dailyEntries[dateKey];

            return Column(
              children: [
                // Sticky Welcome Header
                WelcomeHeader(
                  userName: userName,
                  currentWeek: currentWeek,
                  daysLeft: daysLeft,
                  showBorder: _showBorder,
                  bottomPadding: AppConstants.paddingMediumSmall,
                  onNotificationTap: () => PlatformUI.pushPage<void>(
                    context,
                    const NotificationsScreen(),
                  ),
                ),

                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    key: const Key('dashboard_list'),
                    padding: EdgeInsets.fromLTRB(
                      AppConstants.paddingMedium,
                      0,
                      AppConstants.paddingMedium,
                      AppConstants.getBottomPadding(context),
                    ),
                    children: [
                      const SizedBox(height: AppConstants.spacingXSmall),

                      // Hero Card
                      PregnancyOverviewCard(
                        week: displayWeek,
                        currentWeek: currentWeek,
                        dueDate: pregnancy.estimatedDueDate,
                        daysLeft: daysLeft,
                        info: fetusInfo,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          WeekDetailScreen.show(
                            context,
                            week: displayWeek,
                            isCurrentWeek: displayWeek == currentWeek,
                            isPast: displayWeek < currentWeek,
                          );
                        },
                      ),

                      const SizedBox(height: AppConstants.spacingMedium),

                      // Enhanced Daily Log Section
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 4,
                          bottom: AppConstants.spacingSmall,
                        ),
                        child: SectionHeader(
                          title: AppLocalizations.of(context)!.daily_log_title,
                          color: AppTheme.getTrimesterColor(displayWeek),
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          final gestationalDays = today
                              .difference(pregnancy.lastPeriodDate)
                              .inDays;
                          final dayOfWeek = (gestationalDays % 7) + 1;

                          return PregnancyDailyLogCard(
                            entry: todayEntry,
                            color: AppTheme.getTrimesterColor(displayWeek),
                            week: displayWeek,
                            currentWeek: currentWeek,
                            dayOfWeek: dayOfWeek,
                            description: getLocalizedDescription(
                              AppLocalizations.of(context)!,
                              displayWeek,
                            ),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              DailyEntryScreen.show(
                                context: context,
                                editingEntry: todayEntry,
                                selectedDate: todayEntry == null
                                    ? DateTime.now()
                                    : null,
                                isPregnancyMode: true,
                                activePregnancyId: pregnancy.id,
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: AppConstants.spacingSmall),

                      // End Pregnancy Button
                      _buildEndPregnancyButton(context),
                    ],
                  ),
                ),
              ],
            );
          },
    );
  }

  Widget _buildEndPregnancyButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingMedium),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: () => _handleEndPregnancy(context),
          icon: Icon(
            Icons.auto_awesome_rounded,
            size: 18,
            color: context.appTextSecondary.withValues(alpha: 0.7),
          ),
          label: Text(l10n.preg_end_button),
          style: OutlinedButton.styleFrom(
            foregroundColor: context.appTextSecondary,
            side: BorderSide(color: context.appBorderColor),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  void _handleEndPregnancy(BuildContext context) async {
    final option = await showDialog<EndPregnancyOption>(
      context: context,
      builder: (context) => const EndPregnancyPromptDialog(),
    );

    if (option == null) return;

    if (option == EndPregnancyOption.history) {
      if (context.mounted) {
        _showCompletePregnancyDialog(context);
      }
    } else {
      // Option: Just Remove
      if (context.mounted) {
        final pregnancyProvider = Provider.of<PregnancyProvider>(
          context,
          listen: false,
        );
        final laborProvider = Provider.of<LaborProvider>(
          context,
          listen: false,
        );
        final currentPregnancyId = pregnancyProvider.pregnancy?.id;

        await pregnancyProvider.deleteActivePregnancy();

        if (currentPregnancyId != null && context.mounted) {
          await laborProvider.deletePregnancyContractions(currentPregnancyId);
        }

        if (context.mounted) {
          _showPostBirthNavigation(context);
        }
      }
    }
  }

  void _showPostBirthNavigation(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PostBirthNavigationDialog(),
    );
  }

  Widget _buildNoActivePregnancy(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyStateWidget(
      icon: Icons.grid_view_outlined,
      title: l10n.preg_no_active_journey,
      message: l10n.dashboard_ready_track,
      color: AppTheme.primaryColor,
      action: ElevatedButton.icon(
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.dashboard_start_tracking),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: () => Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (context) => const PregnancyOnboardingScreen(),
          ),
        ),
      ),
    );
  }

  void _showCompletePregnancyDialog(BuildContext context) async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => const BabyBornDialog(),
    );

    if (result is Map && context.mounted) {
      final String? babyName = result['babyName'] as String?;
      final String? babyGender = result['babyGender'] as String?;

      await showBabyBornCelebration(
        context,
        babyName: babyName,
        babyGender: babyGender,
      );

      if (context.mounted) {
        _showPostBirthNavigation(context);
      }
    }
  }
}
