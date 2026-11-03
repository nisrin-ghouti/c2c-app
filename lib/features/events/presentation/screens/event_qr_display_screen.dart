import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../widgets/event_qr_display.dart';

/// Host/admin "Show QR" screen — wraps `EventQrDisplay` in its own Scaffold
/// so it's reachable as a dedicated view (rather than a bottom sheet, since
/// the enable/disable toggle here is something a host may want to leave
/// open for a while during the event). Works for both a single event and
/// one Program session, depending on whether [sessionId] is passed.
class EventQrDisplayScreen extends StatelessWidget {
  const EventQrDisplayScreen({
    super.key,
    required this.title,
    required this.eventId,
    this.sessionId,
    required this.initialEnabled,
  });

  final String title;
  final String eventId;
  final String? sessionId;
  final bool initialEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.eventQrHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                EventQrDisplay(
                  eventId: eventId,
                  sessionId: sessionId,
                  initialEnabled: initialEnabled,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
