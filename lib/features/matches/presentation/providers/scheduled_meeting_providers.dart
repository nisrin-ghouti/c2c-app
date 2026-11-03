import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../main.dart' show supabase;

/// A rotating QR token for the Meeting Screen.
class MeetingToken {
  const MeetingToken({required this.token, required this.expiresAt});

  final String token;
  final DateTime expiresAt;

  /// Same payload shape as the spontaneous flow, so a single scanner could
  /// read either — the RPC strips the prefix.
  String get qrValue => 'c2c:meeting:$token';
}

/// The two-sided progress of a meeting: which direction(s) have completed.
class MeetingProgress {
  const MeetingProgress({
    required this.iScannedThem,
    required this.theyScannedMe,
    required this.completed,
    this.points = 0,
  });

  final bool iScannedThem;
  final bool theyScannedMe;
  final bool completed;
  final int points;

  MeetingProgress copyWith({
    bool? iScannedThem,
    bool? theyScannedMe,
    bool? completed,
    int? points,
  }) {
    return MeetingProgress(
      iScannedThem: iScannedThem ?? this.iScannedThem,
      theyScannedMe: theyScannedMe ?? this.theyScannedMe,
      completed: completed ?? this.completed,
      points: points ?? this.points,
    );
  }
}

enum MeetingScanStatus { ok, ownCode, expired, invalid }

/// Outcome of scanning the other student's QR, carrying the updated progress.
class MeetingScanOutcome {
  const MeetingScanOutcome({
    required this.status,
    this.progress,
    this.points = 0,
  });

  final MeetingScanStatus status;
  final MeetingProgress? progress;
  final int points;
}

/// An accepted meeting, for the "My Events" list.
class ScheduledMeeting {
  const ScheduledMeeting({
    required this.proposalId,
    required this.scheduledAt,
    required this.endsAt,
    this.location,
    this.notes,
    required this.otherUserId,
    required this.otherName,
    required this.completed,
  });

  final String proposalId;
  final DateTime scheduledAt;
  final DateTime endsAt;
  final String? location;
  final String? notes;
  final String otherUserId;
  final String otherName;
  final bool completed;
}

/// Thin wrapper over the scheduled-meeting RPCs. Kept in the presentation
/// layer as one small repository since the feature is self-contained and
/// doesn't share the clean-arch stack of the spontaneous flow.
class ScheduledMeetingRepository {
  const ScheduledMeetingRepository(this._client);

  final SupabaseClient _client;

  Future<MeetingToken> rotateToken(String proposalId) async {
    final result = await _client.rpc(
      'rotate_meeting_token',
      params: {'_proposal_id': proposalId},
    );
    final map = Map<String, dynamic>.from(result as Map);
    return MeetingToken(
      token: map['token'] as String,
      expiresAt: DateTime.parse(map['expires_at'] as String),
    );
  }

  Future<MeetingScanOutcome> scan(String rawValue) async {
    final result = await _client.rpc(
      'scan_meeting_qr',
      params: {'_raw': rawValue},
    );
    final map = Map<String, dynamic>.from(result as Map);
    final status = switch (map['status']) {
      'ok' => MeetingScanStatus.ok,
      'own_code' => MeetingScanStatus.ownCode,
      'expired' => MeetingScanStatus.expired,
      _ => MeetingScanStatus.invalid,
    };
    if (status != MeetingScanStatus.ok) {
      return MeetingScanOutcome(status: status);
    }
    return MeetingScanOutcome(
      status: status,
      points: (map['points'] as num?)?.toInt() ?? 0,
      progress: MeetingProgress(
        iScannedThem: map['i_scanned_them'] as bool? ?? true,
        theyScannedMe: map['they_scanned_me'] as bool? ?? false,
        completed: map['completed'] as bool? ?? false,
        points: (map['points'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  Future<MeetingProgress> getProgress(String proposalId) async {
    final result = await _client.rpc(
      'get_meeting_progress',
      params: {'_proposal_id': proposalId},
    );
    final map = Map<String, dynamic>.from(result as Map);
    return MeetingProgress(
      iScannedThem: map['i_scanned_them'] as bool? ?? false,
      theyScannedMe: map['they_scanned_me'] as bool? ?? false,
      completed: map['completed'] as bool? ?? false,
    );
  }

  Future<List<ScheduledMeeting>> listMyMeetings() async {
    final rows = await _client.rpc('list_my_meetings');
    return List<Map<String, dynamic>>.from(rows as List).map((row) {
      return ScheduledMeeting(
        proposalId: row['proposal_id'] as String,
        // Normalized to UTC: an RPC can return a timestamptz without a
        // Z/offset suffix, and DateTime.parse treats those as local.
        scheduledAt: _parseUtcTimestamp(row['scheduled_at'] as String),
        endsAt: _parseUtcTimestamp(row['ends_at'] as String),
        location: row['location'] as String?,
        notes: row['notes'] as String?,
        otherUserId: row['other_user_id'] as String,
        otherName: (row['other_name'] as String?) ?? '',
        completed: row['completed'] as bool? ?? false,
      );
    }).toList();
  }

  /// Realtime feed of check-ins for one meeting — the screen recomputes its
  /// two-section state whenever the other student scans.
  Stream<List<Map<String, dynamic>>> watchCheckins(String proposalId) {
    return _client
        .from('meeting_checkins')
        .stream(primaryKey: ['proposal_id', 'scanner_id'])
        .eq('proposal_id', proposalId);
  }
}

final _scheduledMeetingClientProvider = Provider<SupabaseClient>(
  (ref) => supabase,
);

final scheduledMeetingRepositoryProvider = Provider<ScheduledMeetingRepository>(
  (ref) {
    return ScheduledMeetingRepository(
      ref.watch(_scheduledMeetingClientProvider),
    );
  },
);

/// My accepted meetings — surfaced in My Events. Auto-disposes so it re-fetches
/// each visit (completion state changes after a meeting finishes).
final myMeetingsProvider = FutureProvider.autoDispose<List<ScheduledMeeting>>((
  ref,
) {
  return ref.watch(scheduledMeetingRepositoryProvider).listMyMeetings();
});

/// Parses a Postgres `timestamptz` that may arrive without a `Z`/offset
/// suffix. `DateTime.parse` would treat a suffix-less string as local time,
/// silently shifting the instant. Mirrors the helper in
/// `chat_repository_impl.dart`.
DateTime _parseUtcTimestamp(String raw) {
  final hasOffset = RegExp(r'(Z|[+-]\d\d(:?\d\d)?)$').hasMatch(raw);
  final iso = raw.replaceFirst(' ', 'T');
  return DateTime.parse(hasOffset ? iso : '${iso}Z');
}
