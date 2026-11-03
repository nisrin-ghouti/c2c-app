import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/initials.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../providers/auth_providers.dart';

/// Tappable profile picture: shows the current photo (or the initials
/// fallback), lets the user pick one from the gallery, uploads it to Supabase
/// Storage, and reports the resulting public URL back via [onUploaded].
///
/// The upload happens immediately on pick (rather than on form submit) so the
/// user sees the result straight away and the URL is just another saved field.
class AvatarPicker extends ConsumerStatefulWidget {
  const AvatarPicker({
    super.key,
    required this.fullName,
    required this.avatarHue,
    required this.avatarUrl,
    required this.onUploaded,
    this.onRemoved,
    this.size = 96,
  });

  final String fullName;
  final int avatarHue;
  final String? avatarUrl;
  final ValueChanged<String> onUploaded;

  /// Called when the user removes their current photo. When null, no remove
  /// affordance is shown (e.g. first-time setup, where there's nothing to
  /// remove).
  final VoidCallback? onRemoved;
  final double size;

  @override
  ConsumerState<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends ConsumerState<AvatarPicker> {
  bool _busy = false;

  Future<void> _pick(AppLocalizations l10n) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      // Keep uploads small — avatars are never rendered above ~100px.
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _busy = true);
    try {
      final url = await ref.read(uploadAvatarProvider)(File(picked.path));
      if (!mounted) return;
      widget.onUploaded(url);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profilePhotoUploadError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onTap(AppLocalizations l10n) async {
    final hasPhoto = widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty;
    // Nothing to remove, or no removal handler: go straight to the picker.
    if (!hasPhoto || widget.onRemoved == null) {
      await _pick(l10n);
      return;
    }
    final choice = await showModalBottomSheet<_AvatarAction>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.profilePhotoChange),
              onTap: () => Navigator.of(context).pop(_AvatarAction.change),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.destructive,
              ),
              title: Text(
                l10n.profilePhotoRemove,
                style: const TextStyle(color: AppColors.destructive),
              ),
              onTap: () => Navigator.of(context).pop(_AvatarAction.remove),
            ),
          ],
        ),
      ),
    );
    if (choice == _AvatarAction.change) {
      await _pick(l10n);
    } else if (choice == _AvatarAction.remove) {
      widget.onRemoved?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasPhoto = widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty;

    return Column(
      children: [
        GestureDetector(
          onTap: _busy ? null : () => _onTap(l10n),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InitialsAvatar(
                initials: initialsOf(widget.fullName),
                hue: widget.avatarHue,
                imageUrl: widget.avatarUrl,
                size: widget.size,
              ),
              if (_busy)
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              // Small camera badge on the trailing-bottom edge.
              PositionedDirectional(
                bottom: 0,
                end: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: const Icon(
                    Icons.photo_camera,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: _busy ? null : () => _onTap(l10n),
          child: Text(
            hasPhoto ? l10n.profilePhotoChange : l10n.profilePhotoAdd,
          ),
        ),
      ],
    );
  }
}

enum _AvatarAction { change, remove }
