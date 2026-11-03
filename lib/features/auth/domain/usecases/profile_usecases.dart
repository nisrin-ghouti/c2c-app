import 'dart:io';

import '../entities/gender.dart';
import '../entities/profile.dart';
import '../repositories/auth_repository.dart';

class EnsureProfileExists {
  const EnsureProfileExists(this._repository);
  final AuthRepository _repository;

  Future<void> call() => _repository.ensureProfileExists();
}

class GetMyProfile {
  const GetMyProfile(this._repository);
  final AuthRepository _repository;

  Future<Profile> call() => _repository.getMyProfile();
}

class UploadAvatar {
  const UploadAvatar(this._repository);
  final AuthRepository _repository;

  Future<String> call(File file) => _repository.uploadAvatar(file);
}

class SaveProfile {
  const SaveProfile(this._repository);
  final AuthRepository _repository;

  Future<void> call({
    required String fullName,
    List<String>? faculties,
    List<String>? fieldsOfStudy,
    String? degree,
    Gender? gender,
    int? year,
    String? bio,
    List<String>? hobbies,
    List<String>? interests,
    List<String>? languages,
    String? avatarUrl,
    bool clearAvatar = false,
  }) {
    return _repository.saveProfile(
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
      clearAvatar: clearAvatar,
    );
  }
}
