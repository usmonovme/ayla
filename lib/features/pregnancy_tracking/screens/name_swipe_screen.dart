import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/platform_wrapper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/route_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/pregnancy_provider.dart';
import '../providers/name_swipe_provider.dart';

class NameSwipeScreen extends StatefulWidget {
  const NameSwipeScreen({super.key});

  @override
  State<NameSwipeScreen> createState() => _NameSwipeScreenState();
}

class _SwipeParticle {
  double x, y;
  double vx, vy;
  double size;
  Color color;
  double alpha = 1.0;

  _SwipeParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
  });

  void update() {
    x += vx;
    y += vy;
    vy += 0.1; // gravity
    alpha -= 0.015;
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_SwipeParticle> particles;

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      if (p.alpha <= 0) continue;
      final paint = Paint()..color = p.color.withValues(alpha: p.alpha);
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _NameSwipeScreenState extends State<NameSwipeScreen> with TickerProviderStateMixin {
  bool _isInitialized = false;
  String? _matchedName;
  late AnimationController _celebrationController;
  late Animation<double> _celebrationScale;
  final List<_SwipeParticle> _particles = [];
  Timer? _particleTimer;

  // Key to target the top card for button-triggered swipe animations
  final GlobalKey<_SwipeCardState> _topCardKey = GlobalKey<_SwipeCardState>();
  // Tracks if the last action was undone, to animate the card sliding back in
  String? _undoneAction;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _celebrationScale = CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    );

    // Setup particle update timer
    _particleTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) return;
      if (_particles.isNotEmpty) {
        setState(() {
          for (var p in _particles) {
            p.update();
          }
          _particles.removeWhere((p) => p.alpha <= 0);
        });
      }
    });
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _particleTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final pregnancyProvider = Provider.of<PregnancyProvider>(context, listen: false);
      final nameSwipeProvider = Provider.of<NameSwipeProvider>(context, listen: false);

      final pregnancy = pregnancyProvider.pregnancy;
      final userId = authProvider.firebaseUser?.uid;

      if (pregnancy != null && userId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            nameSwipeProvider.initializeDeck(
              pregnancyId: pregnancy.id,
              userId: userId,
              appLocale: Localizations.localeOf(context).languageCode,
              defaultBabyGender: pregnancy.babyGender,
            );
          }
        });

        // Listen for match events
        nameSwipeProvider.onMatchFound.listen((name) {
          _showMatchCelebration(name);
        });
      }
      _isInitialized = true;
    }
  }

  void _showMatchCelebration(String name) {
    HapticFeedback.heavyImpact();
    setState(() {
      _matchedName = name;
    });
    _celebrationController.forward(from: 0.0);
    _spawnCelebrationParticles();
  }

  void _spawnCelebrationParticles() {
    final random = Random();
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    // Soft baby colors for particles
    final colors = [
      const Color(0xFF90CAF9), // soft blue
      const Color(0xFFF48FB1), // soft pink
      const Color(0xFFCE93D8), // soft lavender
      const Color(0xFFFFE082), // soft gold
      const Color(0xFFA5D6A7), // soft mint
    ];

    for (int i = 0; i < 80; i++) {
      _particles.add(
        _SwipeParticle(
          x: width / 2,
          y: height / 2 - 50,
          vx: (random.nextDouble() - 0.5) * 12,
          vy: (random.nextDouble() - 0.6) * 12 - 4,
          size: random.nextDouble() * 6 + 4,
          color: colors[random.nextInt(colors.length)],
        ),
      );
    }
  }

  void _closeMatchCelebration() {
    _celebrationController.reverse().then((_) {
      setState(() {
        _matchedName = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NameSwipeProvider>(context);

    // Dynamic background gradient based on gender filter
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Color> gradientColors;
    if (provider.genderFilter == 'boy') {
      gradientColors = isDark
          ? [const Color(0xFF0D1B2A), const Color(0xFF1B263B)]
          : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)];
    } else if (provider.genderFilter == 'girl') {
      gradientColors = isDark
          ? [const Color(0xFF2D1620), const Color(0xFF1F0E15)]
          : [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)];
    } else {
      gradientColors = isDark
          ? [const Color(0xFF1B0E2A), const Color(0xFF11081C)]
          : [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)];
    }

    final activePregnancy = Provider.of<PregnancyProvider>(context).pregnancy;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Top-left ambient glow spot
          Positioned(
            top: -150,
            left: -150,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (provider.genderFilter == 'girl'
                            ? const Color(0xFFEC407A)
                            : (provider.genderFilter == 'boy'
                                ? const Color(0xFF1E88E5)
                                : AppTheme.primaryColor))
                        .withValues(alpha: isDark ? 0.15 : 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom-right ambient glow spot
          Positioned(
            bottom: -150,
            right: -150,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (provider.genderFilter == 'girl'
                            ? const Color(0xFFEC407A)
                            : (provider.genderFilter == 'boy'
                                ? const Color(0xFF1E88E5)
                                : AppTheme.primaryColor))
                        .withValues(alpha: isDark ? 0.12 : 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Content Area
          SafeArea(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // Header
                      _buildHeader(context, provider),

                      // Card Stack
                      Expanded(
                        child: activePregnancy == null
                            ? _buildNoPregnancyState()
                            : provider.currentDeck.isEmpty
                                ? _buildEmptyDeckState(provider)
                                : _buildCardStack(context, provider),
                      ),

                      // Bottom Action Buttons
                      if (activePregnancy != null && provider.currentDeck.isNotEmpty)
                        _buildBottomActions(provider),
                    ],
                  ),
          ),

          // Particle overlay for matches
          if (_particles.isNotEmpty)
            IgnorePointer(
              child: CustomPaint(
                painter: _ParticlePainter(_particles),
                child: Container(),
              ),
            ),

          // Match Celebration Overlay
          if (_matchedName != null) _buildMatchCelebrationOverlay(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, NameSwipeProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () => Navigator.pop(context),
          ),

          // Gender Filter Toggle (Pill style Segmented Control)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.appGlassColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: context.appGlassBorderColor,
              ),
            ),
            child: Row(
              children: [
                _buildFilterButton(provider, 'boy', l10n.preg_gender_boy),
                _buildFilterButton(provider, 'both', l10n.preg_name_finder_both),
                _buildFilterButton(provider, 'girl', l10n.preg_gender_girl),
              ],
            ),
          ),

          // Liked List Shortcut
          IconButton(
            icon: Icon(
              Icons.bookmark_rounded,
              size: 28,
              color: provider.genderFilter == 'girl'
                  ? const Color(0xFFEC407A)
                  : provider.genderFilter == 'boy'
                      ? const Color(0xFF1E88E5)
                      : const Color(0xFFAB47BC),
            ),
            onPressed: () => Navigator.pushNamed(context, RouteConstants.likedNames),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(NameSwipeProvider provider, String filter, String label) {
    final isSelected = provider.genderFilter == filter;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter dynamic active color
    final Color activeColor;
    if (filter == 'boy') {
      activeColor = const Color(0xFF64B5F6); // Soft baby blue
    } else if (filter == 'girl') {
      activeColor = const Color(0xFFF06292); // Soft baby pink
    } else {
      activeColor = const Color(0xFFBA68C8); // Soft baby lavender
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        provider.setGenderFilter(filter);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildCardStack(BuildContext context, NameSwipeProvider provider) {
    final size = MediaQuery.of(context).size;
    final displayCount = min(provider.currentDeck.length, 5);

    // Calculate entrance offset if there was an undo
    Offset? entranceOffset;
    if (_undoneAction != null) {
      if (_undoneAction == 'liked') {
        entranceOffset = Offset(size.width * 1.5, 0);
      } else if (_undoneAction == 'passed') {
        entranceOffset = Offset(-size.width * 1.5, 0);
      }
      _undoneAction = null;
    }

    return Center(
      child: SizedBox(
        width: size.width * 0.92,
        height: size.height * 0.58,
        child: Stack(
          clipBehavior: Clip.none,
          children: List.generate(
            displayCount,
            (index) {
              final nameData = provider.currentDeck[index];
              final isTop = index == 0;

              // Alternating subtle organic rotations
              double rotationAngle = 0.0;
              if (index > 0) {
                final factor = index.isOdd ? 1.0 : -1.0;
                rotationAngle = factor * (0.015 + index * 0.008);
              }

              return Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: Offset(0.0, isTop ? 0.0 : (index * 12.0)),
                    child: Transform.scale(
                      scale: isTop ? 1.0 : (1.0 - (index * 0.04)).clamp(0.8, 1.0),
                      child: Transform.rotate(
                        angle: rotationAngle,
                        child: IgnorePointer(
                          ignoring: !isTop,
                          child: _SwipeCard(
                            key: isTop ? _topCardKey : null,
                            nameData: nameData,
                            entranceOffset: isTop ? entranceOffset : null,
                            onSwiped: (liked) {
                              provider.handleSwipe(liked);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ).reversed.toList(), // Reverse so index 0 (top card) is painted last (on top)
        ),
      ),
    );
  }

  Widget _buildBottomActions(NameSwipeProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: 28,
        top: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Undo Button
          _ActionButton(
            icon: Icons.undo_rounded,
            iconColor: provider.canUndo ? const Color(0xFFFFB300) : Colors.grey.withValues(alpha: 0.5),
            onTap: provider.canUndo
                ? () {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _undoneAction = provider.lastSwipedAction;
                    });
                    provider.undoSwipe();
                  }
                : null,
            size: 60,
            glowColor: const Color(0xFFFFB300),
          ),
          const SizedBox(width: 24),

          // Pass Button (Swipe Left)
          _ActionButton(
            icon: Icons.close_rounded,
            iconColor: const Color(0xFFEF5350),
            onTap: () {
              HapticFeedback.lightImpact();
              if (_topCardKey.currentState != null) {
                _topCardKey.currentState!.swipeProgrammatically(false);
              } else {
                provider.handleSwipe(false);
              }
            },
            size: 60,
            glowColor: const Color(0xFFEF5350),
          ),
          const SizedBox(width: 24),

          // Like Button (Swipe Right)
          _ActionButton(
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFF66BB6A),
            onTap: () {
              HapticFeedback.mediumImpact();
              if (_topCardKey.currentState != null) {
                _topCardKey.currentState!.swipeProgrammatically(true);
              } else {
                provider.handleSwipe(true);
              }
            },
            size: 60,
            glowColor: const Color(0xFF66BB6A),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPregnancyState() {
    return Center(
      child: EmptyStateWidget(
        icon: Icons.child_care_rounded,
        title: 'Active Pregnancy Required',
        message: 'You must start tracking a pregnancy to find baby names.',
        color: const Color(0xFFAB47BC),
        action: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFAB47BC),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('Go Back'),
        ),
      ),
    );
  }

  Widget _buildEmptyDeckState(NameSwipeProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final themeColor = provider.genderFilter == 'girl'
        ? const Color(0xFFEC407A)
        : provider.genderFilter == 'boy'
            ? const Color(0xFF1E88E5)
            : const Color(0xFFAB47BC);

    return Center(
      child: GlassCard(
        margin: const EdgeInsets.all(AppConstants.paddingLarge),
        padding: const EdgeInsets.all(AppConstants.paddingLarge + 8),
        borderRadius: 28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: themeColor.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.celebration_rounded,
                size: 56,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.preg_liked_names_empty_deck_title,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.preg_liked_names_empty_deck_msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: context.appTextSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      provider.resetPasses();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: themeColor.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      l10n.preg_liked_names_empty_deck_reset,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, RouteConstants.likedNames),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      l10n.preg_liked_names_empty_deck_view,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCelebrationOverlay(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: ScaleTransition(
          scale: _celebrationScale,
          child: Container(
            width: width * 0.82,
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1B24) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.pinkAccent.withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: 4,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Heart icons
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.favorite_rounded, size: 84, color: Colors.pink[300]),
                    const Icon(Icons.favorite_rounded, size: 54, color: Colors.redAccent),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Icon(Icons.star_rounded, size: 24, color: Colors.yellow[300]),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "It's a Name Match!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You and your partner both swiped right on',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.pink.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _matchedName ?? '',
                    style: GoogleFonts.nunito(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.pinkAccent,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _closeMatchCelebration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 4,
                  ),
                  child: Text(
                    'Keep Swiping',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
}

class _SwipeCard extends StatefulWidget {
  final Map<String, String> nameData;
  final void Function(bool liked) onSwiped;
  final Offset? entranceOffset;

  const _SwipeCard({
    super.key,
    required this.nameData,
    required this.onSwiped,
    this.entranceOffset,
  });

  @override
  State<_SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<_SwipeCard> with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  final GlobalKey _cardBoundaryKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _handleShare() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    try {
      // 1. Wait for the post frame callback to ensure the rebuild frame is scheduled and rendered
      final completer = Completer<void>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        completer.complete();
      });
      await completer.future;

      // 2. Wait a small extra delay to let any rendering/paint queues flush completely
      await Future<void>.delayed(const Duration(milliseconds: 50));

      RenderRepaintBoundary? boundary;
      ui.Image? image;
      int attempts = 0;

      while (attempts < 5) {
        try {
          boundary = _cardBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
          if (boundary == null) throw Exception('Repaint boundary not found');

          image = await boundary.toImage(pixelRatio: 3.0);
          break; // Success!
        } catch (e) {
          attempts++;
          if (attempts >= 5) {
            rethrow; // Propagate the error if all retries failed
          }
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      }

      if (image == null) throw Exception('Failed to capture image');
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null || byteData.lengthInBytes == 0) {
        throw Exception('Failed to generate image data');
      }

      final pngBytes = byteData.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final name = widget.nameData['name'] ?? 'baby_name';
      final fileName = 'baby_name_$name.png';
      final imagePath = '${directory.path}/$fileName';
      final imageFile = File(imagePath);

      await imageFile.writeAsBytes(pngBytes, flush: true);

      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      final box = context.findRenderObject() as RenderBox?;
      final nameStr = widget.nameData['name'] ?? '';
      final String shareText = l10n.preg_name_share_caption(nameStr);

      await PlatformUI.share(
        files: [XFile(imagePath, mimeType: 'image/png')],
        subject: shareText,
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      );
    } catch (e) {
      debugPrint('Error sharing name image: $e');
      if (mounted) {
        PlatformUI.showMessage(
          context,
          message: 'Failed to share image: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    if (widget.entranceOffset != null) {
      _dragOffset = widget.entranceOffset!;
      _slideAnimation = Tween<Offset>(
        begin: widget.entranceOffset!,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
      _slideController.forward();
      _slideController.addListener(_updateDragOffset);
    } else {
      _slideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset.zero,
      ).animate(_slideController);
    }
  }

  void _updateDragOffset() {
    if (mounted) {
      setState(() {
        _dragOffset = _slideAnimation.value;
      });
    }
  }

  @override
  void dispose() {
    _slideController.removeListener(_updateDragOffset);
    _slideController.dispose();
    super.dispose();
  }

  void swipeProgrammatically(bool liked) {
    if (_slideController.isAnimating) return;

    final size = MediaQuery.of(context).size;
    final targetX = liked ? size.width * 1.5 : -size.width * 1.5;

    _slideAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(targetX, 0),
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _slideController.forward(from: 0.0).then((_) {
      _slideController.removeListener(_updateDragOffset);
      _onSwipeComplete(liked);
    });

    _slideController.addListener(_updateDragOffset);
  }

  void _onSwipeComplete(bool liked) {
    widget.onSwiped(liked);
    setState(() {
      _dragOffset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final name = widget.nameData['name'] ?? '';
    final meaning = widget.nameData['meaning'] ?? '';
    final gender = widget.nameData['gender'] ?? 'boy';

    // Calculate rotation angle and tilt based on drag offset
    final double rotateAngle = (_dragOffset.dx / size.width) * (pi / 8);

    // Compute opacity of stamps
    final double likeOpacity = (_dragOffset.dx / 120).clamp(0.0, 1.0);
    final double nopeOpacity = (-_dragOffset.dx / 120).clamp(0.0, 1.0);

    final isAnimating = _slideController.isAnimating;

    return GestureDetector(
      onPanUpdate: isAnimating ? null : (details) {
        setState(() {
          _dragOffset += details.delta;
        });
      },
      onPanEnd: isAnimating ? null : (details) {
        final threshold = size.width * 0.35;
        if (_dragOffset.dx > threshold) {
          // Swipe Right (Like)
          _slideAnimation = Tween<Offset>(
            begin: _dragOffset,
            end: Offset(size.width * 1.5, _dragOffset.dy),
          ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
          _slideController.forward(from: 0.0).then((_) => _onSwipeComplete(true));
        } else if (_dragOffset.dx < -threshold) {
          // Swipe Left (Nope)
          _slideAnimation = Tween<Offset>(
            begin: _dragOffset,
            end: Offset(-size.width * 1.5, _dragOffset.dy),
          ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
          _slideController.forward(from: 0.0).then((_) => _onSwipeComplete(false));
        } else {
          // Snap Back
          _slideAnimation = Tween<Offset>(
            begin: _dragOffset,
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
          _slideController.forward(from: 0.0);
          _slideController.addListener(() {
            setState(() {
              _dragOffset = _slideAnimation.value;
            });
          });
        }
      },
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: rotateAngle,
          child: RepaintBoundary(
            key: _cardBoundaryKey,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2E2E4A), const Color(0xFF1F1F35)]
                      : [Colors.white, const Color(0xFFFDFBFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  if (isDark)
                    BoxShadow(
                      color: (gender == 'girl'
                              ? const Color(0xFFEC407A)
                              : (gender == 'boy'
                                  ? const Color(0xFF1E88E5)
                                  : AppTheme.primaryColor))
                          .withValues(alpha: 0.12),
                      blurRadius: 30,
                      spreadRadius: -2,
                      offset: const Offset(0, 4),
                    ),
                ],
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : context.appBorderColor.withValues(alpha: 0.6),
                  width: isDark ? 1.5 : 1,
                ),
              ),
              child: Stack(
                children: [
                  if (!_isSharing)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: _handleShare,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.appGlassColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.share_rounded,
                            color: context.appTextSecondary.withValues(alpha: 0.6),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  // Name & Details Content
                Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingXLarge),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Gender Icon Badge
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (gender == 'girl'
                                    ? const Color(0xFFEC407A)
                                    : const Color(0xFF1E88E5))
                                .withValues(alpha: isDark ? 0.15 : 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (gender == 'girl'
                                      ? const Color(0xFFEC407A)
                                      : const Color(0xFF1E88E5))
                                  .withValues(alpha: isDark ? 0.3 : 0.15),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            gender == 'girl' ? Icons.female_rounded : Icons.male_rounded,
                            size: 36,
                            color: gender == 'girl' ? const Color(0xFFEC407A) : const Color(0xFF1E88E5),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Name String
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            name,
                            style: GoogleFonts.nunito(
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              color: context.appTextPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        // Subtle Separator Line
                        if (meaning.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Container(
                            width: 80,
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  (gender == 'girl'
                                          ? const Color(0xFFEC407A)
                                          : const Color(0xFF1E88E5))
                                      .withValues(alpha: 0.35),
                                  Colors.transparent,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Meaning text
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              meaning,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: context.appTextSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Swipe Stamps overlay: LIKE (Green Stamp)
                if (likeOpacity > 0)
                  Positioned(
                    top: 40,
                    left: 32,
                    child: Transform.rotate(
                      angle: -0.2,
                      child: Opacity(
                        opacity: likeOpacity,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green, width: 4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'LIKE',
                            style: GoogleFonts.nunito(
                              color: Colors.green,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Swipe Stamps overlay: NOPE (Red Stamp)
                if (nopeOpacity > 0)
                  Positioned(
                    top: 40,
                    right: 32,
                    child: Transform.rotate(
                      angle: 0.2,
                      child: Opacity(
                        opacity: nopeOpacity,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red, width: 4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'NOPE',
                            style: GoogleFonts.nunito(
                              color: Colors.red,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
}
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final double size;
  final Color? glowColor;

  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.size,
    this.glowColor,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = widget.onTap != null;
    final Color baseColor = widget.glowColor ?? widget.iconColor;

    // Premium consistent background and border (Unified Glassmorphism)
    final Color backgroundColor;
    final Border border;

    if (enabled) {
      backgroundColor = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.7);
      border = Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.08),
        width: 1.2,
      );
    } else {
      // Disabled state
      backgroundColor = isDark
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.black.withValues(alpha: 0.02);
      border = Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        width: 1.0,
      );
    }

    return GestureDetector(
      onTapDown: enabled
          ? (_) {
              setState(() => _isPressed = true);
              _controller.forward();
            }
          : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _isPressed = false);
              _controller.reverse();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: enabled
          ? () {
              setState(() => _isPressed = false);
              _controller.reverse();
            }
          : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            border: border,
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: _isPressed
                          ? baseColor.withValues(alpha: isDark ? 0.3 : 0.2)
                          : Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                      blurRadius: _isPressed ? 16 : 8,
                      spreadRadius: _isPressed ? 1.0 : 0.0,
                      offset: Offset(0, _isPressed ? 2 : 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              widget.icon,
              color: enabled ? widget.iconColor : (isDark ? Colors.white24 : Colors.black26),
              size: widget.size * 0.44,
            ),
          ),
        ),
      ),
    );
  }
}
