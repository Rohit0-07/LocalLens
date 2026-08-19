import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/feedback/app_messenger.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/media_url.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../compose/data/media_service.dart';
import '../profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _dobController = TextEditingController();
  bool _submitting = false;
  String? _photoUrl;
  Uint8List? _photoPreview;

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            key: const Key('saveProfileButton'),
            onPressed: _submitting ? null : _save,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.tr('action_save')),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(userProfileProvider),
            child: const Text('Retry'),
          ),
        ),
        data: (profile) {
          if (!_displayNameController.text.isNotEmpty) {
            _displayNameController.text = profile.displayName ?? '';
            _usernameController.text = profile.username ?? '';
            _dobController.text = _formatDateForInput(profile.dateOfBirth);
          }

          final photoUrl = _photoPreview != null
              ? null
              : (profile.photoUrl != null && profile.photoUrl!.isNotEmpty
                  ? resolveMediaUrl(profile.photoUrl)
                  : null);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: GestureDetector(
                  key: const Key('editProfilePhoto'),
                  onTap: _pickPhoto,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      _photoPreview != null
                          ? ClipOval(
                              child: Image.memory(
                                _photoPreview!,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                              ),
                            )
                          : photoUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    photoUrl,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _fallbackAvatar(
                                  theme,
                                  colorScheme,
                                  _displayNameController.text,
                                ),
                              ),
                            )
                          : _fallbackAvatar(
                              theme,
                              colorScheme,
                              _displayNameController.text,
                            ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary,
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                key: const Key('editDisplayNameField'),
                controller: _displayNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'What neighbours will see on your reports',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('editUsernameField'),
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'e.g. ward_sentinel',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('editDateOfBirthField'),
                controller: _dobController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  hintText: 'DD/MM/YYYY',
                  prefixIcon: Icon(Icons.cake_outlined),
                  border: OutlineInputBorder(),
                ),
                onTap: () => _pickDob(),
              ),
              const SizedBox(height: 12),
              Text(
                'Your display name appears on posts you publish. Anonymous reports always show as "Anonymous".',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _fallbackAvatar(ThemeData theme, ColorScheme colorScheme, String name) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.anonMask.withValues(alpha: 0.14),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.person_outline,
        size: 42,
        color: AppColors.anonMask,
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    final Uint8List bytes;
    try {
      bytes = await picked.readAsBytes();
    } catch (_) {
      return;
    }

    setState(() => _photoPreview = bytes);

    try {
      final media = await ref.read(mediaServiceProvider).uploadMedia(
            bytes: bytes,
            isInAppCamera: false,
          );
      if (!mounted) return;
      setState(() => _photoUrl = media.url);
      ref.read(appMessengerProvider.notifier).show('Photo staged for profile');
    } catch (err) {
      if (!mounted) return;
      setState(() => _photoPreview = null);
      ref.read(appMessengerProvider.notifier).show(
            'Could not upload photo. ${err.toString()}',
          );
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_dobController.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'Select Date of Birth',
    );
    if (picked != null && mounted) {
      _dobController.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  Future<void> _save() async {
    final session = ref.read(sessionProvider);
    if (session == null || session.isGuest) {
      ref.read(appMessengerProvider.notifier).show('Sign in to update your profile');
      return;
    }
    setState(() => _submitting = true);
    final client = ref.read(apiClientProvider);
    final body = <String, dynamic>{
      'display_name': _displayNameController.text.trim(),
      'username': _usernameController.text.trim(),
    };
    final dob = _parseDob(_dobController.text);
    if (dob != null) body['date_of_birth'] = dob;
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      body['photo_url'] = _photoUrl;
    }

    try {
      await client.patchJson('/auth/me', body: body);
      ref.invalidate(userProfileProvider);
      if (mounted) {
        ref.read(appMessengerProvider.notifier).show('Profile updated');
        context.pop();
      }
    } catch (err) {
      if (mounted) {
        ref.read(appMessengerProvider.notifier).show(
              'Could not update profile. ${err.toString()}',
            );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static String _formatDateForInput(String? iso) {
    final date = DateTime.tryParse(iso ?? '');
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String? _parseDob(String value) {
    final parts = value.trim().split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    // Reject impossible dates instead of letting DateTime roll them over
    // (e.g. 31/02 stays invalid rather than silently becoming 03/03).
    if (month < 1 || month > 12 || day < 1 || year < 1900) return null;
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) return null;
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}