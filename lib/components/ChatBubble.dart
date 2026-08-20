import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class ChatBubble extends StatelessWidget {
  final String senderName;
  final String message;
  final String timestamp;
  final bool isCurrentUser;
  final String? avatarUrl;

  const ChatBubble({
    super.key,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isCurrentUser = false,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              backgroundColor: AppColors.secondaryFixedDim,
              child: avatarUrl == null
                  ? Text(
                      senderName.isNotEmpty ? senderName[0] : 'U',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      senderName,
                      style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isCurrentUser ? AppColors.secondary : AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: isCurrentUser ? const Radius.circular(12) : const Radius.circular(2),
                      bottomRight: isCurrentUser ? const Radius.circular(2) : const Radius.circular(12),
                    ),
                    border: Border.all(
                      color: isCurrentUser ? AppColors.secondary : AppColors.surfaceContainerHigh,
                    ),
                  ),
                  child: Text(
                    message,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isCurrentUser ? Colors.white : AppColors.onSurface,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Text(
                    timestamp,
                    style: AppTypography.labelSmall.copyWith(fontSize: 10, color: AppColors.outline),
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
