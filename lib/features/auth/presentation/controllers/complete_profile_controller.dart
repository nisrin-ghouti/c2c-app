import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/auth_failure.dart';
import '../../domain/entities/gender.dart';
import '../../domain/usecases/determine_post_auth_destination.dart';
import '../../domain/usecases/profile_usecases.dart';
import '../providers/auth_providers.dart';
import 'auth_action_state.dart';
import 'auth_message_kind.dart';

class CompleteProfileController extends StateNotifier<AuthActionState> {
  CompleteProfileController({
    required SaveProfile saveProfile,
    required DeterminePostAuthDestination determinePostAuthDestination,
  }) : _saveProfile = saveProfile,
       _determinePostAuthDestination = determinePostAuthDestination,
       super(AuthActionState.initial);

  final SaveProfile _saveProfile;
  final DeterminePostAuthDestination _determinePostAuthDestination;

  Future<PostAuthDestination?> submit({
    required String fullName,
    required List<String> faculties,
    required List<String> fieldsOfStudy,
    String? degree,
    Gender? gender,
    int? year,
    String? bio,
    List<String>? hobbies,
    List<String>? interests,
    List<String>? languages,
    String? avatarUrl,
  }) async {
    state = state.loadingStarted();
    try {
      await _saveProfile(
        fullName: fullName,
        faculties: faculties,
        fieldsOfStudy: fieldsOfStudy,
        degree: degree,
        gender: gender,
        year: year,
        bio: bio,
        hobbies: hobbies,
        interests: interests,
        languages: languages,
        avatarUrl: avatarUrl,
      );
      final destination = await _determinePostAuthDestination();
      state = AuthActionState.success;
      return destination;
    } on AuthFailure catch (e) {
      state = state.withError(classifyAuthFailure(e));
      return null;
    }
  }
}

final completeProfileControllerProvider =
    StateNotifierProvider.autoDispose<
      CompleteProfileController,
      AuthActionState
    >((ref) {
      return CompleteProfileController(
        saveProfile: ref.watch(saveProfileProvider),
        determinePostAuthDestination: ref.watch(
          determinePostAuthDestinationProvider,
        ),
      );
    });
