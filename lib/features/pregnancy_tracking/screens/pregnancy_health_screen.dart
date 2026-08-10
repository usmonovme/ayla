import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/pregnancy_provider.dart';
import '../widgets/health_dashboard_tab.dart';
import '../widgets/daily_logs_tab.dart';
import '../widgets/planning_tab.dart';
import 'pregnancy_onboarding_screen.dart';

class PregnancyHealthScreen extends StatefulWidget {
  final int? initialTabIndex;

  const PregnancyHealthScreen({super.key, this.initialTabIndex});

  @override
  State<PregnancyHealthScreen> createState() => _PregnancyHealthScreenState();
}

class _PregnancyHealthScreenState extends State<PregnancyHealthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex ?? 0,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging ||
          _tabController.animation!.value == _tabController.index) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<PregnancyProvider>(
      builder: (context, pregnancyProvider, child) {
        if (pregnancyProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final pregnancy = pregnancyProvider.pregnancy;

        if (pregnancy == null) {
          return EmptyStateWidget(
            icon: Icons.monitor_heart_outlined,
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

        return Stack(
          children: [
            TabBarView(
              controller: _tabController,
              children: const [
                HealthDashboardTab(),
                DailyLogsTab(),
                PlanningTab(),
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
                  l10n.insights_tab_overview,
                  l10n.period_tab_logs,
                  l10n.preg_tab_planning,
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
