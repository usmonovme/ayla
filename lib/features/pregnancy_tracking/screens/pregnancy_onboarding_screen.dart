import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/platform_wrapper.dart';
import '../../../core/widgets/unit_toggle.dart';
import '../../../core/widgets/ruler_slider.dart';
import '../../../core/widgets/range_calendar.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/pregnancy_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';
import '../../auth/widgets/auth_screen_background.dart';
import '../../auth/models/user_model.dart';
import '../../gamification/providers/gamification_provider.dart';
import '../../gamification/widgets/badge_celebration.dart';
import '../../../core/services/analytics_service.dart';

class PregnancyOnboardingScreen extends StatefulWidget {
  const PregnancyOnboardingScreen({super.key});

  @override
  State<PregnancyOnboardingScreen> createState() =>
      _PregnancyOnboardingScreenState();
}

class _PregnancyOnboardingScreenState extends State<PregnancyOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;
  static const double _bottomActionBaseHeight = 80;

  DateTime _lmp = DateTime.now().subtract(const Duration(days: 28));
  late double _heightValue;
  late double _weightValue;
  late LengthUnit _selectedLengthUnit;
  late WeightUnit _selectedWeightUnit;

  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    // Normalize LMP to midnight
    _lmp = DateTime(_lmp.year, _lmp.month, _lmp.day);

    final prefs = context.read<AuthProvider>().userProfile?.preferences;
    _selectedLengthUnit = prefs?.lengthUnit ?? LengthUnit.cm;
    _selectedWeightUnit = prefs?.weightUnit ?? WeightUnit.kg;

    // Set initial values based on units
    if (_selectedLengthUnit == LengthUnit.inch) {
      _heightValue = 65.0; // ~165 cm
    } else {
      _heightValue = 165.0;
    }

    if (_selectedWeightUnit == WeightUnit.lbs) {
      _weightValue = 140.0; // ~63.5 kg
    } else {
      _weightValue = 65.0;
    }
    
    // Log start of pregnancy onboarding
    AnalyticsService.instance.logPregnancyOnboardingStart();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleLengthUnit(LengthUnit unit) {
    if (_selectedLengthUnit == unit) return;
    setState(() {
      _selectedLengthUnit = unit;
      if (unit == LengthUnit.inch) {
        _heightValue = (_heightValue / 2.54).clamp(40.0, 95.0);
      } else {
        _heightValue = (_heightValue * 2.54).clamp(100.0, 240.0);
      }
    });
  }

  void _toggleWeightUnit(WeightUnit unit) {
    if (_selectedWeightUnit == unit) return;
    setState(() {
      _selectedWeightUnit = unit;
      if (unit == WeightUnit.lbs) {
        _weightValue = (_weightValue * 2.20462).clamp(66.0, 440.0);
      } else {
        _weightValue = (_weightValue * 0.453592).clamp(30.0, 200.0);
      }
    });
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _startTracking();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _startTracking() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final pregnancyProvider = context.read<PregnancyProvider>();
      final gamification = context.read<GamificationProvider>();
      final userId = authProvider.firebaseUser!.uid;
      await pregnancyProvider.startPregnancy(
        userId,
        _lmp,
        initialWeight: _weightValue,
        height: _heightValue,
      );

      // Check badges before marking onboarding complete
      if (mounted) {
        try {
          if (!gamification.isInitialized) {
            await gamification.initialize(userId);
          }
          final pregnancyId = pregnancyProvider.pregnancy?.id;
          if (pregnancyId != null) {
            final newBadges = await gamification.checkBadgeUnlocks(
              AppMode.pregnancyTracking,
              contextId: pregnancyId,
            );
            if (mounted && newBadges.isNotEmpty) {
              await showBadgeCelebration(context, newBadges);
            }
          }
        } catch (_) {
          // Badge checking is non-critical
        }
      }

      // Mark onboarding as completed & persist final unit options
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        if (authProvider.userProfile != null) {
          await authProvider.updateUserPreferences(
            authProvider.userProfile!.preferences.copyWith(
              hasCompletedPregnancyOnboarding: true,
              lengthUnit: _selectedLengthUnit,
              weightUnit: _selectedWeightUnit,
            ),
          );
          // Log pregnancy onboarding completion
          AnalyticsService.instance.logPregnancyOnboardingComplete();
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        PlatformUI.showMessage(context, message: 'Error: $e', isError: true);
      }
    }
  }

  Future<void> _skipOnboarding() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.userProfile != null) {
        await authProvider.updateUserPreferences(
          authProvider.userProfile!.preferences.copyWith(
            hasCompletedPregnancyOnboarding: true,
          ),
        );
        // Log pregnancy onboarding completion (even if skipped)
        AnalyticsService.instance.logPregnancyOnboardingComplete();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        PlatformUI.showMessage(context, message: 'Error: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    const bool canContinue = true; // Sliders are always valid

    return PlatformScaffold(
      body: AuthScreenBackground(
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildTopBar(l10n),
                  _buildProgressBar(),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: _bottomActionsHeight(context),
                      ),
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (index) =>
                            setState(() => _currentStep = index),
                        children: [
                          _buildStepLmp(l10n, isIOS),
                          _buildStepHeight(l10n),
                          _buildStepWeight(l10n),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomActions(l10n, canContinue),
            ),
          ],
        ),
      ),
    );
  }

  double _bottomActionsHeight(BuildContext context) {
    return _bottomActionBaseHeight + MediaQuery.of(context).padding.bottom;
  }

  Widget _buildTopBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedOpacity(
            opacity: _currentStep > 0 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Semantics(
              label: 'Back',
              button: true,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _currentStep > 0 ? _prevStep : null,
                  borderRadius: BorderRadius.circular(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? AppTheme.darkSurfaceColor.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: context.isDarkMode
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: context.appTextPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              l10n.preg_onboarding_title,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: context.appTextPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 46, height: 46),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isCompletedOrCurrent = index <= _currentStep;
          return Expanded(
            child: Container(
              height: 6,
              margin: EdgeInsets.only(
                right: index < _totalSteps - 1 ? 6.0 : 0.0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isCompletedOrCurrent
                    ? AppTheme.pregnancyPrimary
                    : AppTheme.pregnancyPrimary.withValues(alpha: 0.15),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepLmp(AppLocalizations l10n, bool isIOS) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final minDate = today.subtract(const Duration(days: 300));

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 16),
        Text(
          l10n.preg_onboarding_q,
          style: GoogleFonts.nunito(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: context.appTextPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.preg_onboarding_q_desc,
          style: GoogleFonts.nunito(
            fontSize: 16,
            color: context.appTextSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),

        GlassCard(
          padding: const EdgeInsets.all(12),
          borderRadius: 24,
          child: RangeCalendar(
            selectedDate: _lmp,
            duration: 1,
            minDate: minDate,
            maxDate: today,
            primaryColor: AppTheme.pregnancyPrimary,
            onDateChanged: (date) => setState(() => _lmp = date),
          ),
        ),
      ],
    );
  }

  Widget _buildStepHeight(AppLocalizations l10n) {
    final bool isCm = _selectedLengthUnit == LengthUnit.cm;
    final double minHeight = isCm ? 100.0 : 40.0;
    final double maxHeight = isCm ? 240.0 : 95.0;

    // Converted ft/in format for Imperial height display
    String ftInDisplay = '';
    if (!isCm) {
      final feet = (_heightValue / 12).floor();
      final inches = (_heightValue % 12).round();
      ftInDisplay = '$feet ft $inches in';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 16),
        Text(
          l10n.preg_onboarding_height_title,
          style: GoogleFonts.nunito(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: context.appTextPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.preg_onboarding_height_desc,
          style: GoogleFonts.nunito(
            fontSize: 16,
            color: context.appTextSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),

        GlassCard(
          padding: const EdgeInsets.all(24),
          borderRadius: 28,
          child: Column(
            children: [
              // Unit Toggle capsule at top right/center
              Center(
                child: UnitToggle<LengthUnit>(
                  selectedValue: _selectedLengthUnit,
                  options: const {
                    LengthUnit.cm: 'cm',
                    LengthUnit.inch: 'inches',
                  },
                  onSelected: _toggleLengthUnit,
                ),
              ),
              const SizedBox(height: 32),

              // Giant Value Display
              Column(
                children: [
                  Text(
                    isCm ? '${_heightValue.round()} cm' : ftInDisplay,
                    style: GoogleFonts.nunito(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.pregnancyPrimary,
                    ),
                  ),
                  if (!isCm) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${_heightValue.toStringAsFixed(1)}"',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // Slider flanked by +/- buttons with premium spacing
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIncrementButton(
                    icon: Icons.remove,
                    onTap: () {
                      setState(() {
                        _heightValue = (_heightValue - 1.0).clamp(
                          minHeight,
                          maxHeight,
                        );
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: RulerSlider(
                      value: _heightValue,
                      min: minHeight,
                      max: maxHeight,
                      step: 1.0,
                      tickStep: 1.0,
                      pixelsPerUnit: isCm ? 10.0 : 12.0,
                      onChanged: (val) {
                        setState(() => _heightValue = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildIncrementButton(
                    icon: Icons.add,
                    onTap: () {
                      setState(() {
                        _heightValue = (_heightValue + 1.0).clamp(
                          minHeight,
                          maxHeight,
                        );
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepWeight(AppLocalizations l10n) {
    final bool isKg = _selectedWeightUnit == WeightUnit.kg;
    final double minWeight = isKg ? 30.0 : 66.0;
    final double maxWeight = isKg ? 200.0 : 440.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 16),
        Text(
          l10n.preg_onboarding_weight_title,
          style: GoogleFonts.nunito(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: context.appTextPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.preg_onboarding_weight_desc,
          style: GoogleFonts.nunito(
            fontSize: 16,
            color: context.appTextSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),

        GlassCard(
          padding: const EdgeInsets.all(24),
          borderRadius: 28,
          child: Column(
            children: [
              // Unit Toggle
              Center(
                child: UnitToggle<WeightUnit>(
                  selectedValue: _selectedWeightUnit,
                  options: const {WeightUnit.kg: 'kg', WeightUnit.lbs: 'lbs'},
                  onSelected: _toggleWeightUnit,
                ),
              ),
              const SizedBox(height: 32),

              // Giant Value Display
              Text(
                '${_weightValue.toStringAsFixed(1)} ${_selectedWeightUnit.name.toLowerCase()}',
                style: GoogleFonts.nunito(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.pregnancyPrimary,
                ),
              ),
              const SizedBox(height: 32),

              // Slider flanked by +/- buttons with premium spacing
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIncrementButton(
                    icon: Icons.remove,
                    onTap: () {
                      setState(() {
                        _weightValue = (_weightValue - 0.1).clamp(
                          minWeight,
                          maxWeight,
                        );
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: RulerSlider(
                      value: _weightValue,
                      min: minWeight,
                      max: maxWeight,
                      step: 0.1,
                      tickStep: 0.5,
                      pixelsPerUnit: isKg ? 30.0 : 20.0,
                      onChanged: (val) {
                        setState(() => _weightValue = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildIncrementButton(
                    icon: Icons.add,
                    onTap: () {
                      setState(() {
                        _weightValue = (_weightValue + 0.1).clamp(
                          minWeight,
                          maxWeight,
                        );
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIncrementButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return BouncingIconButton(icon: icon, onTap: onTap);
  }

  Widget _buildBottomActions(AppLocalizations l10n, bool canContinue) {
    final isDark = context.isDarkMode;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.darkSurfaceColor.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.4),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              if (_currentStep == 0) ...[
                _GlassSkipButton(
                  text: l10n.onboarding_skip,
                  onPressed: _isLoading ? null : _skipOnboarding,
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: _PremiumButton(
                  text: _currentStep == _totalSteps - 1
                      ? l10n.preg_onboarding_btn
                      : l10n.onboarding_continue,
                  onPressed: (_isLoading || !canContinue) ? null : _nextStep,
                  isLoading: _isLoading,
                  isSuccess: _isSuccess,
                  primaryColor: AppTheme.pregnancyPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSuccess;
  final Color primaryColor;

  const _PremiumButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isSuccess = false,
    required this.primaryColor,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    return Semantics(
      button: true,
      label: widget.text,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed && !isDisabled ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: isDisabled
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.primaryColor,
                            widget.primaryColor.withValues(alpha: 0.85),
                            widget.primaryColor.withValues(alpha: 0.7),
                          ],
                        ),
                  color: isDisabled ? Colors.grey.withValues(alpha: 0.3) : null,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: isDisabled
                      ? null
                      : [
                          BoxShadow(
                            color: widget.primaryColor.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: widget.isSuccess
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 28,
                            key: ValueKey('success'),
                          )
                        : widget.isLoading
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            widget.text,
                            key: const ValueKey('text'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GlassSkipButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const _GlassSkipButton({required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Semantics(
      button: true,
      label: text,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkSurfaceColor.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.8),
              ),
            ),
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.appTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BouncingIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const BouncingIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  State<BouncingIconButton> createState() => _BouncingIconButtonState();
}

class _BouncingIconButtonState extends State<BouncingIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.86,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? AppTheme.pregnancyPrimary.withValues(alpha: 0.15)
                : AppTheme.pregnancyPrimary.withValues(alpha: 0.08),
            border: Border.all(
              color: AppTheme.pregnancyPrimary.withValues(alpha: 0.2),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.pregnancyPrimary.withValues(
                  alpha: isDark ? 0.03 : 0.08,
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(widget.icon, size: 20, color: AppTheme.pregnancyPrimary),
        ),
      ),
    );
  }
}
