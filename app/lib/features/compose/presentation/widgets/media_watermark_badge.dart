import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class MediaWatermarkBadge extends StatelessWidget {
  final bool isVerified;
  final String? customLabel;
  final bool isCompact;

  const MediaWatermarkBadge({
    super.key,
    required this.isVerified,
    this.customLabel,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = customLabel ??
        (isVerified ? 'LocalLens Verified' : 'User Uploaded - Unverified');

    final backgroundColor = isVerified
        ? AppColors.watermarkVerifiedSurface
        : AppColors.watermarkUnverifiedSurface;

    final borderAndTextColor = isVerified
        ? AppColors.watermarkVerified
        : AppColors.watermarkUnverified;

    final icon = isVerified
        ? Icons.verified_user_rounded
        : Icons.warning_amber_rounded;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8.0 : 12.0,
        vertical: isCompact ? 4.0 : 6.0,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: borderAndTextColor.withValues(alpha: 0.4),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isCompact ? 14.0 : 18.0,
            color: borderAndTextColor,
          ),
          const SizedBox(width: 6.0),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: borderAndTextColor,
                fontSize: isCompact ? 11.0 : 13.0,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
