import 'dart:ui' as ui;
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/platform_wrapper.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/name_swipe_provider.dart';
import '../../../../core/data/local/database/app_database.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/ambient_bottom_scrim.dart';


class LikedNamesScreen extends StatefulWidget {
  const LikedNamesScreen({super.key});

  @override
  State<LikedNamesScreen> createState() => _LikedNamesScreenState();
}

class _LikedNamesScreenState extends State<LikedNamesScreen> {
  late TextEditingController _searchController;
  String _searchQuery = '';
  String _sortBy = 'recent'; // 'alphabetical' | 'recent'
  List<NameSwipe>? _likedNames;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadLikedNames();
  }

  Future<void> _loadLikedNames() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final provider = Provider.of<NameSwipeProvider>(context, listen: false);
      final list = await provider.getLikedNames();
      if (mounted) {
        setState(() {
          _likedNames = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NameSwipeProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(gradient: context.appBackgroundGradient),
      child: PlatformScaffold(
        extendBodyBehindAppBar: false,
        backgroundColor: Colors.transparent,
        appBar: BrandedAppBar(
          isPregnancy: true,
          title: Text(l10n.preg_liked_names_title),
          helpKeywords: const ['name', 'swiper', 'names'],
          actions: [
            _buildAppBarFilterButton(context, provider),
          ],
        ),
        body: _buildMyFavoritesTab(context, provider),
      ),
    );
  }

  Widget _buildAppBarFilterButton(BuildContext context, NameSwipeProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
      tooltip: l10n.preg_liked_names_sort_tooltip,
      onPressed: () => _showSortBottomSheet(context),
    );
  }

  void _showSortBottomSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    PlatformUI.showPlatformActionSheet<String>(
      context,
      title: l10n.preg_liked_names_sort_tooltip,
      items: [
        ActionSheetItem<String>(
          label: l10n.preg_liked_names_sort_recent,
          value: 'recent',
          icon: Icons.schedule_rounded,
          isSelected: _sortBy == 'recent',
        ),
        ActionSheetItem<String>(
          label: l10n.preg_liked_names_sort_alphabetical,
          value: 'alphabetical',
          icon: Icons.sort_by_alpha_rounded,
          isSelected: _sortBy == 'alphabetical',
        ),
      ],
    ).then((val) {
      if (val != null && val != _sortBy) {
        setState(() {
          _sortBy = val;
        });
      }
    });
  }

  Widget _buildSearchHeader(BuildContext context, NameSwipeProvider provider) {
    final showClear = _searchQuery.isNotEmpty;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: context.appGlassColor.withValues(
                alpha: context.isDarkMode ? 0.6 : 0.4,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: context.appGlassBorderColor,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10),
                  child: Icon(
                    Icons.search_rounded,
                    size: 22,
                    color: context.appTextSecondary.withValues(alpha: 0.6),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textAlignVertical: TextAlignVertical.center,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: l10n.preg_liked_names_search_hint,
                      hintStyle: GoogleFonts.nunito(
                        fontSize: 15,
                        color: context.appTextSecondary.withValues(alpha: 0.5),
                      ),
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: GoogleFonts.nunito(fontSize: 16, color: context.appTextPrimary),
                  ),
                ),
                if (showClear)
                  IconButton(
                    icon: Icon(Icons.clear_rounded, size: 20, color: context.appTextSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyFavoritesTab(BuildContext context, NameSwipeProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          '${l10n.common_error}: $_errorMessage',
          style: TextStyle(color: context.appTextPrimary),
        ),
      );
    }

    final rawList = _likedNames ?? [];

    // No entries at all — show empty state without search header
    if (rawList.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.favorite_border_rounded,
        title: l10n.preg_liked_names_empty_title,
        message: l10n.preg_liked_names_empty_msg,
        color: context.appTextSecondary.withValues(alpha: 0.5),
      );
    }

    // There are entries — apply search filter & sort
    var list = List<NameSwipe>.from(rawList);
    if (_searchQuery.isNotEmpty) {
      list = list.where((e) => e.name.toLowerCase().contains(_searchQuery)).toList();
    }
    if (_sortBy == 'alphabetical') {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    return Stack(
      children: [
        // The scrollable list or empty search state in the background
        Positioned.fill(
          child: list.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 68),
                  child: EmptyStateWidget(
                    icon: Icons.search_off_rounded,
                    title: l10n.preg_liked_names_empty_title,
                    message: l10n.preg_liked_names_search_empty_msg,
                    color: context.appTextSecondary.withValues(alpha: 0.5),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(
                    left: AppConstants.paddingMedium,
                    right: AppConstants.paddingMedium,
                    top: 68, // Space for the floating search header
                    bottom: MediaQuery.paddingOf(context).bottom + 60.0,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return LikedNameTile(
                      name: item.name,
                      meaning: item.meaning ?? '',
                      gender: item.gender,
                      onDelete: () {
                        PlatformUI.showDeleteDialog(
                          context,
                          title: l10n.preg_liked_names_delete_title,
                          message: l10n.preg_liked_names_delete_confirm(item.name),
                          destructiveButtonText: l10n.common_delete,
                          onDelete: () async {
                            await provider.deleteLikedName(item.name);
                            _loadLikedNames();
                          },
                        );
                      },
                    );
                  },
                ),
        ),
        const AmbientBottomScrim(),
        // Floating search header at the top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildSearchHeader(context, provider),
        ),
      ],
    );
  }
}

