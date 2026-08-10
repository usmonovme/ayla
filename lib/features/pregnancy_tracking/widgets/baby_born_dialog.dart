import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/platform_wrapper.dart';
import '../providers/pregnancy_provider.dart';
import '../providers/labor_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';

class BabyBornDialog extends StatefulWidget {
  const BabyBornDialog({super.key});

  @override
  State<BabyBornDialog> createState() => _BabyBornDialogState();
}

class _BabyBornDialogState extends State<BabyBornDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedGender;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGender == null) {
      // Manual error for dropdown since it's not a TextFormField
      PlatformUI.showMessage(
        context,
        message: l10n.preg_select_gender,
        isError: true,
      );
      return;
    }

    final provider = Provider.of<PregnancyProvider>(context, listen: false);
    final laborProvider = Provider.of<LaborProvider>(context, listen: false);

    try {
      await provider.completePregnancy(
        birthDate: _selectedDate,
        babyName: _nameController.text.trim(),
        babyGender: _selectedGender!,
        birthWeight: _weightController.text.isNotEmpty
            ? double.tryParse(_weightController.text)
            : null,
        birthLength: _lengthController.text.isNotEmpty
            ? double.tryParse(_lengthController.text)
            : null,
        deliveryNotes: _notesController.text.isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      // Reset labor provider in-memory state (keep DB data for history)
      laborProvider.resetState();

      if (mounted) {
        // Return baby info to signal success and provide data for celebration
        Navigator.of(context).pop({
          'babyName': _nameController.text.trim(),
          'babyGender': _selectedGender,
        });
      }
    } catch (e) {
      if (mounted) {
        PlatformUI.showMessage(
          context,
          message: '${l10n.common_error}: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await PlatformUI.showPlatformDatePicker(
      context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectGender(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await PlatformUI.showPlatformActionSheet<String>(
      context,
      title: l10n.preg_gender,
      items: [
        ActionSheetItem(
          label: l10n.preg_gender_boy,
          value: 'Boy',
          icon: Icons.male,
        ),
        ActionSheetItem(
          label: l10n.preg_gender_girl,
          value: 'Girl',
          icon: Icons.female,
        ),
      ],
    );

    if (result != null) {
      setState(() {
        _selectedGender = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = context.watch<AuthProvider>().userProfile?.preferences;
    final weightUnit = prefs?.weightUnit ?? WeightUnit.kg;
    final lengthUnit = prefs?.lengthUnit ?? LengthUnit.cm;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceColor : context.appSurfaceColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.preg_baby_born,
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: context.appTextPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: context.appTextPrimary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Name
                _buildTextField(
                  controller: _nameController,
                  label: l10n.preg_baby_name,
                  icon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  maxLength: 50,
                  validator: (v) => Validators.validateName(v, l10n),
                ),
                const SizedBox(height: 16),

                // Gender Selection
                _buildSelectionField(
                  label: l10n.preg_gender,
                  value: _selectedGender != null
                      ? (_selectedGender == 'Boy'
                            ? l10n.preg_gender_boy
                            : l10n.preg_gender_girl)
                      : null,
                  placeholder: l10n.preg_select_gender,
                  icon: _selectedGender == 'Girl' ? Icons.female : Icons.male,
                  onTap: () => _selectGender(context),
                ),
                const SizedBox(height: 16),

                // Date Selection
                _buildSelectionField(
                  label: l10n.preg_birth_date,
                  value: DateFormat.yMMMMd().format(_selectedDate),
                  placeholder: '',
                  icon: Icons.calendar_today,
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 16),

                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _weightController,
                        label:
                            '${l10n.preg_weight} (${weightUnit.name.toLowerCase()})',
                        icon: Icons.monitor_weight_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            Validators.validateWeight(v, l10n, maxDigits: 3),
                        inputFormatters: [
                          TextInputFormatter.withFunction(
                            (oldValue, newValue) => newValue.copyWith(
                              text: newValue.text.replaceAll(',', '.'),
                            ),
                          ),
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d{0,3}(\.?\d{0,2})'),
                          ),
                          LengthLimitingTextInputFormatter(3),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _lengthController,
                        label:
                            '${l10n.preg_length} (${lengthUnit == LengthUnit.inch ? 'in' : lengthUnit.name.toLowerCase()})',
                        icon: Icons.straighten,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            Validators.validateLength(v, l10n, maxDigits: 3),
                        inputFormatters: [
                          TextInputFormatter.withFunction(
                            (oldValue, newValue) => newValue.copyWith(
                              text: newValue.text.replaceAll(',', '.'),
                            ),
                          ),
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d{0,3}(\.?\d{0,2})'),
                          ),
                          LengthLimitingTextInputFormatter(3),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notes
                _buildTextField(
                  controller: _notesController,
                  label: l10n.preg_delivery_notes,
                  icon: Icons.edit_note_rounded,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  validator: (v) => Validators.validateNotes(v, l10n),
                ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.pregnancyPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.preg_save_details,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: context.appTextSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.appTextPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            prefixIcon: Padding(
              padding: EdgeInsets.only(
                bottom: maxLines > 1 ? (maxLines * 12.0) : 0,
              ),
              child: Icon(icon, color: AppTheme.pregnancyPrimary),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            filled: true,
            fillColor: context.appSurfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.appBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.appBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.pregnancyPrimary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildSelectionField({
    required String label,
    required String? value,
    required String placeholder,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: context.appTextSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: context.appSurfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.appBorderColor),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Icon(icon, color: AppTheme.pregnancyPrimary),
                ),
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: value != null
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: value != null
                          ? context.appTextPrimary
                          : AppTheme.textHint,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: context.appTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
