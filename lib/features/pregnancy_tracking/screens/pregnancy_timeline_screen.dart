import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../gamification/widgets/badge_celebration.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/navigation/navigation_provider.dart';
import '../providers/pregnancy_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import 'pregnancy_onboarding_screen.dart';
import 'week_detail_screen.dart';
import '../widgets/baby_born_dialog.dart';
import '../widgets/post_birth_navigation_dialog.dart';
import 'widgets/trimester_page_widget.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';

class PregnancyTimelineScreen extends StatefulWidget {
  const PregnancyTimelineScreen({super.key});

  @override
  State<PregnancyTimelineScreen> createState() =>
      _PregnancyTimelineScreenState();
}

class _PregnancyTimelineScreenState extends State<PregnancyTimelineScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _hasInitializedView = false;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _jumpToCurrentTrimester() {
    final provider = Provider.of<PregnancyProvider>(context, listen: false);
    final currentWeek = provider.pregnancy?.currentWeek ?? 0;
    if (currentWeek <= 0) return;

    final targetIndex = _getTrimesterForWeek(currentWeek) - 1;
    if (targetIndex != _tabController.index) {
      _tabController.index = targetIndex;
    }
  }

  int _getTrimesterForWeek(int week) {
    if (week <= 13) return 1;
    if (week <= 27) return 2;
    return 3;
  }

  void _onWeekTap(int week, int currentWeek, bool isPremium) {
    WeekDetailScreen.show(
      context,
      week: week,
      isCurrentWeek: week == currentWeek,
      isPast: week < currentWeek,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PregnancyProvider>(
      builder: (context, pregnancyProvider, child) {
        final pregnancy = pregnancyProvider.pregnancy;
        final l10n = AppLocalizations.of(context)!;
        final navProvider = context.watch<NavigationProvider>();
        final pendingWeek = navProvider.pendingTimelineWeek;

        if (pendingWeek != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final currentWeek = pregnancy?.currentWeek ?? 0;
              final isPremium = context.read<AuthProvider>().isPremium;
              _onWeekTap(pendingWeek, currentWeek, isPremium);
              context.read<NavigationProvider>().clearPendingTimelineWeek();
            }
          });
        }

        if (pregnancyProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (pregnancy == null) {
          return EmptyStateWidget(
            icon: Icons.route_outlined,
            title: l10n.preg_no_active_journey,
            message: l10n.preg_no_active_journey_msg,
            color: AppTheme.pregnancyPrimary,
            action: ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.preg_onboarding_btn),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.pregnancyPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
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

        final currentWeek = pregnancy.currentWeek;
        final isPremium = context.select<AuthProvider, bool>(
          (p) => p.isPremium,
        );

        if (!_hasInitializedView) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_hasInitializedView) {
              _jumpToCurrentTrimester();
              _hasInitializedView = true;
            }
          });
        }

        return Container(
          decoration: BoxDecoration(gradient: context.appBackgroundGradient),
          child: Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: [
                  TrimesterPageWidget(
                    trimester: 1,
                    currentWeek: currentWeek,
                    isPremium: isPremium,
                    l10n: l10n,
                    pulseAnimation: _pulseAnimation,
                    onWeekTap: (w, c, p) => _onWeekTap(w, c, p),
                    onFinishTap: () => _showCompletePregnancyDialog(context),
                  ),
                  TrimesterPageWidget(
                    trimester: 2,
                    currentWeek: currentWeek,
                    isPremium: isPremium,
                    l10n: l10n,
                    pulseAnimation: _pulseAnimation,
                    onWeekTap: (w, c, p) => _onWeekTap(w, c, p),
                    onFinishTap: () => _showCompletePregnancyDialog(context),
                  ),
                  TrimesterPageWidget(
                    trimester: 3,
                    currentWeek: currentWeek,
                    isPremium: isPremium,
                    l10n: l10n,
                    pulseAnimation: _pulseAnimation,
                    onWeekTap: (w, c, p) => _onWeekTap(w, c, p),
                    onFinishTap: () => _showCompletePregnancyDialog(context),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ModernTabBar(
                  controller: _tabController,
                  isScrollable: false,
                  tabs: [
                    l10n.preg_trimester_label(1),
                    l10n.preg_trimester_label(2),
                    l10n.preg_trimester_label(3),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const PostBirthNavigationDialog(),
        );
      }
    }
  }
}
