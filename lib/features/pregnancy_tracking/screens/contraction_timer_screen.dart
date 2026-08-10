import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../gamification/providers/gamification_provider.dart';
import '../../auth/models/user_model.dart';
import '../providers/pregnancy_provider.dart';
import '../providers/labor_provider.dart';
import '../models/contraction_model.dart';
import '../../../core/widgets/glass_card.dart';
import '../../gamification/widgets/badge_celebration.dart';
import '../../../core/theme/theme_extension.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const _kRose = Color(0xFFE8909C); // active / trimester1Primary
const _kDeep = Color(0xFFC0606E);
const _kPurple = Color(0xFF9381FF); // idle / primaryColor
const _kAmber = Color(0xFFF4A261); // 5-1-1 warning

class ContractionTimerScreen extends StatefulWidget {
  const ContractionTimerScreen({super.key});

  @override
  State<ContractionTimerScreen> createState() => _ContractionTimerScreenState();
}

class _ContractionTimerScreenState extends State<ContractionTimerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ── Pulse rings (idle) ────────────────────────────────────────────────────
  late AnimationController _idlePulseCtrl;

  // ── Active contraction: expanding ripples ─────────────────────────────────
  late AnimationController _rippleCtrl;

  // ── Button heartbeat scale ────────────────────────────────────────────────
  late AnimationController _heartbeatCtrl;
  late Animation<double> _heartbeatAnim;

  // ── ECG waveform scroll ───────────────────────────────────────────────────
  late AnimationController _ecgCtrl;

  // ── Warning banner slide ──────────────────────────────────────────────────
  late AnimationController _bannerCtrl;
  late Animation<Offset> _bannerSlide;
  late Animation<double> _bannerOpacity;
  bool _was511 = false;

  late LaborProvider _laborProvider;
  Timer? _hideIntensityTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _idlePulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _heartbeatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _heartbeatAnim = Tween<double>(
      begin: 1.0,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _heartbeatCtrl, curve: Curves.easeInOut));

    _ecgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    )..repeat();

    _bannerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bannerSlide = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _bannerCtrl, curve: Curves.easeOutBack));
    _bannerOpacity = CurvedAnimation(parent: _bannerCtrl, curve: Curves.easeIn);

    _laborProvider = context.read<LaborProvider>();
    _laborProvider.addListener(_onProviderChange);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _laborProvider.removeListener(_onProviderChange);
    _hideIntensityTimer?.cancel();

    _idlePulseCtrl.dispose();
    _rippleCtrl.dispose();
    _heartbeatCtrl.dispose();
    _ecgCtrl.dispose();
    _bannerCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _idlePulseCtrl.stop(canceled: false);
      _rippleCtrl.stop(canceled: false);
      _heartbeatCtrl.stop(canceled: false);
      _ecgCtrl.stop(canceled: false);
    } else if (state == AppLifecycleState.resumed) {
      if (!_idlePulseCtrl.isAnimating) _idlePulseCtrl.repeat();
      if (!_rippleCtrl.isAnimating) _rippleCtrl.repeat();
      if (!_heartbeatCtrl.isAnimating) _heartbeatCtrl.repeat(reverse: true);
      if (!_ecgCtrl.isAnimating) _ecgCtrl.repeat();
    }
  }

  void _onProviderChange() {
    if (!mounted) return;

    _checkBannerState(_laborProvider.meets511Rule);

    if (_laborProvider.isActive) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }

    _hideIntensityTimer?.cancel();
    if (!_laborProvider.isActive &&
        _laborProvider.contractions.isNotEmpty &&
        _laborProvider.contractions.first.endTime != null &&
        _laborProvider.contractions.first.intensity == null) {
      final endTime = _laborProvider.contractions.first.endTime!;
      final diff = DateTime.now().difference(endTime);
      if (diff.inSeconds < 120) {
        final remaining = const Duration(minutes: 2) - diff;
        _hideIntensityTimer = Timer(remaining, () {
          if (mounted) setState(() {});
        });
      }
    }
  }

  void _checkBannerState(bool meets511) {
    if (meets511 && !_was511) {
      _bannerCtrl.forward();
    } else if (!meets511 && _was511) {
      _bannerCtrl.reverse();
    }
    _was511 = meets511;
  }

  // ── Text helpers ──────────────────────────────────────────────────────────
  String _fmtDuration(Duration d, AppLocalizations l10n) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    if (mins > 0 && secs > 0) {
      return l10n.contraction_timer_duration_text(mins, secs);
    }
    if (mins > 0) {
      return l10n
          .contraction_timer_duration_text(mins, 0)
          .replaceAll(RegExp(r'\s+0\S*$'), '');
    }
    return l10n.contraction_timer_seconds_text(secs);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<LaborProvider>();
    final active = provider.activeContraction;
    final isActive = provider.isActive;
    final meets511 = provider.meets511Rule;

    final orbColor = isActive ? _kRose : _kPurple;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: BrandedAppBar(
        isPregnancy: true,
        title: Text(l10n.contraction_timer_title),
      ),
      body: Stack(
        children: [
          // ── Background ────────────────────────────────────────────────
          _AnimatedBackground(
            isActive: isActive,
            rippleCtrl: _rippleCtrl,
            idlePulseCtrl: _idlePulseCtrl,
            orbColor: orbColor,
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Minimum adaptive padding to ensure items don't clamp together
                final double vPadding = constraints.maxHeight * 0.05;

                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.spacingLarge,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Status bar (labor phase) — only shown when 5-1-1 is met
                              if (meets511) ...[
                                _StatusBanner(
                                  provider: provider,
                                  l10n: l10n,
                                  isActive: isActive,
                                  meets511: meets511,
                                ),
                                const SizedBox(height: 12),
                              ],
                              // ECG waveform
                              _EcgStrip(
                                ecgCtrl: _ecgCtrl,
                                isActive: isActive,
                                color: orbColor,
                                contractions: provider.contractions,
                                activeStartTime: active?.startTime,
                                meets511: meets511,
                              ),
                            ],
                          ),

                          SizedBox(height: vPadding),

                          // Central orb button
                          _OrbButton(
                            isActive: isActive,
                            active: active,
                            heartbeatAnim: _heartbeatAnim,
                            orbColor: orbColor,
                            l10n: l10n,
                            onTap: () async {
                              HapticFeedback.heavyImpact();
                              if (isActive) {
                                provider.stopAndSaveContraction();
                                final pregnancyId = context
                                    .read<PregnancyProvider>()
                                    .pregnancy
                                    ?.id;
                                final gamification = context
                                    .read<GamificationProvider>();
                                final newBadges = await gamification
                                    .checkBadgeUnlocks(
                                      AppMode.pregnancyTracking,
                                      contextId: pregnancyId,
                                    );
                                if (context.mounted && newBadges.isNotEmpty) {
                                  await showBadgeCelebration(
                                    context,
                                    newBadges,
                                  );
                                }
                              } else {
                                provider.startContraction(l10n);
                              }
                            },
                          ),

                          SizedBox(height: vPadding),

                          // Bottom card: intensity picker OR stats + history
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.paddingLarge,
                            ),
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOutCubic,
                              child: _bottomSection(provider, l10n),
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

          // ── 5-1-1 warning slide-in ────────────────────────────────────
          if (meets511 || _bannerCtrl.value > 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
              left: AppConstants.paddingLarge,
              right: AppConstants.paddingLarge,
              child: FadeTransition(
                opacity: _bannerOpacity,
                child: SlideTransition(
                  position: _bannerSlide,
                  child: _AlertBanner(l10n: l10n),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bottomSection(LaborProvider provider, AppLocalizations l10n) {
    final needsIntensity =
        !provider.isActive &&
        provider.contractions.isNotEmpty &&
        provider.contractions.first.intensity == null &&
        provider.contractions.first.endTime != null &&
        DateTime.now()
                .difference(provider.contractions.first.endTime!)
                .inMinutes <
            2;

    if (needsIntensity) {
      return _IntensityPicker(provider: provider, l10n: l10n);
    }
    return _StatsAndHistory(
      provider: provider,
      l10n: l10n,
      fmtDuration: _fmtDuration,
    );
  }
}

// ─── Animated Background ──────────────────────────────────────────────────────
class _AnimatedBackground extends StatelessWidget {
  final bool isActive;
  final AnimationController rippleCtrl;
  final AnimationController idlePulseCtrl;
  final Color orbColor;

  const _AnimatedBackground({
    required this.isActive,
    required this.rippleCtrl,
    required this.idlePulseCtrl,
    required this.orbColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: isActive ? rippleCtrl : idlePulseCtrl,
      builder: (context, child) {
        final t = isActive ? rippleCtrl.value : idlePulseCtrl.value;
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: context.appBackgroundGradient),
          child: Stack(
            children: [
              // Top blob
              Positioned(
                top: -120,
                right: -80,
                child: Container(
                  width: 340 + sin(t * pi * 2) * 20,
                  height: 340 + sin(t * pi * 2) * 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: orbColor.withValues(
                      alpha: isActive ? 0.14 + sin(t * pi * 2) * 0.04 : 0.08,
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              // Bottom blob
              Positioned(
                bottom: -80,
                left: -60,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.trimester3Primary.withValues(alpha: 0.08),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Status Banner ────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final LaborProvider provider;
  final AppLocalizations l10n;
  final bool isActive;
  final bool meets511;

  const _StatusBanner({
    required this.provider,
    required this.l10n,
    required this.isActive,
    required this.meets511,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = meets511
        ? _kAmber
        : isActive
        ? _kRose
        : AppTheme.primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLarge,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.appSurfaceColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Pulsing dot
            _PulsingDot(color: statusColor, active: isActive || meets511),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.laborStatus(l10n),
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: context.appTextPrimary,
                    ),
                  ),
                  if (isActive)
                    Text(
                      l10n.contraction_timer_breathe,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                ],
              ),
            ),
            // Phase chip, visible only for 5-1-1 state
            if (meets511)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  meets511 ? '5-1-1 ✓' : l10n.contraction_timer_stop_upper,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  final bool active;
  const _PulsingDot({required this.color, required this.active});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(
      begin: 0.8,
      end: 1.4,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.active) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingDot old) {
    super.didUpdateWidget(old);
    if (widget.active && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.active && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final s = widget.active ? _scale.value : 1.0;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            if (widget.active)
              Container(
                width: 20 * s,
                height: 20 * s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.2 / s),
                ),
              ),
            // Solid dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── ECG Waveform strip ───────────────────────────────────────────────────────
class _EcgStrip extends StatelessWidget {
  final AnimationController ecgCtrl;
  final bool isActive;
  final Color color;
  final List<ContractionEntry> contractions;
  final DateTime? activeStartTime;
  final bool meets511;

  const _EcgStrip({
    required this.ecgCtrl,
    required this.isActive,
    required this.color,
    required this.contractions,
    required this.activeStartTime,
    required this.meets511,
  });

  @override
  Widget build(BuildContext context) {
    final signal = _EcgSignalModel.fromContractions(
      contractions,
      isActive: isActive,
      activeStartTime: activeStartTime,
      meets511: meets511,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLarge,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: context.appSurfaceColor.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.appBorderColor),
          ),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: ecgCtrl,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _EcgPainter(
                      progress: ecgCtrl.value,
                      isActive: isActive,
                      color: color,
                      isDark: context.isDarkMode,
                      intensity01: signal.intensity01,
                      cyclesVisible: signal.cyclesVisible,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EcgSignalModel {
  final double intensity01;
  final double cyclesVisible;

  const _EcgSignalModel({
    required this.intensity01,
    required this.cyclesVisible,
  });

  static double _intensityScore(ContractionIntensity? intensity) {
    switch (intensity) {
      case ContractionIntensity.mild:
        return 0.34;
      case ContractionIntensity.moderate:
        return 0.66;
      case ContractionIntensity.strong:
        return 1.0;
      default:
        return 0.0;
    }
  }

  static double _weightedIntensity(List<ContractionEntry> contractions) {
    double weighted = 0.0;
    double weightSum = 0.0;
    int seen = 0;
    for (final c in contractions) {
      if (c.endTime == null || c.intensity == null) continue;
      final w = pow(0.68, seen).toDouble();
      weighted += _intensityScore(c.intensity) * w;
      weightSum += w;
      seen++;
      if (seen >= 8) break;
    }
    if (weightSum == 0) return 0.0;
    return weighted / weightSum;
  }

  static double _avgFrequencyMinutes(List<ContractionEntry> contractions) {
    final completed = contractions
        .where((c) => c.endTime != null)
        .take(8)
        .toList();
    if (completed.length < 2) return 5.5;

    double total = 0.0;
    int count = 0;
    for (int i = 0; i < completed.length - 1; i++) {
      final diff = completed[i].startTime.difference(
        completed[i + 1].startTime,
      );
      final mins = diff.inSeconds.abs() / 60.0;

      // If gap exceeds threshold, stop averaging further back
      if (diff.abs() > AppConstants.contractionSessionThreshold) {
        break;
      }

      if (mins <= 0) continue;
      total += mins;
      count++;
    }
    if (count == 0) return 5.5;
    return total / count;
  }

  factory _EcgSignalModel.fromContractions(
    List<ContractionEntry> contractions, {
    required bool isActive,
    required DateTime? activeStartTime,
    required bool meets511,
  }) {
    var intensity = _weightedIntensity(contractions);
    if (intensity == 0.0) {
      intensity = isActive ? 0.58 : 0.38;
    }

    if (isActive && activeStartTime != null) {
      final activeMinutes =
          DateTime.now().difference(activeStartTime).inSeconds / 60.0;
      final ramp = (1 - exp(-activeMinutes / 8.0)) * 0.10;
      intensity += ramp;
    }
    if (meets511) intensity += 0.08;
    intensity = intensity.clamp(0.22, 1.0);

    final avgFreqMin = _avgFrequencyMinutes(contractions);
    final cadenceNorm = ((avgFreqMin - 2.0) / 8.0).clamp(0.0, 1.0);
    final visualPeriod =
        ((0.78 + cadenceNorm * 0.92) * (1.08 - intensity * 0.20)).clamp(
          0.65,
          2.0,
        );
    final cyclesVisible = (5.4 / visualPeriod).clamp(2.0, 5.4);

    return _EcgSignalModel(
      intensity01: intensity,
      cyclesVisible: cyclesVisible,
    );
  }
}

class _EcgPainter extends CustomPainter {
  final double progress;
  final bool isActive;
  final Color color;
  final bool isDark;
  final double intensity01;
  final double cyclesVisible;

  _EcgPainter({
    required this.progress,
    required this.isActive,
    required this.color,
    required this.isDark,
    required this.intensity01,
    required this.cyclesVisible,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07)
      ..strokeWidth = 1;

    final mid = size.height / 2;
    canvas.drawLine(Offset(0, mid), Offset(size.width, mid), gridPaint);
    canvas.drawLine(
      Offset(0, size.height * 0.25),
      Offset(size.width, size.height * 0.25),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.75),
      Offset(size.width, size.height * 0.75),
      gridPaint,
    );

    final linePaint = Paint()
      ..color = color.withValues(alpha: isActive ? 0.9 : 0.35)
      ..strokeWidth = isActive ? 2.0 : 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: isActive ? 0.25 : 0.0)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    final double sweep = isActive ? progress : (progress * 0.45) % 1.0;
    final double visible = isActive ? cyclesVisible : (1.5 + intensity01 * 0.8);

    const totalPts = 620;
    double? prevY;
    for (int i = 0; i <= totalPts; i++) {
      final xRatio = i / totalPts;
      final x = size.width * xRatio;
      final phase = ((xRatio + sweep) * visible) % 1.0;
      var y = isActive
          ? (xRatio <= progress
                ? _activeWaveY(phase, mid, size.height, intensity01)
                : mid)
          : _idleWaveY(phase, mid, intensity01);

      /* legacy waveform branch removed
      if (isActive) {
        // Sharp ECG spike: flat → P wave → QRS complex → T wave
        if (cyclePos < 0.1) {
          y = mid - sin(cyclePos / 0.1 * pi) * 4; // P
        } else if (cyclePos < 0.25) {
          y = mid;
        } else if (cyclePos < 0.28) {
          y = mid + (cyclePos - 0.25) / 0.03 * 8; // Q dip
        } else if (cyclePos < 0.32) {
          y =
              mid +
              8 -
              (cyclePos - 0.28) / 0.04 * (8 + size.height * 0.4); // R up
        } else if (cyclePos < 0.36) {
          y =
              mid -
              size.height * 0.4 +
              (cyclePos - 0.32) / 0.04 * (size.height * 0.4 + 12); // S
        } else if (cyclePos < 0.4) {
          y = mid + 12 - (cyclePos - 0.36) / 0.04 * 12; // back to mid
        } else if (cyclePos < 0.55) {
          y = mid - sin((cyclePos - 0.4) / 0.15 * pi) * 6; // T wave
        }
      } else {
        // Gentle sine for idle
        y =
            mid -
            (sin(sampleT * 1.8) * 3.2 +
                sin(sampleT * 4.3 + rawX * pi) * 1.6 +
                sin(sampleT * 8.5) * 0.9);
      }

      */
      if (prevY != null) {
        final keep = isActive ? 0.64 : 0.56;
        y = prevY * keep + y * (1.0 - keep);
      }
      prevY = y;
      final clampedY = y.clamp(3.0, size.height - 3.0).toDouble();

      if (i == 0) {
        path.moveTo(x, clampedY);
      } else {
        path.lineTo(x, clampedY);
      }
    }

    if (isActive) canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);

    // Scanning head dot moving across the strip
    if (isActive) {
      final dotX = size.width * progress;
      final dotPhase = ((progress + sweep) * visible) % 1.0;
      final dotY = _activeWaveY(
        dotPhase,
        mid,
        size.height,
        intensity01,
      ).clamp(3.0, size.height - 3.0).toDouble();

      canvas.drawCircle(Offset(dotX, dotY), 4, Paint()..color = color);
      canvas.drawCircle(
        Offset(dotX, dotY),
        8,
        Paint()..color = color.withValues(alpha: 0.2),
      );
    }
  }

  double _activeWaveY(double p, double mid, double height, double intensity) {
    final pAmp = 1.0 + 1.6 * intensity;
    final qAmp = 1.6 + 2.0 * intensity;
    final rAmp = height * (0.12 + 0.12 * intensity);
    final sAmp = 2.8 + 3.2 * intensity;
    final tAmp = 1.2 + 2.0 * intensity;

    final pWave = _gaussCycle(p, 0.09, 0.022) * pAmp;
    final qWave = _gaussCycle(p, 0.206, 0.013) * qAmp;
    final rWave = _gaussCycle(p, 0.24, 0.014) * rAmp;
    final sWave = _gaussCycle(p, 0.286, 0.016) * sAmp;
    final tWave = _gaussCycle(p, 0.45, 0.056) * tAmp;

    return mid - pWave + qWave - rWave + sWave - tWave;
  }

  double _idleWaveY(double p, double mid, double intensity) {
    final amp = 1.6 + 1.2 * intensity;
    return mid - sin(p * pi * 2) * amp - sin(p * pi * 4) * (amp * 0.28);
  }

  double _gaussCycle(double p, double center, double sigma) {
    final d = _cyclicDistance(p, center);
    return exp(-(d * d) / (2 * sigma * sigma));
  }

  double _cyclicDistance(double a, double b) {
    final direct = (a - b).abs();
    return min(direct, 1.0 - direct);
  }

  @override
  bool shouldRepaint(_EcgPainter old) =>
      old.progress != progress ||
      old.isActive != isActive ||
      old.color != color ||
      old.isDark != isDark ||
      old.intensity01 != intensity01 ||
      old.cyclesVisible != cyclesVisible;
}

// ─── Central Orb Button ───────────────────────────────────────────────────────
class _OrbButton extends StatelessWidget {
  final bool isActive;
  final ContractionEntry? active;
  final Animation<double> heartbeatAnim;
  final Color orbColor;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _OrbButton({
    required this.isActive,
    required this.active,
    required this.heartbeatAnim,
    required this.orbColor,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ScaleTransition(
        scale: isActive ? heartbeatAnim : const AlwaysStoppedAnimation(1.0),
        child: Container(
          width: 230,
          height: 230,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: isActive
                  ? [_kRose.withValues(alpha: 0.9), _kDeep]
                  : [
                      AppTheme.primaryColor.withValues(alpha: 0.85),
                      AppTheme.primaryColor,
                    ],
              center: const Alignment(-0.3, -0.35),
              radius: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: orbColor.withValues(alpha: isActive ? 0.55 : 0.35),
                blurRadius: isActive ? 50 : 28,
                spreadRadius: isActive ? 16 : 6,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(-6, -6),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: isActive && active != null
                ? _ActiveContent(startTime: active!.startTime, l10n: l10n)
                : _IdleContent(l10n: l10n),
          ),
        ),
      ),
    );
  }
}

class _IdleContent extends StatelessWidget {
  final AppLocalizations l10n;
  const _IdleContent({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.touch_app_rounded,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.contraction_timer_start_upper,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }
}

class _ActiveContent extends StatelessWidget {
  final DateTime startTime;
  final AppLocalizations l10n;
  const _ActiveContent({required this.startTime, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LiveTimer(startTime: startTime),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Text(
            l10n.contraction_timer_stop_upper,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveTimer extends StatefulWidget {
  final DateTime startTime;
  const _LiveTimer({required this.startTime});

  @override
  State<_LiveTimer> createState() => _LiveTimerState();
}

class _LiveTimerState extends State<_LiveTimer> {
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _update();
    });
  }

  @override
  void didUpdateWidget(_LiveTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startTime != oldWidget.startTime) {
      _update();
    }
  }

  void _update() {
    setState(() => _elapsed = DateTime.now().difference(widget.startTime));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes.remainder(60);
    final s = _elapsed.inSeconds.remainder(60);
    final str = h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';

    return Text(
      str,
      style: GoogleFonts.nunito(
        fontSize: 52,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        height: 1,
        letterSpacing: -1,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

// ─── Intensity Picker ─────────────────────────────────────────────────────────
class _IntensityPicker extends StatelessWidget {
  final LaborProvider provider;
  final AppLocalizations l10n;
  const _IntensityPicker({required this.provider, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.monitor_heart_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.contraction_timer_how_was_it,
                style: GoogleFonts.nunito(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: context.appTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Options
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _IntensityTile(
                  provider: provider,
                  intensity: ContractionIntensity.mild,
                  label: l10n.contraction_timer_mild,
                  icon: Icons.sentiment_satisfied_alt_rounded,
                  color: const Color(0xFF4CAF50),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                const SizedBox(width: 8),
                _IntensityTile(
                  provider: provider,
                  intensity: ContractionIntensity.moderate,
                  label: l10n.contraction_timer_moderate,
                  icon: Icons.sentiment_neutral_rounded,
                  color: _kAmber,
                  gradient: const LinearGradient(
                    colors: [_kAmber, Color(0xFFE67E22)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                const SizedBox(width: 8),
                _IntensityTile(
                  provider: provider,
                  intensity: ContractionIntensity.strong,
                  label: l10n.contraction_timer_strong,
                  icon: Icons.sentiment_very_dissatisfied_rounded,
                  color: _kRose,
                  gradient: const LinearGradient(
                    colors: [_kRose, _kDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IntensityTile extends StatefulWidget {
  final LaborProvider provider;
  final ContractionIntensity intensity;
  final String label;
  final IconData icon;
  final Color color;
  final LinearGradient gradient;
  const _IntensityTile({
    required this.provider,
    required this.intensity,
    required this.label,
    required this.icon,
    required this.color,
    required this.gradient,
  });

  @override
  State<_IntensityTile> createState() => _IntensityTileState();
}

class _IntensityTileState extends State<_IntensityTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.92,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _tap() async {
    HapticFeedback.mediumImpact();
    _ctrl.reverse();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (mounted) _ctrl.forward();
    widget.provider.updateLastContractionIntensity(widget.intensity);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          onTap: _tap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: Colors.white, size: 30),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Stats + contraction timeline ────────────────────────────────────────────
class _StatsAndHistory extends StatelessWidget {
  final LaborProvider provider;
  final AppLocalizations l10n;
  final String Function(Duration, AppLocalizations) fmtDuration;

  const _StatsAndHistory({
    required this.provider,
    required this.l10n,
    required this.fmtDuration,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.contractions.isEmpty) {
      final color = provider.isActive ? _kRose : AppTheme.primaryColor;
      return GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Icon(
                provider.isActive
                    ? Icons.timelapse_rounded
                    : Icons.monitor_heart_outlined,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              provider.isActive
                  ? l10n.common_ongoing
                  : l10n.contraction_timer_ready,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              provider.isActive
                  ? l10n.contraction_timer_breathe
                  : l10n.contraction_timer_empty,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.appTextSecondary.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    provider.isActive
                        ? Icons.stop_circle_outlined
                        : Icons.touch_app_rounded,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    provider.isActive
                        ? l10n.contraction_timer_stop_upper
                        : l10n.contraction_timer_start_upper,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Stats row
    final last = provider.contractions.first;
    final durationText = last.endTime != null
        ? fmtDuration(last.duration, l10n)
        : '–';

    String frequencyText = '--';
    if (provider.contractions.length > 1) {
      final diff = provider.contractions[0].startTime.difference(
        provider.contractions[1].startTime,
      );
      if (diff.abs() <= AppConstants.contractionSessionThreshold) {
        frequencyText = fmtDuration(diff, l10n);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Stats glass row ──────────────────────────────────────────────
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          borderRadius: 20,
          child: Row(
            children: [
              _StatCell(
                icon: Icons.timer_rounded,
                label: l10n.contraction_timer_duration,
                value: durationText,
                color: _kRose,
              ),
              Container(
                width: 1,
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: context.appDividerColor,
              ),
              _StatCell(
                icon: Icons.compress_rounded,
                label: l10n.contraction_timer_frequency,
                value: frequencyText,
                color: AppTheme.primaryColor,
              ),
              Container(
                width: 1,
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: context.appDividerColor,
              ),
              _StatCell(
                icon: Icons.format_list_numbered_rounded,
                label: l10n.contraction_timer_count,
                value: '${provider.contractions.length}',
                color: AppTheme.trimester3Primary,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Contraction timeline bars ────────────────────────────────────
        _ContractionTimeline(
          contractions: provider.contractions.take(3).toList(),
          fmtDuration: fmtDuration,
          l10n: l10n,
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: context.appTextPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: context.appTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Contraction Timeline ─────────────────────────────────────────────────────
class _ContractionTimeline extends StatelessWidget {
  final List<ContractionEntry> contractions;
  final String Function(Duration, AppLocalizations) fmtDuration;
  final AppLocalizations l10n;

  const _ContractionTimeline({
    required this.contractions,
    required this.fmtDuration,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${l10n.contraction_timer_history} (${contractions.length})',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.appTextSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...contractions.asMap().entries.map((e) {
            final i = e.key;
            final c = e.value;
            return _TimelineRow(
              contraction: c,
              index: i,
              total: contractions.length,
              fmtDuration: fmtDuration,
              l10n: l10n,
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final ContractionEntry contraction;
  final int index;
  final int total;
  final String Function(Duration, AppLocalizations) fmtDuration;
  final AppLocalizations l10n;

  const _TimelineRow({
    required this.contraction,
    required this.index,
    required this.total,
    required this.fmtDuration,
    required this.l10n,
  });

  Color _intensityColor() {
    switch (contraction.intensity) {
      case ContractionIntensity.mild:
        return const Color(0xFF4CAF50);
      case ContractionIntensity.moderate:
        return _kAmber;
      case ContractionIntensity.strong:
        return _kRose;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = contraction.endTime == null ? _kRose : _intensityColor();
    final durationSecs = contraction.endTime != null
        ? contraction.duration.inSeconds
        : 0;
    // Bar width: 0–120s maps to 0–1 (capped)
    final barFrac = (durationSecs / 120).clamp(0.0, 1.0);
    final timeStr = _fmt(contraction.startTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline connector
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                if (index < total - 1)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: context.appDividerColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        timeStr,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.appTextSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        contraction.endTime != null && durationSecs > 0
                            ? fmtDuration(contraction.duration, l10n)
                            : '...',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Stack(
                    children: [
                      // Track
                      Container(
                        height: 5,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: dotColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      // Fill
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: barFrac,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          height: 5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                dotColor.withValues(alpha: 0.6),
                                dotColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    return DateFormat.jm().format(dt);
  }
}

// ─── 5-1-1 Alert Banner ───────────────────────────────────────────────────────
class _AlertBanner extends StatelessWidget {
  final AppLocalizations l10n;
  const _AlertBanner({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _kAmber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _kAmber.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: _kAmber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.contraction_timer_active_labor,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _kAmber,
                      ),
                    ),
                    Text(
                      l10n.contraction_timer_contact_doctor,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kAmber.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
