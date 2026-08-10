import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/pregnancy_provider.dart';
import '../models/checklist_item_model.dart';
import '../data/persistent_checklists.dart';
import '../../../core/widgets/section_header.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';
import '../../auth/models/user_model.dart';
import '../../gamification/providers/gamification_provider.dart';
import '../../gamification/widgets/badge_celebration.dart';

class PlanningTab extends StatefulWidget {
  const PlanningTab({super.key});

  @override
  State<PlanningTab> createState() => _PlanningTabState();
}

class _PlanningTabState extends State<PlanningTab> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<PregnancyProvider>();
    final allItems = provider.checklistItems;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppConstants.paddingMedium,
        64,
        AppConstants.paddingMedium,
        AppConstants.getBottomPadding(context),
      ),
      children: [
        _buildCategorySection(context, l10n.preg_checklist_hospital_bag, [
          _buildSubCategory(
            context,
            l10n.preg_checklist_hospital_mom,
            allItems
                .where(
                  (i) =>
                      i.category ==
                      PersistentChecklistData.categoryHospitalBagMom,
                )
                .toList(),
          ),
          _buildSubCategory(
            context,
            l10n.preg_checklist_hospital_baby,
            allItems
                .where(
                  (i) =>
                      i.category ==
                      PersistentChecklistData.categoryHospitalBagBaby,
                )
                .toList(),
          ),
          _buildSubCategory(
            context,
            l10n.preg_checklist_hospital_partner,
            allItems
                .where(
                  (i) =>
                      i.category ==
                      PersistentChecklistData.categoryHospitalBagPartner,
                )
                .toList(),
          ),
        ]),
        const SizedBox(height: AppConstants.spacingLarge),
        _buildCategorySection(context, l10n.preg_checklist_birth_plan, [
          _buildSubCategory(
            context,
            '',
            allItems
                .where(
                  (i) =>
                      i.category == PersistentChecklistData.categoryBirthPlan,
                )
                .toList(),
            hideTitle: true,
          ),
        ]),
        const SizedBox(height: AppConstants.spacingLarge),
        _buildCategorySection(context, l10n.preg_checklist_nursery, [
          _buildSubCategory(
            context,
            '',
            allItems
                .where(
                  (i) => i.category == PersistentChecklistData.categoryNursery,
                )
                .toList(),
            hideTitle: true,
          ),
        ]),
      ],
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String title,
    List<Widget> subCategories,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, color: AppTheme.pregnancyPrimary),
        const SizedBox(height: AppConstants.spacingMedium),
        ...subCategories,
      ],
    );
  }

  Widget _buildSubCategory(
    BuildContext context,
    String title,
    List<ChecklistItem> items, {
    bool hideTitle = false,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hideTitle) ...[
          Padding(
            padding: const EdgeInsets.only(left: 14, bottom: 8, top: 8),
            child: Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: context.appTextSecondary,
              ),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: context.appGlassColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.appGlassBorderColor),
          ),
          child: Column(
            children: items
                .map((item) => _buildChecklistItem(context, item))
                .toList(),
          ),
        ),
        const SizedBox(height: AppConstants.spacingSmall),
      ],
    );
  }

  Widget _buildChecklistItem(BuildContext context, ChecklistItem item) {
    final l10n = AppLocalizations.of(context)!;
    final String itemText = _getLocalizedItemText(l10n, item.itemKey);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          HapticFeedback.lightImpact();
          final pregnancyProvider = context.read<PregnancyProvider>();
          final gamification = context.read<GamificationProvider>();
          await pregnancyProvider.toggleChecklistItem(item);
          // Check for checklist completion badges when an item is checked
          if (!item.isChecked && context.mounted) {
            try {
              final pregnancyId = pregnancyProvider.pregnancy?.id;
              if (pregnancyId != null) {
                final newBadges = await gamification.checkBadgeUnlocks(
                  AppMode.pregnancyTracking,
                  contextId: pregnancyId,
                );
                if (context.mounted && newBadges.isNotEmpty) {
                  await showBadgeCelebration(context, newBadges);
                }
              }
            } catch (_) {
              // Badge checking is non-critical
            }
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.center, // Center aligned for single line
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: item.isChecked
                      ? AppTheme.pregnancyPrimary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: item.isChecked
                        ? AppTheme.pregnancyPrimary
                        : context.appTextSecondary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                  child: item.isChecked
                      ? const Icon(
                          Icons.check_rounded,
                          key: ValueKey('checked'),
                          size: 16,
                          color: Colors.white,
                        )
                      : const SizedBox.shrink(key: ValueKey('unchecked')),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  itemText,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: item.isChecked
                        ? FontWeight.w600
                        : FontWeight.w700,
                    color: item.isChecked
                        ? context.appTextSecondary
                        : context.appTextPrimary,
                    decoration: item.isChecked
                        ? TextDecoration.lineThrough
                        : null,
                    height: 1.2, // Tighter line height for better alignment
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLocalizedItemText(AppLocalizations l10n, String key) {
    // This is a bit hacky but works for localized strings without reflection in Flutter
    final map = {
      'preg_item_comfort_clothes': l10n.preg_item_comfort_clothes,
      'preg_item_slippers_socks': l10n.preg_item_slippers_socks,
      'preg_item_toiletries': l10n.preg_item_toiletries,
      'preg_item_nursing_gear': l10n.preg_item_nursing_gear,
      'preg_item_documents': l10n.preg_item_documents,
      'preg_item_baby_outfit': l10n.preg_item_baby_outfit,
      'preg_item_swaddle': l10n.preg_item_swaddle,
      'preg_item_diapers': l10n.preg_item_diapers,
      'preg_item_car_seat': l10n.preg_item_car_seat,
      'preg_item_partner_clothes': l10n.preg_item_partner_clothes,
      'preg_item_snacks': l10n.preg_item_snacks,
      'preg_item_charger': l10n.preg_item_charger,
      'preg_item_pain_mgmt': l10n.preg_item_pain_mgmt,
      'preg_item_birth_presence': l10n.preg_item_birth_presence,
      'preg_item_cord_clamping': l10n.preg_item_cord_clamping,
      'preg_item_skin_to_skin': l10n.preg_item_skin_to_skin,
      'preg_item_crib': l10n.preg_item_crib,
      'preg_item_changing_table': l10n.preg_item_changing_table,
      'preg_item_nursery_chair': l10n.preg_item_nursery_chair,
      'preg_item_baby_monitor': l10n.preg_item_baby_monitor,
      'preg_item_diaper_pail': l10n.preg_item_diaper_pail,
    };
    return map[key] ?? key;
  }
}
