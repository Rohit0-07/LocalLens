import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_paths.dart';

class WardChip extends StatelessWidget {
  const WardChip({
    required super.key,
    required this.wardName,
    this.slug,
    this.onTap,
  });

  final String wardName;
  final String? slug;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.location_city_rounded, size: 16),
      label: Text(wardName),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: onTap ??
          () {
            final targetSlug = slug ?? wardName;
            context.push(RoutePaths.wardDetailFor(targetSlug));
          },
    );
  }
}
