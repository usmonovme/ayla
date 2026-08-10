import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/glass_input_wrapper.dart';
import '../../../core/widgets/platform_wrapper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../gamification/providers/gamification_provider.dart';
import '../../auth/models/user_model.dart';
import '../providers/pregnancy_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../gamification/widgets/badge_celebration.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';

/// Screen for adding a weight entry
class AddWeightScreen extends StatefulWidget {
  final DateTime? selectedDate;
  final bool isEmbedded;

  const AddWeightScreen({
    super.key,
    this.selectedDate,
    this.isEmbedded = false,
  });

  static Future<void> show({
    required BuildContext context,
    DateTime? selectedDate,
  }) {
    return Navigator.pushNamed(
      context,
      RouteConstants.addWeight,
      arguments: {'selectedDate': selectedDate},
    );
  }

  @override
  State<AddWeightScreen> createState() => _AddWeightScreenState();
}

class _AddWeightScreenState extends State<AddWeightScreen> {
  late DateTime _selectedDate;
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String? _weightError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _weightController.addListener(_validateWeight);
  }

  @override
  void dispose() {
    _weightController.removeListener(_validateWeight);
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _validateWeight() {
    final l10n = AppLocalizations.of(context)!;
    final value = _weightController.text;
    if (value.isEmpty) {
      setState(() => _weightError = null);
      return;
    }

    final weight = double.tryParse(value);
    if (weight == null) {
      setState(() => _weightError = l10n.common_error);
      return;
    }

    final prefs = context.read<AuthProvider>().userProfile?.preferences;
    final isLbs = prefs?.weightUnit == WeightUnit.lbs;

    final min = isLbs ? 66.0 : 30.0;
    final max = isLbs ? 550.0 : 250.0;

    if (weight < min || weight > max) {
      setState(() {
        _weightError = 'Enter a value between $min and $max';
      });
    } else {
      setState(() => _weightError = null);
    }
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    final l10n = AppLocalizations.of(context)!;
    _validateWeight();
    if (_weightError != null || _weightController.text.isEmpty) {
      return;
    }

    final weight = double.parse(_weightController.text);

    setState(() => _isLoading = true);
    try {
      await context.read<PregnancyProvider>().addWeight(
        weight,
        _selectedDate,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );
      if (mounted) {
        final pregnancyId = context.read<PregnancyProvider>().pregnancy?.id;
        final gamification = context.read<GamificationProvider>();
        final newBadges = await gamification.checkBadgeUnlocks(
          AppMode.pregnancyTracking,
          contextId: pregnancyId,
        );

        if (mounted && newBadges.isNotEmpty) {
          await showBadgeCelebration(context, newBadges);
        }

        if (mounted) {
          await PlatformUI.showMessage(
            context,
            message: l10n.health_weight_add_success,
          );
        }
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        await PlatformUI.showMessage(
          context,
          message: 'Error saving weight: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDatePicker() async {
    final picked = await PlatformUI.showPlatformDatePicker(
      context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Widget _buildAppBarTitle() {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: _showDatePicker,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.health_weight_add),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat(
                  AppConstants.dateFormatDisplay,
                ).format(_selectedDate),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final authProvider = context.watch<AuthProvider>();
    final weightUnit =
        authProvider.userProfile?.preferences.weightUnit ?? WeightUnit.kg;

    final mainContent = SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        children: [
          // Weight Input
          GlassInputWrapper(
            title: l10n.preg_weight,
            icon: Icons.monitor_weight_rounded,
            iconColor: Theme.of(context).colorScheme.primary,
            child: _buildWeightInput(weightUnit),
          ),
          const SizedBox(height: 16),

          // Notes
          GlassInputWrapper(
            title: l10n.notes,
            icon: Icons.edit_note_rounded,
            child: _buildNotesInput(l10n),
          ),
          const SizedBox(height: 24),

          // Spacer for floating button
          const SizedBox(height: 100),
        ],
      ),
    );

    final isValid = _weightError == null && _weightController.text.isNotEmpty;

    final bottomButton = ElevatedButton(
      onPressed: _isLoading || !isValid ? null : _handleSave,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.6),
        disabledForegroundColor: Colors.white70,
        overlayColor: Colors.white.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(vertical: 14),
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 2,
        shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
      ),
      child: SizedBox(
        height: 24,
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  l10n.common_save,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );

    final pageContent = Stack(
      children: [
        Positioned.fill(child: mainContent),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              AppConstants.paddingMedium,
              AppConstants.paddingMedium,
              AppConstants.paddingMedium,
              AppConstants.paddingMedium + bottomPadding,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.appBackgroundColor.withValues(alpha: 0),
                  context.appBackgroundColor.withValues(alpha: 0.9),
                  context.appBackgroundColor,
                  context.appBackgroundColor,
                ],
                stops: const [0.0, 0.2, 0.4, 1.0],
              ),
            ),
            child: bottomButton,
          ),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(gradient: context.appBackgroundGradient),
      child: PlatformScaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: BrandedAppBar(
          title: _buildAppBarTitle(),
          isPregnancy: true,
          leading: widget.isEmbedded
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
        ),
        body: SafeArea(
          top: !widget.isEmbedded,
          bottom: false,
          child: pageContent,
        ),
      ),
    );
  }

  Widget _buildWeightInput(WeightUnit unit) {
    return TextField(
      controller: _weightController,
      autofocus: true,
      textInputAction: TextInputAction.next,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        TextInputFormatter.withFunction(
          (oldValue, newValue) =>
              newValue.copyWith(text: newValue.text.replaceAll(',', '.')),
        ),
        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.?\d{0,2})')),
      ],
      style: GoogleFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: context.appTextPrimary,
      ),
      decoration: InputDecoration(
        hintText: '0.0',
        hintStyle: GoogleFonts.nunito(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: context.appTextSecondary.withValues(alpha: 0.7),
        ),
        errorText: _weightError,
        suffixText: unit.name.toLowerCase(),
        suffixStyle: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: context.appTextSecondary,
        ),
        filled: true,
        fillColor: context.appSurfaceColor.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildNotesInput(AppLocalizations l10n) {
    return TextField(
      controller: _noteController,
      maxLines: 3,
      style: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: context.appTextPrimary,
      ),
      decoration: InputDecoration(
        hintText: l10n.notes_hint,
        hintStyle: GoogleFonts.nunito(fontSize: 16, color: AppTheme.textHint),
        filled: true,
        fillColor: context.appSurfaceColor.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }
}
