import 'package:flutter/material.dart';

/// A [ScaffoldMessenger] key attached to `MaterialApp.router` itself (an
/// ancestor of every route's own `Scaffold`), for the rare case a SnackBar
/// must outlive the screen that triggered it — e.g. showing a success
/// message right as that screen pops, where a per-screen
/// `ScaffoldMessenger.of(context)` would have its SnackBar torn down along
/// with the popped route before the user ever sees it.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