class LikedNameTile extends StatefulWidget {
  final String name;
  final String meaning;
  final String gender;
  final VoidCallback onDelete;

  const LikedNameTile({
    super.key,
    required this.name,
    required this.meaning,
    required this.gender,
    required this.onDelete,
  });

  @override
  State<LikedNameTile> createState() => _LikedNameTileState();
}

class _LikedNameTileState extends State<LikedNameTile> {
  final GlobalKey _tileBoundaryKey = GlobalKey();
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
          boundary = _tileBoundaryKey.currentContext?.findRenderObject()
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
      final fileName = 'liked_baby_name_${widget.name}.png';
      final imagePath = '${directory.path}/$fileName';
      final imageFile = File(imagePath);

      await imageFile.writeAsBytes(pngBytes, flush: true);

      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      final box = context.findRenderObject() as RenderBox?;
      final String shareText = l10n.preg_liked_name_share_caption(widget.name);

      await PlatformUI.share(
        files: [XFile(imagePath, mimeType: 'image/png')],
        subject: shareText,
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      );
    } catch (e) {
      debugPrint('Error sharing liked name image: $e');
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
  Widget build(BuildContext context) {
    final isGirl = widget.gender.toLowerCase() == 'girl';
    final Color genderColor = isGirl ? const Color(0xFFEC407A) : const Color(0xFF1E88E5);
    final IconData genderIcon = isGirl ? Icons.female_rounded : Icons.male_rounded;

    return RepaintBoundary(
      key: _tileBoundaryKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: GlassCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          borderRadius: 24,
          child: Row(
            children: [
              // Gender Icon Badge
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: genderColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: genderColor.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
                child: Icon(genderIcon, color: genderColor, size: 22),
              ),
              const SizedBox(width: 16),

              // Name and Meaning
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: context.appTextPrimary,
                      ),
                    ),
                    if (widget.meaning.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.meaning,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: context.appTextSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Share Action
              if (!_isSharing)
                GestureDetector(
                  onTap: _handleShare,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.share_rounded,
                      color: context.appTextSecondary.withValues(alpha: 0.6),
                      size: 22,
                    ),
                  ),
                ),

              // Delete Action
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: context.isDarkMode ? Colors.redAccent.withValues(alpha: 0.8) : Colors.red[400],
                  size: 22,
                ),
                onPressed: widget.onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
