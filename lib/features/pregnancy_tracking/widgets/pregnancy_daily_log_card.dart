import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_extension.dart';
import '../../period_tracking/models/daily_entry_model.dart';
import '../../../l10n/app_localizations.dart';
import '../data/pregnancy_localization_helper.dart';

class PregnancyDailyLogCard extends StatefulWidget {
  final DailyEntry? entry;
  final VoidCallback onTap;
  final Color color;
  final int week;
  final int currentWeek;
  final int dayOfWeek;
  final String description;

  const PregnancyDailyLogCard({
    super.key,
    this.entry,
    required this.onTap,
    required this.color,
    required this.week,
    required this.currentWeek,
    required this.dayOfWeek,
    required this.description,
  });

  @override
  State<PregnancyDailyLogCard> createState() => _PregnancyDailyLogCardState();
}

class _PregnancyDailyLogCardState extends State<PregnancyDailyLogCard> {
  int _currentInsightIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasEntry = widget.entry != null;

    final insights = [
      _InsightData(
        title: l10n.preg_dev_highlight,
        content: getLocalizedDescription(l10n, widget.week),
        icon: AppTheme.insightsIcon,
        accentColor: widget.color,
      ),
      _InsightData(
        title: l10n.preg_weekly_tip,
        content: getLocalizedTip(l10n, widget.week),
        icon: Icons.lightbulb_rounded,
        accentColor: Colors.amber,
      ),
      _InsightData(
        title: l10n.preg_checklist,
        content: '',
        icon: Icons.task_alt_rounded,
        accentColor: widget.color,
        isChecklist: true,
        checklistItems: getLocalizedChecklist(l10n, widget.week),
      ),
    ];

    final currentInsight = insights[_currentInsightIndex];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: context.appGlassColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: context.appGlassBorderColor,
                width: 1.0,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Content: Large Indicator + Info Column
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildIndicator(context, l10n),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Label & Navigation Row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        l10n.dashboard_this_week,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: context.appTextPrimary,
                                          letterSpacing: -0.5,
                                          height: 1.0,
                                        ),
                                      ),
                                      _buildNavButton(
                                        icon: Icons.autorenew_rounded,
                                        onPressed: () => setState(() {
                                          _currentInsightIndex =
                                              (_currentInsightIndex + 1) %
                                              insights.length;
                                        }),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    currentInsight.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: context.appTextSecondary,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Insight Content (Animated)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: currentInsight.isChecklist
                          ? _buildChecklistPreview(
                              context,
                              currentInsight,
                              l10n,
                            )
                          : Text(
                              currentInsight.content,
                              key: ValueKey(_currentInsightIndex),
                              style: TextStyle(
                                fontSize: 14,
                                color: context.appTextSecondary,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Progress Bar (Day of Week)
                    _buildProgressBar(context, widget.dayOfWeek, widget.color),

                    const SizedBox(height: 24),

                    // Interaction Section
                    if (hasEntry) ...[
                      _buildLoggedStateStat(context, l10n),
                    ] else ...[
                      _buildEmptyStatePrompt(context, l10n),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({required IconData icon, VoidCallback? onPressed}) {
    return Material(
      color: Colors.transparent,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        color: context.appTextSecondary.withValues(alpha: 0.6),
        disabledColor: context.appTextSecondary.withValues(alpha: 0.2),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
        splashRadius: 20,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildChecklistPreview(
    BuildContext context,
    _InsightData data,
    AppLocalizations l10n,
  ) {
    if (data.checklistItems.isEmpty) {
      return Text(
        l10n.preg_checklist_empty,
        key: ValueKey(_currentInsightIndex),
        style: TextStyle(
          fontSize: 14,
          color: context.appTextSecondary,
          height: 1.4,
        ),
      );
    }
    return Column(
      key: ValueKey(_currentInsightIndex),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(data.checklistItems.length, (index) {
        final item = data.checklistItems[index];
        final isLast = index == data.checklistItems.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline node & connector
              SizedBox(
                width: 14,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: data.accentColor,
                          boxShadow: [
                            BoxShadow(
                              color: data.accentColor.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: data.accentColor.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Checklist text
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 10.0),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.appTextSecondary,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildIndicator(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color,
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.dayOfWeek}',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          Text(
            l10n.cal_day_suffix.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 0.5,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, int day, Color color) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Stack(
          alignment: Alignment.centerLeft,
          clipBehavior: Clip.none,
          children: [
            // Background track
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.appBorderColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Progress segment
            LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                final progress = (day / 7).clamp(0.05, 1.0);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      height: 10,
                      width: maxWidth * progress,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withValues(alpha: 0.6), color],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: (maxWidth * progress) - 8,
                      top: -3,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.cal_day_1,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.appTextSecondary.withValues(alpha: 0.5),
              ),
            ),
            Text(
              l10n.cal_day_n(7),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.appTextSecondary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoggedStateStat(BuildContext context, AppLocalizations l10n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.appSurfaceColor.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(widget.entry?.mood != null ? 8 : 10),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: widget.entry?.mood != null
                    ? Text(
                        _getMoodEmoji(widget.entry!.mood!),
                        style: const TextStyle(fontSize: 24),
                      )
                    : Icon(
                        Icons.task_alt_rounded,
                        color: widget.color,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.entry?.mood != null
                          ? l10n.preg_daily_log_feeling(
                              widget.entry!.mood!.localizedName(l10n),
                            )
                          : l10n.cal_logged,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _hasSymptomsOrNotes
                          ? _buildSummary(l10n)
                          : l10n.preg_daily_log_empty_msg,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_rounded, color: widget.color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStatePrompt(BuildContext context, AppLocalizations l10n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.appSurfaceColor.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_reaction_rounded,
                  color: widget.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.preg_daily_log_add,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.preg_daily_log_empty_msg,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: context.appTextSecondary.withValues(alpha: 0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasSymptomsOrNotes {
    if (widget.entry == null) return false;
    return widget.entry!.physicalSymptoms.isNotEmpty ||
        widget.entry!.emotionalSymptoms.isNotEmpty ||
        (widget.entry!.notes != null && widget.entry!.notes!.isNotEmpty);
  }

  String _buildSummary(AppLocalizations l10n) {
    if (widget.entry == null) return '';
    final symptoms =
        widget.entry!.physicalSymptoms.length +
        widget.entry!.emotionalSymptoms.length;
    final List<String> parts = [];
    if (symptoms > 0) {
      parts.add(l10n.entry_symptoms_count(symptoms));
    }
    if (widget.entry!.notes != null && widget.entry!.notes!.isNotEmpty) {
      parts.add(l10n.entry_note_added);
    }
    return parts.join(' • ');
  }

  String _getMoodEmoji(Mood mood) {
    switch (mood) {
      case Mood.terrible:
        return '😖';
      case Mood.bad:
        return '☹️';
      case Mood.okay:
        return '😐';
      case Mood.good:
        return '🙂';
      case Mood.great:
        return '😄';
    }
  }
}

class _InsightData {
  final String title;
  final String content;
  final IconData icon;
  final Color accentColor;
  final bool isChecklist;
  final List<String> checklistItems;

  _InsightData({
    required this.title,
    required this.content,
    required this.icon,
    required this.accentColor,
    this.isChecklist = false,
    this.checklistItems = const [],
  });
}
