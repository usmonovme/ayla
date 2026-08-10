import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/platform_wrapper.dart';
import '../../gamification/providers/gamification_provider.dart';
import '../../auth/models/user_model.dart';
import '../providers/pregnancy_provider.dart';
import '../../settings/providers/in_app_review_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../gamification/widgets/badge_celebration.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';

// ─── Colour palette for this screen ───────────────────────────────────────────
const _kPink = Color(0xFFE8909C); // trimester1Primary
const _kDeep = Color(0xFFC0606E);
const _kGold = Color(0xFFFFB347);

class KickCounterSessionScreen extends StatefulWidget {
  const KickCounterSessionScreen({super.key});

  @override
  State<KickCounterSessionScreen> createState() =>
      _KickCounterSessionScreenState();
}

class _KickCounterSessionScreenState extends State<KickCounterSessionScreen>
    with TickerProviderStateMixin {
  // ── Timer ──────────────────────────────────────────────────────────────────
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  // ── Kick history (timestamps) ──────────────────────────────────────────────
  final List<DateTime> _kickTimestamps = [];
  DateTime? get _lastKick =>
      _kickTimestamps.isNotEmpty ? _kickTimestamps.last : null;

  // ── Animations ────────────────────────────────────────────────────────────
  late AnimationController _impactCtrl; // button squish on tap
  late AnimationController _successCtrl; // celebration when target met
  late Animation<double> _impactScaleAnim;
  late Animation<double> _successScaleAnim;
  late Animation<double> _successOpacityAnim;

  // Ring wipe for the arc progress
  late AnimationController _ringCtrl;
  late Animation<double> _ringAnim;
  double _previousProgress = 0;

  // Floating +1 bubbles
  final List<_BubbleData> _bubbles = [];

  // Button key for position
  final GlobalKey _orbKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _startTimer();

    // Impact on tap
    _impactCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _impactScaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.82,
        ).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.82,
          end: 1.12,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.12,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_impactCtrl);

    // Progress ring
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _ringAnim = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutCubic));

    // Success burst
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _successScaleAnim = Tween<double>(
      begin: 0.0,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _successCtrl, curve: Curves.easeOutBack));
    _successOpacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.8), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.0), weight: 50),
    ]).animate(_successCtrl);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _elapsed = Duration(seconds: t.tick));
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _impactCtrl.dispose();
    _ringCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  // ── Kick tap handler ────────────────────────────────────────────────────────
  void _onKickTap() {
    HapticFeedback.heavyImpact();
    _impactCtrl.forward(from: 0.0);

    final provider = context.read<PregnancyProvider>();
    provider.recordKick();

    final now = DateTime.now();
    setState(() => _kickTimestamps.add(now));

    // Animate the progress ring
    final session = provider.activeKickSession;
    final count = (session?.count ?? 0);
    final newProgress = (count / 10).clamp(0.0, 1.0);
    _ringAnim = Tween<double>(
      begin: _previousProgress,
      end: newProgress,
    ).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutCubic));
    _previousProgress = newProgress;
    _ringCtrl.forward(from: 0.0);

    if (count == 10) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _successCtrl.forward(from: 0.0);
      });
    }

    // Spawn floating bubble
    double cx = MediaQuery.of(context).size.width / 2;
    double cy = MediaQuery.of(context).size.height / 2;
    final box = _orbKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final pos = box.localToGlobal(Offset.zero);
      cx = pos.dx + box.size.width / 2;
      cy = pos.dy + box.size.height / 2;
    }
    final bubble = _BubbleData(x: cx, y: cy);
    setState(() => _bubbles.add(bubble));
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _bubbles.remove(bubble));
    });
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  String _timeSince(DateTime? t, AppLocalizations l10n) {
    if (t == null) return l10n.kick_counter_no_kicks_yet;
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return l10n.kick_counter_just_now;
    return l10n.kick_counter_mins_ago(diff.inMinutes);
  }

  double _avgInterval() {
    if (_kickTimestamps.length < 2) return 0;
    final spans = <double>[];
    for (int i = 1; i < _kickTimestamps.length; i++) {
      spans.add(
        _kickTimestamps[i]
            .difference(_kickTimestamps[i - 1])
            .inSeconds
            .toDouble(),
      );
    }
    return spans.reduce((a, b) => a + b) / spans.length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<PregnancyProvider>();
    final session = provider.activeKickSession;

    if (session == null) {
      return Scaffold(
        backgroundColor: context.appBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: _kPink)),
      );
    }

    final count = session.count;
    final isTargetMet = count >= 10;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: BrandedAppBar(
        isPregnancy: true,
        title: Text(l10n.kick_counter_title),
      ),
      body: Stack(
        children: [
          // ── Background ───────────────────────────────────────────────────
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(gradient: context.appBackgroundGradient),
          ),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppConstants.spacingMedium),

                // Timer + stats row
                _StatsRow(
                  elapsed: _elapsed,
                  count: count,
                  avgInterval: _avgInterval(),
                  l10n: l10n,
                ),

                const SizedBox(height: AppConstants.spacingLarge),

                // Kick waveform / timeline
                _KickWaveform(timestamps: _kickTimestamps, target: 10),

                const Spacer(),

                // Central tap orb
                _buildOrb(count, isTargetMet),

                const SizedBox(height: 12),

                // Last kick label
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    _timeSince(_lastKick, l10n),
                    key: ValueKey(_lastKick?.second),
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.appTextSecondary,
                    ),
                  ),
                ),

                const Spacer(),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingLarge,
                  ),
                  child: _ActionButtons(
                    isTargetMet: isTargetMet,
                    l10n: l10n,
                    onStop: () => _stopAndSave(context),
                    onCancel: () => _confirmCancel(context),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingLarge),
              ],
            ),
          ),

          // ── Floating bubbles ─────────────────────────────────────────────
          ..._bubbles.map((b) => _FloatingBubble(key: ValueKey(b), data: b)),

          // ── Success burst overlay ────────────────────────────────────────
          if (isTargetMet)
            AnimatedBuilder(
              animation: _successCtrl,
              builder: (context, child) => Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: _successOpacityAnim.value,
                    child: Transform.scale(
                      scale: _successScaleAnim.value,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.successColor.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrb(int count, bool isTargetMet) {
    final activeColor = isTargetMet ? AppTheme.successColor : _kPink;
    const orbSize = 220.0;
    const innerSize = 180.0;

    return GestureDetector(
      key: _orbKey,
      onTap: _onKickTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_impactCtrl, _ringCtrl]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer breathing glow (static now)
              Container(
                width: orbSize,
                height: orbSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor.withValues(alpha: 0.12),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),

              // Arc progress track (grey)
              SizedBox(
                width: orbSize,
                height: orbSize,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 6,
                  color: activeColor.withValues(alpha: 0.12),
                  strokeCap: StrokeCap.round,
                ),
              ),

              // Arc progress fill (animated)
              SizedBox(
                width: orbSize,
                height: orbSize,
                child: CircularProgressIndicator(
                  value: _ringAnim.value,
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                  color: activeColor,
                ),
              ),

              // Dot markers for each kick (10 dots on the ring)
              _KickDots(
                count: count,
                isTargetMet: isTargetMet,
                size: orbSize,
                activeColor: activeColor,
              ),

              // Inner button
              Transform.scale(
                scale: _impactScaleAnim.value,
                child: Container(
                  width: innerSize,
                  height: innerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isTargetMet
                          ? [
                              AppTheme.successColor.withValues(alpha: 0.9),
                              AppTheme.successColor,
                            ]
                          : [_kPink.withValues(alpha: 0.85), _kDeep],
                      center: const Alignment(-0.3, -0.4),
                      radius: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.45),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(-6, -6),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hand icon
                      Icon(
                        AppTheme.kickIcon,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      // Count
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: CurvedAnimation(
                            parent: anim,
                            curve: Curves.elasticOut,
                          ),
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: Text(
                          '$count',
                          key: ValueKey<int>(count),
                          style: GoogleFonts.nunito(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1,
                            letterSpacing: -1,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        '/ 10',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      if (isTargetMet) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 10,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.kick_counter_target_met,
                                style: GoogleFonts.nunito(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmCancel(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await PlatformUI.showDeleteDialog(
      context,
      title: l10n.kick_counter_cancel_session_title,
      message: l10n.kick_counter_cancel_session_msg,
      destructiveButtonText: l10n.common_yes,
      onDelete: () {
        context.read<PregnancyProvider>().cancelKickSession();
        Navigator.pop(context);
      },
    );
  }

  void _stopAndSave(BuildContext context) async {
    try {
      await context.read<PregnancyProvider>().stopAndSaveKickSession();
      if (context.mounted) {
        final pregnancyId = context.read<PregnancyProvider>().pregnancy?.id;
        final gamification = context.read<GamificationProvider>();
        final newBadges = await gamification.checkBadgeUnlocks(
          AppMode.pregnancyTracking,
          contextId: pregnancyId,
        );

        if (context.mounted && newBadges.isNotEmpty) {
          await showBadgeCelebration(context, newBadges);
        }

        if (context.mounted) {
          // Trigger in-app review check
          context.read<InAppReviewProvider>().logSignificantEvent(context);
          Navigator.pop(context);
          PlatformUI.showMessage(
            context,
            message: AppLocalizations.of(context)!.kick_counter_save_success,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        PlatformUI.showMessage(context, message: 'Error: $e', isError: true);
      }
    }
  }
}

// ─── Stats row (timer + count + avg) ─────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final Duration elapsed;
  final int count;
  final double avgInterval; // seconds
  final AppLocalizations l10n;

  const _StatsRow({
    required this.elapsed,
    required this.count,
    required this.avgInterval,
    required this.l10n,
  });

  String _fmtAvg() {
    if (avgInterval <= 0) return '--';
    final s = avgInterval.round();
    if (s < 60) return '${s}s';
    return '${(s / 60).toStringAsFixed(1)}m';
  }

  @override
  Widget build(BuildContext context) {
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLarge,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: context.appGlassColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: context.appGlassBorderColor,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kPink.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Timer
                _StatCell(
                  icon: Icons.timer_outlined,
                  label: l10n.kick_counter_duration,
                  value: '$m:$s',
                  color: _kPink,
                  monospace: true,
                ),
                _Divider(),
                // Kicks so far
                _StatCell(
                  icon: AppTheme.kickIcon,
                  label: l10n.kick_counter_kicks,
                  value: '$count',
                  color: _kGold,
                ),
                _Divider(),
                // Average interval
                _StatCell(
                  icon: Icons.compress_rounded,
                  label: l10n.kick_counter_avg_gap,
                  value: _fmtAvg(),
                  color: AppTheme.trimester3Primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: context.appDividerColor,
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool monospace;
  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: context.appTextPrimary,
              fontFeatures: monospace
                  ? const [FontFeature.tabularFigures()]
                  : null,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: context.appTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Kick waveform / timeline ─────────────────────────────────────────────────
class _KickWaveform extends StatelessWidget {
  final List<DateTime> timestamps;
  final int target;
  const _KickWaveform({required this.timestamps, required this.target});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              AppLocalizations.of(context)!.kick_counter_kick_pattern,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.appTextSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: context.appSurfaceColor.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.appBorderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(
                painter: _WaveformPainter(
                  timestamps: timestamps,
                  target: target,
                  color: _kPink,
                  isDark: context.isDarkMode,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<DateTime> timestamps;
  final int target;
  final Color color;
  final bool isDark;

  _WaveformPainter({
    required this.timestamps,
    required this.target,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (timestamps.isEmpty) {
      _drawEmptyState(canvas, size);
      return;
    }

    final barW = size.width / target;
    final maxH = size.height * 0.75;

    // Draw completed kick bars
    for (int i = 0; i < timestamps.length; i++) {
      final x = i * barW + barW / 2;
      // Vary height slightly for organic feel
      final h = maxH * (0.6 + 0.4 * sin(i * 1.3 + timestamps.length * 0.5));
      final top = size.height / 2 - h / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barW * 0.3, top, barW * 0.6, h),
        const Radius.circular(4),
      );

      final fraction = (i + 1) / target;
      final barColor = Color.lerp(_kPink, _kGold, fraction)!;
      final barPaint = Paint()
        ..shader = LinearGradient(
          colors: [barColor.withValues(alpha: 0.5), barColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect.outerRect)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(rect, barPaint);
    }

    // Draw remaining (empty) slots
    final emptyPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    for (int i = timestamps.length; i < target; i++) {
      final x = i * barW + barW / 2;
      const h = 6.0;
      final top = size.height / 2 - h / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barW * 0.25, top, barW * 0.5, h),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, emptyPaint);
    }
  }

  void _drawEmptyState(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kPink.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final barW = size.width / 10;
    for (int i = 0; i < 10; i++) {
      final x = i * barW + barW / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barW * 0.25, size.height / 2 - 3, barW * 0.5, 6),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => old.timestamps != timestamps;
}

// ─── 10 dot markers around the ring ──────────────────────────────────────────
class _KickDots extends StatelessWidget {
  final int count;
  final bool isTargetMet;
  final double size;
  final Color activeColor;
  const _KickDots({
    required this.count,
    required this.isTargetMet,
    required this.size,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DotsPainter(
          count: count,
          activeColor: activeColor,
          inactiveColor: context.appDividerColor,
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  final int count;
  final Color activeColor;
  final Color inactiveColor;
  _DotsPainter({
    required this.count,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const total = 10;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 4;
    const dotR = 4.5;

    for (int i = 0; i < total; i++) {
      // Start from top (-π/2) going clockwise
      final angle = -pi / 2 + (2 * pi / total) * i;
      final x = cx + radius * cos(angle);
      final y = cy + radius * sin(angle);
      final isActive = i < count;
      final paint = Paint()
        ..color = isActive ? activeColor : inactiveColor
        ..style = PaintingStyle.fill;
      if (isActive) {
        // Glow
        canvas.drawCircle(
          Offset(x, y),
          dotR + 2,
          Paint()..color = activeColor.withValues(alpha: 0.25),
        );
      }
      canvas.drawCircle(Offset(x, y), dotR, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.count != count;
}

// ─── Action buttons ───────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final bool isTargetMet;
  final AppLocalizations l10n;
  final VoidCallback onStop;
  final VoidCallback onCancel;
  const _ActionButtons({
    required this.isTargetMet,
    required this.l10n,
    required this.onStop,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final btnColor = isTargetMet ? AppTheme.successColor : _kPink;
    return Column(
      children: [
        // Primary stop/save
        SizedBox(
          width: double.infinity,
          child: Material(
            color: btnColor,
            borderRadius: BorderRadius.circular(24),
            shadowColor: btnColor.withValues(alpha: 0.4),
            elevation: 8,
            child: InkWell(
              onTap: onStop,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isTargetMet
                          ? Icons.check_circle_rounded
                          : Icons.save_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.kick_counter_stop,
                      style: GoogleFonts.nunito(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Cancel
        TextButton(
          onPressed: onCancel,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            l10n.kick_counter_cancel,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Floating bubble (+1) data model ─────────────────────────────────────────
class _BubbleData {
  final double x;
  final double y;
  final int id = DateTime.now().microsecondsSinceEpoch;
  _BubbleData({required this.x, required this.y});
}

// ─── Floating bubble widget ───────────────────────────────────────────────────
class _FloatingBubble extends StatefulWidget {
  final _BubbleData data;
  const _FloatingBubble({super.key, required this.data});

  @override
  State<_FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<_FloatingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _up;
  late Animation<double> _side;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<double> _ring;
  late Animation<double> _ringOpacity;

  final _rng = Random();
  late final double _sideAmt;
  late final List<Offset> _particles;

  @override
  void initState() {
    super.initState();
    _sideAmt = (_rng.nextDouble() - 0.5) * 130;
    _particles = List.generate(6, (_) {
      final angle = _rng.nextDouble() * pi * 2;
      final d = 50 + _rng.nextDouble() * 50;
      return Offset(cos(angle) * d, sin(angle) * d);
    });

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _up = Tween<double>(
      begin: 0,
      end: -220,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuad));
    _side = Tween<double>(
      begin: 0,
      end: _sideAmt,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));
    _fade = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_ctrl);
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.4,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 15,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 75),
    ]).animate(_ctrl);
    _ring = Tween<double>(begin: 0.2, end: 2.2).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutQuart),
      ),
    );
    _ringOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 0.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 70),
    ]).animate(_ctrl);

    _ctrl.forward();
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
        return Positioned(
          left: widget.data.x - 50,
          top: widget.data.y - 50,
          child: SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Shockwave ring
                Opacity(
                  opacity: _ringOpacity.value,
                  child: Transform.scale(
                    scale: _ring.value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _kPink,
                          width: 6 * _ringOpacity.value,
                        ),
                      ),
                    ),
                  ),
                ),
                // Particles
                ..._particles.map((p) {
                  return Transform.translate(
                    offset: Offset(
                      p.dx * _ring.value / 1.5,
                      p.dy * _ring.value / 1.5,
                    ),
                    child: Opacity(
                      opacity: _ringOpacity.value,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kPink,
                        ),
                      ),
                    ),
                  );
                }),
                // +1 bubble
                Transform.translate(
                  offset: Offset(_side.value, _up.value),
                  child: Opacity(
                    opacity: _fade.value,
                    child: Transform.scale(
                      scale: _scale.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kPink, _kDeep],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: _kPink.withValues(alpha: 0.45),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              AppTheme.kickIcon,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '+1',
                              style: GoogleFonts.nunito(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
