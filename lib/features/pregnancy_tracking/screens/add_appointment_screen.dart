import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/glass_input_wrapper.dart';
import '../../../core/widgets/platform_wrapper.dart';
import '../../gamification/providers/gamification_provider.dart';
import '../../auth/models/user_model.dart';
import '../providers/pregnancy_provider.dart';
import '../models/appointment_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../gamification/widgets/badge_celebration.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';

/// Screen for scheduling a new appointment
class AddAppointmentScreen extends StatefulWidget {
  final DateTime? selectedDate;
  final bool isEmbedded;

  const AddAppointmentScreen({
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
      RouteConstants.addAppointment,
      arguments: {'selectedDate': selectedDate},
    );
  }

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  int? _reminderLeadTime = 60; // Default 1 hour
  bool _isLoading = false;

  List<Map<String, dynamic>> _getLeadTimeOptions(AppLocalizations l10n) => [
    {'label': l10n.health_appt_reminder_none, 'value': null},
    {'label': l10n.health_appt_reminder_15m, 'value': 15},
    {'label': l10n.health_appt_reminder_30m, 'value': 30},
    {'label': l10n.health_appt_reminder_1h, 'value': 60},
    {'label': l10n.health_appt_reminder_2h, 'value': 120},
    {'label': l10n.health_appt_reminder_1d, 'value': 1440},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate =
        widget.selectedDate ?? DateTime.now().add(const Duration(days: 1));
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context)!;
    if (_titleController.text.isEmpty) {
      PlatformUI.showMessage(
        context,
        message: l10n.health_appt_error_title,
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final provider = context.read<PregnancyProvider>();
      final pregnancy = provider.pregnancy;

      if (pregnancy == null) {
        throw Exception('No active pregnancy');
      }

      DateTime? reminderTime;
      if (_reminderLeadTime != null) {
        reminderTime = dateTime.subtract(Duration(minutes: _reminderLeadTime!));
      }

      final appointment = Appointment(
        id: const Uuid().v4(),
        pregnancyId: pregnancy.id,
        userId: pregnancy.userId,
        date: dateTime,
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        reminderTime: reminderTime,
        reminderLeadTime: _reminderLeadTime,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await provider.addAppointment(appointment);

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
            message: l10n.health_appt_add_success,
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
          message: 'Error saving appointment: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDateTimePicker() async {
    final pickedDate = await PlatformUI.showPlatformDatePicker(
      context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 300)),
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final pickedTime = await PlatformUI.showPlatformTimePicker(
        context,
        initialTime: _selectedTime,
      );
      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDate = pickedDate;
          _selectedTime = pickedTime;
        });
      }
    }
  }

  void _showReminderPicker(AppLocalizations l10n) async {
    final options = _getLeadTimeOptions(l10n);
    final items = options.map((opt) {
      return ActionSheetItem<int?>(
        label: opt['label'] as String,
        value: opt['value'] as int?,
        isSelected: opt['value'] == _reminderLeadTime,
        icon: Icons.notifications_active_rounded,
        iconColor: Colors.amber,
      );
    }).toList();

    // Show action sheet. Since 'None' value is null, we need to know if it was picked or dismissed.
    // But usually dismissing means 'no change'.
    final result = await PlatformUI.showPlatformActionSheet<int?>(
      context,
      title: l10n.health_appt_reminder,
      items: items,
    );

    // If selected an item (even if it's null for 'None'), result will be that value.
    // If dismissed, result will be null.
    // This is ambiguous for 'None'.
    // Let's use a workaround: check if the selected value is different.
    // Or better, change 'None' value to a unique one like -1 for this picker.

    // Actually, I'll just check if the result is explicitly one of the values.
    final pickedOption = options.any((o) => o['value'] == result);
    if (pickedOption || result != null) {
      setState(() => _reminderLeadTime = result);
    }
  }

  Widget _buildAppBarTitle() {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: _showDateTimePicker,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.health_appt_add),
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
              const SizedBox(width: 4),
              Text(
                _selectedTime.format(context),
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

    final mainContent = SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        children: [
          // Title
          GlassInputWrapper(
            title: l10n.health_appt_title,
            icon: Icons.event_note_rounded,
            iconColor: AppTheme.primaryColor,
            child: _buildTitleInput(l10n),
          ),
          const SizedBox(height: 16),

          // Location / Doctor
          GlassInputWrapper(
            title: l10n.health_appt_location,
            icon: Icons.place_rounded,
            iconColor: AppTheme.accentColor,
            child: _buildLocationInput(l10n),
          ),
          const SizedBox(height: 16),

          // Reminder
          GlassInputWrapper(
            title: l10n.health_appt_reminder,
            icon: Icons.notifications_active_rounded,
            iconColor: Colors.amber,
            child: _buildReminderSelector(l10n),
          ),
          const SizedBox(height: 16),

          // Notes
          GlassInputWrapper(
            title: l10n.notes,
            icon: Icons.description_rounded,
            iconColor: context.appTextSecondary,
            child: _buildNotesInput(l10n),
          ),
          const SizedBox(height: 24),

          // Spacer for floating button
          const SizedBox(height: 100),
        ],
      ),
    );

    final isValid = _titleController.text.isNotEmpty;

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

  Widget _buildTitleInput(AppLocalizations l10n) {
    return TextField(
      controller: _titleController,
      autofocus: true,
      style: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: context.appTextPrimary,
      ),
      decoration: InputDecoration(
        hintText: l10n.health_appt_title_hint,
        hintStyle: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.textHint,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildLocationInput(AppLocalizations l10n) {
    return TextField(
      controller: _descriptionController,
      style: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: context.appTextPrimary,
      ),
      decoration: InputDecoration(
        hintText: l10n.health_appt_location_hint,
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

  Widget _buildReminderSelector(AppLocalizations l10n) {
    final options = _getLeadTimeOptions(l10n);
    final selectedOption = options.firstWhere(
      (opt) => opt['value'] == _reminderLeadTime,
      orElse: () => options.first,
    );

    return InkWell(
      onTap: () => _showReminderPicker(l10n),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: context.appSurfaceColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedOption['label'] as String,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.appTextPrimary,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_right_rounded,
              color: context.appTextSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesInput(AppLocalizations l10n) {
    return TextField(
      controller: _notesController,
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
