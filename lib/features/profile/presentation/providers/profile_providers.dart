import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/profile.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../points/presentation/providers/points_providers.dart';

final myProfileProvider = FutureProvider.autoDispose<Profile>((ref) {
  return ref.watch(getMyProfileProvider)();
});

final myTotalPointsProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(getMyTotalPointsProvider)();
});
