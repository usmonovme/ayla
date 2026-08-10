import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../insights/providers/insights_provider.dart';
import '../../insights/widgets/insight_detail_dialog.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';
import 'pregnancy_quick_tools.dart';
import '../../../core/widgets/section_header.dart';

class HealthDashboardTab extends StatelessWidget {
  const HealthDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<InsightsProvider>(
      builder: (context, insightsProvider, child) {
        final pregInsights = insightsProvider.pregnancyActionableInsights;

        return ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            64,
            16,
            AppConstants.getBottomPadding(context),
          ),
          children: [
            if (pregInsights.isNotEmpty) ...[
              SectionHeader(title: l10n.nav_insights),
              const SizedBox(height: 12),
              _PregnancyActionableInsightsSection(insights: pregInsights),
              const SizedBox(height: 24),
            ],

            const PregnancyQuickTools(),
          ],
        );
      },
    );
  }
}

class _PregnancyActionableInsightsSection extends StatefulWidget {
  final List<ActionableInsight> insights;

  const _PregnancyActionableInsightsSection({required this.insights});

  @override
  State<_PregnancyActionableInsightsSection> createState() =>
      _PregnancyActionableInsightsSectionState();
}

class _PregnancyActionableInsightsSectionState
    extends State<_PregnancyActionableInsightsSection> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getCategoryName(BuildContext context, InsightType type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case InsightType.cycle:
        return l10n.insights_cat_cycle;
      case InsightType.symptom:
        return l10n.insights_cat_symptom;
      case InsightType.mood:
        return l10n.insights_cat_mood;
      case InsightType.healthAlert:
        return l10n.insights_cat_health;
      case InsightType.scienceSnippet:
        return l10n.insights_cat_science;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
              itemCount: widget.insights.length,
              itemBuilder: (context, index) {
                final insight = widget.insights[index];
                return GestureDetector(
                  onTap: () => InsightDetailDialog.show(context, insight),
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
                                color: insight.color.withValues(alpha: 0.15),
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
                                  insight.color.withValues(alpha: 0.06),
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
                                    color: insight.color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Icon(
                                    insight.icon,
                                    color: insight.color,
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
                                        insight.title,
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
                                      Text(
                                        insight.message,
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
                                color: insight.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: insight.color.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _getCategoryName(
                                  context,
                                  insight.type,
                                ).toUpperCase(),
                                style: TextStyle(
                                  color: insight.color,
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
              },
            ),
          ),
        ),
        if (widget.insights.length > 1) ...[
          const SizedBox(height: AppConstants.spacingSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.insights.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: _currentPage == index ? 20 : 6,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? widget.insights[index].color
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
