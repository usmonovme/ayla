import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../data/fetus_development_data.dart';
import '../data/pregnancy_localization_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/theme_extension.dart';

import '../../../core/widgets/section_header.dart';

class WeeklyInsightsCarousel extends StatefulWidget {
  final FetusDevelopmentInfo info;

  const WeeklyInsightsCarousel({super.key, required this.info});

  @override
  State<WeeklyInsightsCarousel> createState() => _WeeklyInsightsCarouselState();
}

class _WeeklyInsightsCarouselState extends State<WeeklyInsightsCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Using theme colors for each card type
    final pages = [
      _InsightData(
        title: l10n.preg_dev_highlight,
        content: getLocalizedDescription(l10n, widget.info.week),
        icon: AppTheme.insightsIcon,
        accentColor: AppTheme.primaryColor,
        lightColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        categoryName: l10n.preg_tab_development.toUpperCase(),
      ),
      _InsightData(
        title: l10n.preg_weekly_tip,
        content: getLocalizedTip(l10n, widget.info.week),
        icon: Icons.lightbulb_rounded,
        accentColor: AppTheme.ovulationColor,
        lightColor: AppTheme.ovulationColor.withValues(alpha: 0.1),
        categoryName: l10n.insights_cat_science.toUpperCase(),
      ),
      _InsightData(
        title: l10n.preg_checklist,
        content: '',
        icon: Icons.task_alt_rounded,
        accentColor: AppTheme.successColor,
        lightColor: AppTheme.successColor.withValues(alpha: 0.1),
        isChecklist: true,
        checklistItems: getLocalizedChecklist(l10n, widget.info.week),
        categoryName: l10n.preg_checklist.toUpperCase(),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        SectionHeader(title: l10n.dashboard_this_week),
        const SizedBox(height: AppConstants.spacingMedium),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.9 + (0.1 * value),
              child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
            );
          },
          child: SizedBox(
            height: 180,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return _ModernInsightCard(data: pages[index]);
              },
            ),
          ),
        ),
        if (pages.length > 1) ...[
          const SizedBox(height: AppConstants.spacingSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: _currentPage == index ? 20 : 6,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? pages[index].accentColor
                      : (context.isDarkMode
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InsightData {
  final String title;
  final String content;
  final IconData icon;
  final Color accentColor;
  final Color lightColor;
  final bool isChecklist;
  final List<String> checklistItems;
  final String categoryName;

  _InsightData({
    required this.title,
    required this.content,
    required this.icon,
    required this.accentColor,
    required this.lightColor,
    required this.categoryName,
    this.isChecklist = false,
    this.checklistItems = const [],
  });
}

class _ModernInsightCard extends StatelessWidget {
  final _InsightData data;

  const _ModernInsightCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetailDialog(context, data),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: context.appSurfaceColor,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: data.accentColor.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),

              // Subtle Gradient Tint
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      data.accentColor.withValues(alpha: 0.06),
                      context.appSurfaceColor.withValues(
                        alpha: 0.0,
                      ),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
              ),

              // Content Layer
              Padding(
                padding: const EdgeInsets.all(
                  AppConstants.paddingLarge,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left Side: Icon Container
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: data.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        data.icon,
                        color: data.accentColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(
                      width: AppConstants.spacingMedium,
                    ),

                    // Right Side: Text Information
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            data.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: context.appTextPrimary,
                                  letterSpacing: -0.2,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          data.isChecklist
                              ? _buildChecklistPreview(context)
                              : Text(
                                  data.content,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: context.appTextSecondary,
                                        height: 1.4,
                                        fontSize: 13,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Special Category Label (Bottom Right)
              Positioned(
                right: 16,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: data.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: data.accentColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    data.categoryName,
                    style: TextStyle(
                      color: data.accentColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistPreview(BuildContext context) {
    if (data.checklistItems.isEmpty) {
      return Text(
        AppLocalizations.of(context)!.preg_checklist_empty,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: context.appTextSecondary,
          height: 1.4,
          fontSize: 13,
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: data.checklistItems.take(2).map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_outline, size: 14, color: data.accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appTextSecondary,
                    height: 1.4,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showDetailDialog(
    BuildContext context,
    _InsightData data,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => _InsightDetailDialog(data: data),
    );
  }
}

class _InsightDetailDialog extends StatelessWidget {
  final _InsightData data;

  const _InsightDetailDialog({required this.data});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.appSurfaceColor,
      surfaceTintColor: context.appSurfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: data.accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: data.accentColor, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: data.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                data.categoryName,
                style: TextStyle(
                  color: data.accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            data.isChecklist
                ? _buildFullChecklist(context)
                : Text(
                    data.content,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.common_close),
        ),
      ],
    );
  }

  Widget _buildFullChecklist(BuildContext context) {
    if (data.checklistItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(data.checklistItems.length, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: data.lightColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: data.accentColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: data.accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.checklistItems[index],
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    color: context.appTextPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
