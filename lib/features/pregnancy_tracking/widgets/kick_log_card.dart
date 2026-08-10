import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/platform_wrapper.dart';
import '../models/kick_session_model.dart';
import '../../../l10n/app_localizations.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';

class KickLogCard extends StatelessWidget {
  final KickSession session;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;

  const KickLogCard({
    super.key,
    required this.session,
    this.onLongPress,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat.yMMMd(l10n.localeName).format(session.startTime);
    final timeStr = DateFormat.jm(l10n.localeName).format(session.startTime);
    final fullDateTimeStr = '$dateStr · $timeStr';
    final m = session.duration.inMinutes;
    final s = session.duration.inSeconds % 60;

    String durationStr;
    if (m > 0 && s > 0) {
      durationStr = l10n.contraction_timer_duration_text(m, s);
    } else if (m > 0) {
      durationStr = l10n
          .contraction_timer_duration_text(m, 0)
          .replaceAll(RegExp(r'\s+0\S*$'), '');
    } else {
      durationStr = l10n.contraction_timer_seconds_text(s);
    }

    const accentColor = AppTheme.trimester1Primary;

    Widget card = GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Circular Badge
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.08),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: const Center(
              child: Icon(
                AppTheme.kickIcon,
                color: accentColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Primary: kick count
                Text(
                  '${session.count} ${l10n.kick_counter_kicks}',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.appTextPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                // Secondary: date + time
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: context.appTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      fullDateTimeStr,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // Secondary: duration
                Row(
                  children: [
                    Icon(
                      Icons.hourglass_bottom_rounded,
                      size: 13,
                      color: context.appTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      durationStr,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onLongPress != null || onDelete != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(24),
          child: card,
        ),
      );
    }

    if (onDelete != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Dismissible(
          key: ValueKey(session.id),
          direction: DismissDirection.endToStart,
          background: Container(
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.12),
            ),
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
                      ? CupertinoIcons.delete_solid
                      : Icons.delete_forever_rounded,
                  color: AppTheme.errorColor,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.common_delete,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.errorColor,
                  ),
                ),
              ],
            ),
          ),
          confirmDismiss: (_) async {
            bool confirmed = false;
            await PlatformUI.showDeleteDialog(
              context,
              itemType: l10n.common_item_kick_session,
              onDelete: () => confirmed = true,
            );
            return confirmed;
          },
          onDismissed: (_) => onDelete?.call(),
          child: card,
        ),
      );
    }

    return card;
  }
}
