import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';

/// A tappable external URL row — the Instagram/website link on an event, and
/// the link and maps link on a benefit.
///
/// Tapping opens the URL in the platform browser. It used to only copy the
/// address to the clipboard, because `url_launcher` wasn't a dependency; the
/// link therefore looked tappable, said "Open link", and did nothing of the
/// sort. Copying survives as the fallback for the cases launching genuinely
/// can't be done (no browser, a malformed address), so the address is never a
/// dead end.
class ExternalLinkValue extends StatelessWidget {
  const ExternalLinkValue({super.key, required this.value});

  /// The address as the organizer typed it — shown verbatim.
  final String value;

  /// Organizers routinely type `instagram.com/...` or `www.example.com` with
  /// no scheme, which [Uri.parse] reads as a relative path that cannot be
  /// launched. Anything without a scheme is assumed to be https.
  static Uri? _resolve(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(
      trimmed.contains('://') ? trimmed : 'https://$trimmed',
    );
    if (uri == null || uri.host.isEmpty) return null;
    return uri;
  }

  Future<void> _open(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final uri = _resolve(value);

    if (uri != null) {
      try {
        // `canLaunchUrl` is deliberately skipped: on both platforms it needs
        // the scheme declared up front (Info.plist / AndroidManifest queries)
        // and answers false when it isn't, which is exactly the silent
        // nothing-happens this fixes. Launching and catching tells the truth.
        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (opened) return;
      } catch (_) {
        // Fall through to the clipboard.
      }
    }

    if (!context.mounted) return;
    await Clipboard.setData(ClipboardData(text: value.trim()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.externalLinkOpenFailedCopied)));
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.primary,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.open_in_new,
            size: 15,
            color: AppColors.mutedForeground,
          ),
        ],
      ),
    );
  }
}
