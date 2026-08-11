import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../providers/geo_providers.dart';

/// Presentational ward-location indicator.
///
/// Takes the resolved [WardLocationState] via the constructor and does NOT
/// watch any provider itself; surfaces watch `wardLocationProvider` and pass
/// the state in. Informational only — never blocks or disables surrounding
/// UI.
class WardLocationChip extends StatelessWidget {
  const WardLocationChip({super.key, required this.state});

  final WardLocationState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      WardLocationLoading() => const _StaticChip(
          key: Key('wardLocationLoading'),
          text: 'Locating…',
        ),
      WardLocationUnavailable() => const _StaticChip(
          key: Key('wardLocationUnavailable'),
          icon: Icons.location_off_outlined,
          text: 'Location unavailable',
        ),
      WardLocationSuccess(place: 'Outside coverage') => const _StaticChip(
          key: Key('wardLocationOutsideCoverage'),
          text: 'Outside coverage',
        ),
      WardLocationSuccess(:final place, :final code, :final wardSlug) =>
        ActionChip(
          key: const Key('wardLocationChip'),
          avatar: const Icon(Icons.place_outlined),
          label: Text(code.isEmpty ? place : '$place · $code'),
          onPressed: wardSlug == null
              ? null
              : () => context.push(RoutePaths.wardDetailFor(wardSlug)),
        ),
    };
  }
}

/// Non-interactive chip used for the loading / unavailable / outside-coverage
/// states.
class _StaticChip extends StatelessWidget {
  const _StaticChip({super.key, this.icon, required this.text});

  final IconData? icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: icon == null ? null : Icon(icon, size: 18),
      label: Text(text),
    );
  }
}
