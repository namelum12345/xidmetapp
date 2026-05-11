import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.isSent,
    required this.timeLabel,
    this.seenByPeer = false,
  });

  final String text;
  final bool isSent;
  final String timeLabel;

  /// Yalnız göndərilən mesajlar üçün: qarşı tərəf oxuyub (`readBy`).
  final bool seenByPeer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final bubble = DecoratedBox(
      decoration: BoxDecoration(
        color: isSent ? AppColors.primary : AppColors.chatBubbleIncoming,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppTheme.radiusLg),
          topRight: const Radius.circular(AppTheme.radiusLg),
          bottomLeft: Radius.circular(isSent ? AppTheme.radiusLg : 4),
          bottomRight: Radius.circular(isSent ? 4 : AppTheme.radiusLg),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isSent ? 0.08 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment:
              isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: textTheme.bodyMedium?.copyWith(
                color: isSent ? AppColors.onPrimary : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeLabel,
                  style: textTheme.labelSmall?.copyWith(
                    color: isSent
                        ? AppColors.onPrimary.withValues(alpha: 0.85)
                        : AppColors.textSecondary,
                  ),
                ),
                if (isSent) ...[
                  const SizedBox(width: 6),
                  Icon(
                    seenByPeer
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 15,
                    color: seenByPeer
                        ? AppColors.onPrimary
                        : AppColors.onPrimary.withValues(alpha: 0.65),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.72,
        alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
        child: bubble,
      ),
    );
  }
}
