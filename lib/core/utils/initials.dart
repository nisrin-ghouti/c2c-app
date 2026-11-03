/// First letter of the first and last "words" in [name], uppercased — the
/// fallback shown in [InitialsAvatar] circles. Shared across match
/// candidates, leaderboard entries, and the viewer's own rank card.
String initialsOf(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  final first = parts.first.substring(0, 1);
  final last = parts.length > 1 ? parts.last.substring(0, 1) : '';
  return (first + last).toUpperCase();
}
