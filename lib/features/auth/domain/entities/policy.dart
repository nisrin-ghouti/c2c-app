/// The currently active usage policy, returned by the `get_active_policy`
/// RPC. Users must agree to it once before entering the app.
class Policy {
  const Policy({
    required this.id,
    required this.title,
    required this.body,
    required this.version,
  });

  final String id;
  final String title;
  final String body;
  final int version;
}
