import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/event_scan_result.dart';
import '../providers/events_providers.dart';

/// Host/admin fallback for when a student's QR can't be scanned: type their
/// permanent Student ID to mark them attended.
///
/// Two steps on purpose — look the ID up, show the name, *then* confirm. A
/// single-step "type 10 digits and submit" would happily award points to a
/// mistyped stranger, and attendance can't be undone from this screen.
///
/// Returns `true` if attendance was confirmed, so the caller can refresh.
Future<bool> showConfirmByStudentIdSheet(
  BuildContext context, {
  required String eventId,
  String? sessionId,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => Padding(
      // Keeps the field above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _ConfirmByStudentIdSheet(eventId: eventId, sessionId: sessionId),
    ),
  );
  return confirmed ?? false;
}

class _ConfirmByStudentIdSheet extends ConsumerStatefulWidget {
  const _ConfirmByStudentIdSheet({required this.eventId, this.sessionId});

  final String eventId;
  final String? sessionId;

  @override
  ConsumerState<_ConfirmByStudentIdSheet> createState() =>
      _ConfirmByStudentIdSheetState();
}

class _ConfirmByStudentIdSheetState
    extends ConsumerState<_ConfirmByStudentIdSheet> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    final studentId = _controller.text.trim();
    if (studentId.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final name = await ref.read(lookupStudentNameByIdProvider)(studentId);
    if (!mounted) return;

    if (name == null) {
      setState(() {
        _busy = false;
        _error = l10n.attendanceManualLookupError;
      });
      return;
    }

    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.attendanceManualConfirmTitle),
        content: Text(l10n.attendanceManualConfirmMessage(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.attendanceManualAction),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (agreed != true) {
      setState(() => _busy = false);
      return;
    }

    final result = await ref.read(confirmAttendanceByStudentIdProvider)(
      widget.eventId,
      studentId,
      sessionId: widget.sessionId,
    );
    if (!mounted) return;

    if (result.status == EventScanStatus.confirmed) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.attendanceManualSuccess(name))),
      );
      return;
    }

    // Reuse the scan screen's vocabulary — these are the same outcomes.
    setState(() {
      _busy = false;
      _error = switch (result.status) {
        EventScanStatus.alreadyScanned => l10n.eventScanErrorAlreadyScanned,
        EventScanStatus.notRegistered => l10n.eventScanErrorNotRegistered,
        EventScanStatus.scanningClosed => l10n.eventScanningClosedMessage,
        EventScanStatus.expired => l10n.eventScanErrorExpired,
        _ => l10n.eventScanErrorInvalid,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.attendanceManualTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            // The ID is always digits, and always reads LTR even in he/ar.
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              hintText: l10n.attendanceManualHint,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _busy ? null : _submit(l10n),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(
                color: AppColors.destructive,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : () => _submit(l10n),
            child: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.attendanceManualAction),
          ),
        ],
      ),
    );
  }
}
