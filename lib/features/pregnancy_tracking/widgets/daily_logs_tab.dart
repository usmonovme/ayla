import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/platform_wrapper.dart';
import '../../../core/constants/app_constants.dart';
import '../../period_tracking/providers/period_tracking_provider.dart';
import '../providers/pregnancy_provider.dart';
import '../../period_tracking/widgets/daily_entry_card.dart';
import '../../period_tracking/screens/daily_entry_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../gamification/providers/gamification_provider.dart';
import '../../../core/widgets/section_header.dart';
import 'action_link.dart';

class DailyLogsTab extends StatefulWidget {
  const DailyLogsTab({super.key});

  @override
  State<DailyLogsTab> createState() => _DailyLogsTabState();
}

class _DailyLogsTabState extends State<DailyLogsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PeriodTrackingProvider>().loadDailyEntries();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activePregnancyId = context.watch<PregnancyProvider>().pregnancy?.id;

    return Consumer<PeriodTrackingProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final allEntries = activePregnancyId == null
            ? provider.filteredDailyEntries.where((_) => false).toList()
            : provider.filteredDailyEntries
                  .where((e) => e.pregnancyLogId == activePregnancyId)
                  .toList();

        if (allEntries.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 64),
            child: EmptyStateWidget(
              icon: Icons.edit_note_rounded,
              title: provider.dailyFilterCriteria.hasActiveFilters
                  ? l10n.filter_no_results
                  : l10n.period_empty_logs_title,
              message: provider.dailyFilterCriteria.hasActiveFilters
                  ? l10n.filter_adjust_msg
                  : l10n.period_empty_logs_msg,
              color: AppTheme.pregnancyPrimary,
              action: ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.preg_log_today_btn),
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
                onPressed: () {
                  HapticFeedback.lightImpact();
                  DailyEntryScreen.show(
                    context: context,
                    selectedDate: DateTime.now(),
                    isPregnancyMode: true,
                    activePregnancyId: activePregnancyId,
                  );
                },
              ),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 64, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SectionHeader(
                    title: l10n.period_tab_logs,
                    color: AppTheme.pregnancyPrimary,
                  ),
                  ActionLink(
                    icon: Icons.add_rounded,
                    label: l10n.preg_log_today_btn,
                    color: AppTheme.pregnancyPrimary,
                    onTap: () => DailyEntryScreen.show(
                      context: context,
                      selectedDate: DateTime.now(),
                      isPregnancyMode: true,
                      activePregnancyId: activePregnancyId,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                displacement: 40,
                onRefresh: () async {
                  await provider.loadDailyEntries();
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    AppConstants.getBottomPadding(context) + 16,
                  ),
                  itemCount: allEntries.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppConstants.spacingMedium),
                  itemBuilder: (context, index) {
                    final entry = allEntries[index];
                    return DailyEntryCard(
                      entry: entry,
                      isPregnancy: true,
                      onTap: () => DailyEntryScreen.show(
                        context: context,
                        editingEntry: entry,
                        isPregnancyMode: true,
                        activePregnancyId: activePregnancyId,
                      ),
                      onDelete: () async {
                        try {
                          await context
                              .read<PeriodTrackingProvider>()
                              .deleteDailyEntry(
                                entryId: entry.id,
                                date: entry.date,
                              );
                          if (!context.mounted) return;
                          context
                              .read<GamificationProvider>()
                              .recalculateStreak();
                          PlatformUI.showMessage(
                            context,
                            message: l10n.period_delete_entry_success,
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          PlatformUI.showMessage(
                            context,
                            message: l10n.entry_delete_error(e.toString()),
                            isError: true,
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
