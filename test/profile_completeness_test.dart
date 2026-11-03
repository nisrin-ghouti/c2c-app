import 'package:c2c/features/auth/domain/entities/gender.dart';
import 'package:c2c/features/auth/domain/entities/profile.dart';
import 'package:flutter_test/flutter_test.dart';

/// A profile with every mandatory field filled in. Each test knocks exactly
/// one of them out, so a failure names the field that stopped being enforced.
Profile _complete({
  String fullName = 'Dana Levi',
  List<String> faculties = const ['Engineering'],
  List<String> fieldsOfStudy = const ['Computer Science'],
  String? degree = 'Bachelor',
  Gender? gender = Gender.female,
  int? year = 2,
}) {
  return Profile(
    id: 'u1',
    fullName: fullName,
    faculties: faculties,
    fieldsOfStudy: fieldsOfStudy,
    degree: degree,
    gender: gender,
    year: year,
  );
}

void main() {
  group('Profile.isComplete', () {
    test('is true when all seven mandatory fields are present', () {
      expect(_complete().isComplete, isTrue);
    });

    test('is false without a first name', () {
      expect(_complete(fullName: '').isComplete, isFalse);
    });

    test('is false with a first name but no last name', () {
      expect(_complete(fullName: 'Dana').isComplete, isFalse);
    });

    test('accepts a multi-word last name', () {
      expect(_complete(fullName: 'Dana Ben Levi').isComplete, isTrue);
    });

    test('is not fooled by padding or repeated whitespace', () {
      expect(_complete(fullName: '   Dana   ').isComplete, isFalse);
      expect(_complete(fullName: '  Dana   Levi  ').isComplete, isTrue);
    });

    test('is false without a field of study', () {
      expect(_complete(fieldsOfStudy: const []).isComplete, isFalse);
    });

    test('is false without a faculty', () {
      expect(_complete(faculties: const []).isComplete, isFalse);
    });

    test('is false without a degree level', () {
      expect(_complete(degree: null).isComplete, isFalse);
      expect(_complete(degree: '   ').isComplete, isFalse);
    });

    test('is false without a year of study', () {
      expect(_complete(year: null).isComplete, isFalse);
    });

    test('is false without a gender', () {
      expect(_complete(gender: null).isComplete, isFalse);
    });

    test('"prefer not to say" is a real answer, not a missing one', () {
      expect(_complete(gender: Gender.undisclosed).isComplete, isTrue);
    });

    test('optional fields stay optional', () {
      final profile = Profile(
        id: 'u1',
        fullName: 'Dana Levi',
        faculties: const ['Engineering'],
        fieldsOfStudy: const ['Computer Science'],
        degree: 'Bachelor',
        gender: Gender.female,
        year: 2,
        // No bio, no avatar, no interests, no languages.
      );
      expect(profile.isComplete, isTrue);
    });
  });
}
