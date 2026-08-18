import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Reusable role pill shown on profile surfaces.
///
/// Mirrors the visual language of the role badge used on the public profile
/// screen: a rounded pill with a 12% alpha tint fill, 30% border and a role
/// icon. Representatives get the brand colour + `how_to_reg` icon, officials
/// get indigo + `account_balance`, everything else primary + `person`.
class ProfileRoleBadge extends StatelessWidget {
  const ProfileRoleBadge({super.key, required this.role});

  /// Raw role string, e.g. `'citizen'`, `'Ward Representative'`,
  /// `'ward_official'`. Displayed title-cased.
  final String role;

  bool get _isRepresentative =>
      role.toLowerCase().contains('representative');
  bool get _isOfficial => role.toLowerCase().contains('official');

  String get _label {
    final parts = role
        .split(RegExp(r'[_\s]+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return role;
    return parts
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = _isRepresentative
        ? AppColors.brand
        : _isOfficial
            ? Colors.indigo
            : theme.colorScheme.primary;

    final icon = _isRepresentative
        ? Icons.how_to_reg_rounded
        : _isOfficial
            ? Icons.account_balance_rounded
            : Icons.person_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
