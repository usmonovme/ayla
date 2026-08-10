import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/platform_wrapper.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/pregnancy_provider.dart';
import '../models/pregnancy_model.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';
import 'pregnancy_history_detail_screen.dart';
import '../../../core/widgets/ambient_bottom_scrim.dart';

/// Streamlined, modern Pregnancy History Screen displaying past journeys
/// as clean, elegant keepsake cards.
class PregnancyHistoryScreen extends StatefulWidget {
  const PregnancyHistoryScreen({super.key});

  @override
  State<PregnancyHistoryScreen> createState() => _PregnancyHistoryScreenState();
}

class _PregnancyHistoryScreenState extends State<PregnancyHistoryScreen> {
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isInitialLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: BrandedAppBar(
        isPregnancy: true,
        title: Text(l10n.preg_history_title),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.appBackgroundGradient),
        child: SafeArea(
          bottom: false,
          child: Consumer<PregnancyProvider>(
            builder: (context, provider, child) {
              final history = provider.history
                  .where((p) => !p.isActive)
                  .toList();

              if (_isInitialLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (history.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.history_rounded,
                  title: l10n.preg_history_empty_title,
                  message: l10n.preg_history_empty_msg,
                  color: AppTheme.pregnancyPrimary,
                );
              }

              return Stack(
                children: [
                  ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.paddingOf(context).bottom + 60.0),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final pregnancy = history[index];
                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 300 + (index * 60)),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 16 * (1.0 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: PregnancyHistoryCard(pregnancy: pregnancy),
                      );
                    },
                  ),
                  const AmbientBottomScrim(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class PregnancyHistoryCard extends StatelessWidget {
  final Pregnancy pregnancy;
  const PregnancyHistoryCard({super.key, required this.pregnancy});

  void _onDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    PlatformUI.showDeleteDialog(
      context,
      itemType: l10n.preg_history_title,
      onDelete: () async {
        try {
          await context.read<PregnancyProvider>().deletePregnancyHistory(
            pregnancy.id,
            pregnancy.userId,
          );
          if (context.mounted) {
            PlatformUI.showMessage(context, message: l10n.common_success);
          }
        } catch (e) {
          if (context.mounted) {
            PlatformUI.showMessage(
              context,
              message: e.toString(),
              isError: true,
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = pregnancy;
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;

    // Calculate birth week for trimester color
    final end = p.birthDate ?? p.updatedAt;
    final diff = end.difference(p.lastPeriodDate).inDays;
    final birthWeek = (diff / 7).floor() + 1;
    final trimesterColor = AppTheme.getTrimesterColor(birthWeek);

    final birthDateStr = p.birthDate != null
        ? DateFormat.yMMMMd(l10n.localeName).format(p.birthDate!)
        : DateFormat.yMMMMd(l10n.localeName).format(p.updatedAt);

    final isBoy =
        p.babyGender?.toLowerCase() == 'boy' ||
        p.babyGender?.toLowerCase() ==
            l10n.preg_history_gender_boy.toLowerCase();
    final isGirl =
        p.babyGender?.toLowerCase() == 'girl' ||
        p.babyGender?.toLowerCase() ==
            l10n.preg_history_gender_girl.toLowerCase();

    final Color genderAccent = isBoy
        ? AppTheme.primaryColor
        : (isGirl ? AppTheme.trimester1Primary : trimesterColor);

    final IconData genderIcon = isBoy
        ? Icons.male_rounded
        : (isGirl ? Icons.female_rounded : Icons.child_care_rounded);

    final String genderLabel = isBoy
        ? l10n.preg_gender_boy
        : (isGirl ? l10n.preg_gender_girl : (p.babyGender ?? ''));

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      borderRadius: 22,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) =>
                  PregnancyHistoryDetailScreen(pregnancy: p),
            ),
          );
        },
        onLongPress: () {
          HapticFeedback.heavyImpact();
          _onDelete(context);
        },
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar circle with soft pastel gradient
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      genderAccent.withValues(alpha: isDark ? 0.25 : 0.15),
                      genderAccent.withValues(alpha: isDark ? 0.08 : 0.04),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: genderAccent.withValues(alpha: isDark ? 0.35 : 0.25),
                    width: 1.5,
                  ),
                ),
                child: Icon(genderIcon, color: genderAccent, size: 24),
              ),
              const SizedBox(width: 14),

              // Info column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.babyName ?? l10n.preg_baby_default_name,
                      style: GoogleFonts.nunito(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: context.appTextPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          p.birthDate != null
                              ? Icons.cake_rounded
                              : Icons.calendar_today_rounded,
                          size: 13,
                          color: context.appTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            birthDateStr,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: context.appTextSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Clean tag pills
                    Row(
                      children: [
                        if (genderLabel.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: genderAccent.withValues(
                                alpha: isDark ? 0.2 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              genderLabel,
                              style: GoogleFonts.nunito(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: genderAccent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: trimesterColor.withValues(
                              alpha: isDark ? 0.2 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p.getDuration(
                              l10n.unit_weeks_short,
                              l10n.unit_days_short,
                            ),
                            style: GoogleFonts.nunito(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: trimesterColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Right arrow
              Icon(
                Icons.chevron_right_rounded,
                color: context.appTextSecondary.withValues(alpha: 0.45),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

