/// A lightweight profile card shown in the home screen's "New students"
/// carousel — newest-joined students, per the reference app's
/// `order('created_at', desc)` query (not a compatibility match, just recency).
class StudentPreview {
  const StudentPreview({
    required this.id,
    required this.fullName,
    required this.avatarHue,
    this.faculty,
    this.year,
    this.avatarUrl,
    this.hobbies = const [],
  });

  final String id;
  final String fullName;
  final int avatarHue;
  final String? faculty;
  final int? year;
  final String? avatarUrl;
  final List<String> hobbies;

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.substring(0, 1);
    final last = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return (first + last).toUpperCase();
  }
}
