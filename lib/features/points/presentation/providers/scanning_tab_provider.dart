import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The two tabs of the Scanning screen.
enum ScanningTab { scan, champions }

/// A one-shot request to open the Scanning screen on a particular tab.
///
/// The Scanning screen lives in a [StatefulShellRoute.indexedStack] branch, so
/// its widget — and its selected tab — persists across navigations. That's the
/// right default (a student mid-scan shouldn't lose it), but it means tapping
/// "Monthly Champions" on Home would otherwise land on whatever tab was open
/// last. The Home button sets this to [ScanningTab.champions]; the Scanning
/// screen consumes it once on build and resets it to null so a later manual
/// visit isn't forced back onto Champions.
final scanningTabRequestProvider = StateProvider<ScanningTab?>((ref) => null);
