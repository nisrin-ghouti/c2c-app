import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../../../../core/widgets/primary_gradient_button.dart';
import '../../domain/entities/proposal_action_result.dart';
import '../providers/chat_providers.dart';

Future<void> showProposeMeetingSheet(BuildContext context, String chatId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ProposeMeetingSheet(chatId: chatId),
  );
}

/// The chat thread's `+` button opens this — date/time, location, and
/// optional notes for an in-chat "let's meet" proposal.
class ProposeMeetingSheet extends ConsumerStatefulWidget {
  const ProposeMeetingSheet({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ProposeMeetingSheet> createState() =>
      _ProposeMeetingSheetState();
}

class _ProposeMeetingSheetState extends ConsumerState<ProposeMeetingSheet> {
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _scheduledAt;
  DateTime? _endsAt;
  bool _submitting = false;

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledAt != null
          ? TimeOfDay(hour: _scheduledAt!.hour, minute: _scheduledAt!.minute)
          : TimeOfDay.now(),
    );
    if (time == null) return;
    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      _scheduledAt = picked;
      // Keep a default 1-hour window, but don't clobber an end time the
      // student already deliberately chose to be further out.
      if (_endsAt == null || !_endsAt!.isAfter(picked)) {
        _endsAt = picked.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEndDateTime() async {
    if (_scheduledAt == null) return;
    final base = _endsAt ?? _scheduledAt!.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: _scheduledAt!,
      lastDate: _scheduledAt!.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
    );
    if (time == null || !mounted) return;
    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!picked.isAfter(_scheduledAt!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).proposeMeetingErrorEndBeforeStart,
          ),
        ),
      );
      return;
    }
    setState(() => _endsAt = picked);
  }

  String _formatDateTime(DateTime dt) {
    final d =
        '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    final t =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d · $t';
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (_scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.proposeMeetingErrorDateRequired)),
      );
      return;
    }
    final endsAt = _endsAt ?? _scheduledAt!.add(const Duration(hours: 1));
    if (!endsAt.isAfter(_scheduledAt!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.proposeMeetingErrorEndBeforeStart)),
      );
      return;
    }
    setState(() => _submitting = true);
    final result = await ref.read(proposeMeetingProvider)(
      widget.chatId,
      scheduledAt: _scheduledAt!,
      endsAt: endsAt,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    if (!mounted) return;
    if (result == ProposeMeetingResult.ok) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          ProposeMeetingResult.invalidWindow =>
            l10n.proposeMeetingErrorEndBeforeStart,
          // Daily meeting limits are refusals, not failures — say which rule
          // was hit so the student knows to pick another day rather than
          // retrying the same one.
          ProposeMeetingResult.dailyPairLimit =>
            l10n.proposeMeetingErrorSameStudentToday,
          ProposeMeetingResult.dailyPartnerLimitSelf =>
            l10n.proposeMeetingErrorDailyLimitSelf,
          ProposeMeetingResult.dailyPartnerLimitOther =>
            l10n.proposeMeetingErrorDailyLimitOther,
          _ => l10n.proposeMeetingError,
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.proposeMeetingTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _pickDateTime,
            child: Text(
              _scheduledAt == null
                  ? l10n.proposeMeetingPickDateTime
                  : _formatDateTime(_scheduledAt!),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _scheduledAt == null ? null : _pickEndDateTime,
            child: Text(
              _endsAt == null
                  ? l10n.proposeMeetingPickEndDateTime
                  : _formatDateTime(_endsAt!),
            ),
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _locationController,
            label: l10n.eventFormLocationLabel,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _notesController,
            label: l10n.proposeMeetingNotesLabel,
          ),
          const SizedBox(height: 20),
          PrimaryGradientButton(
            label: l10n.proposeMeetingSubmit,
            loading: _submitting,
            onPressed: () => _submit(l10n),
          ),
        ],
      ),
    );
  }
}
