import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class AnonymityGuideScreen extends StatelessWidget {
  const AnonymityGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('anonymity_guide_title')),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: colorScheme.primaryContainer,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 32,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Built-In Privacy',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'LocalLens protects your identity while empowering citizen action in your ward.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _GuideSectionCard(
            icon: Icons.fingerprint_rounded,
            iconColor: AppColors.seed,
            title: 'Zero-Retention HMAC Identity',
            subtitle:
                'Your phone number or email is never stored with civic reports or votes.',
            body:
                'Identity tokens (anon_id) are derived on demand using HMAC-SHA256 with a secure server key. '
                'Database queries only observe anonymous cryptographic hashes, preventing user tracking across issues.',
          ),
          const SizedBox(height: 16),
          _GuideSectionCard(
            icon: Icons.location_off_rounded,
            iconColor: AppColors.review,
            title: 'Block-Level Location Fuzzing',
            subtitle:
                'Protect your exact home or office location without sacrificing report utility.',
            body:
                'Enabling location fuzzing rounds your exact GPS coordinates to a broader block-level geohash. '
                'Municipal representatives receive actionable ward data while your precise location stays private.',
          ),
          const SizedBox(height: 16),
          _GuideSectionCard(
            icon: Icons.security_rounded,
            iconColor: AppColors.urgent,
            title: 'Shielded Report Protection',
            subtitle:
                'Complete identity decoupling for high-risk whistleblower issues.',
            body:
                'For sensitive reports where safety is paramount, Shielded Mode removes even the anonymous identity token. '
                'Reports are submitted independently to prevent retaliation while allowing public community verification.',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _GuideSectionCard extends StatelessWidget {
  const _GuideSectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
