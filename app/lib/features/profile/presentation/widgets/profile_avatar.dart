import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/media_url.dart';

/// Reusable profile avatar with layered fallbacks:
/// 1. Network photo when [photoUrl] is set.
/// 2. Name-initial circle when [displayName] is present.
/// 3. Guest / anonymous icon otherwise.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.photoUrl,
    required this.displayName,
    required this.isGuest,
    this.size = 80,
  });

  final String? photoUrl;
  final String? displayName;
  final bool isGuest;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size / 2;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final initial = _initialFor(displayName);

    if (hasPhoto) {
      return ClipOval(
        child: Image.network(
          resolveMediaUrl(photoUrl),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(radius, initial),
        ),
      );
    }
    return _fallback(radius, initial);
  }

  String? _initialFor(String? name) {
    if (name == null) return null;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.characters.first.toUpperCase();
  }

  Widget _fallback(double radius, String? initial) {
    if (initial != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.anonMask.withValues(alpha: 0.14),
        child: Text(
          initial,
          style: TextStyle(
            fontSize: radius * 0.72,
            fontWeight: FontWeight.w700,
            color: AppColors.anonMask,
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.anonMask.withValues(alpha: 0.14),
      child: Icon(
        isGuest ? Icons.person_outline : Icons.masks_outlined,
        size: radius * 0.85,
        color: AppColors.anonMask,
      ),
    );
  }
}