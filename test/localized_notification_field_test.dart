import 'package:c2c/features/notifications/domain/usecases/localized_notification_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('localizedNotificationField', () {
    test('picks the requested language when it is present', () {
      final data = {
        'title': 'Career Fair',
        'title_en': 'Career Fair',
        'title_he': 'יריד תעסוקה',
        'title_ar': 'معرض وظائف',
      };
      expect(
        localizedNotificationField(data, 'title', languageCode: 'he'),
        'יריד תעסוקה',
      );
      expect(
        localizedNotificationField(data, 'title', languageCode: 'ar'),
        'معرض وظائف',
      );
      expect(
        localizedNotificationField(data, 'title', languageCode: 'en'),
        'Career Fair',
      );
    });

    test(
      'falls back to the canonical field when that language is untranslated',
      () {
        // What the organizer typed, with Hebrew never filled in.
        final data = {'title': 'Career Fair', 'title_he': null};
        expect(
          localizedNotificationField(data, 'title', languageCode: 'he'),
          'Career Fair',
        );
      },
    );

    test('treats an empty translation as missing', () {
      final data = {'title': 'Career Fair', 'title_he': '   '};
      expect(
        localizedNotificationField(data, 'title', languageCode: 'he'),
        'Career Fair',
      );
    });

    test('works on a payload written before the translations were added', () {
      // Rows from before migration 0075 carry only the canonical field.
      final data = {'title': 'Career Fair'};
      expect(
        localizedNotificationField(data, 'title', languageCode: 'ar'),
        'Career Fair',
      );
    });

    test('falls back to English when the canonical field is empty', () {
      final data = {'title': '', 'title_en': 'Career Fair'};
      expect(
        localizedNotificationField(data, 'title', languageCode: 'he'),
        'Career Fair',
      );
    });

    test('returns an empty string when nothing is available', () {
      expect(
        localizedNotificationField(const {}, 'title', languageCode: 'he'),
        '',
      );
    });

    test('ignores a non-string value rather than throwing', () {
      final data = {'title': 42, 'title_en': 'Career Fair'};
      expect(
        localizedNotificationField(data, 'title', languageCode: 'he'),
        'Career Fair',
      );
    });

    test('resolves location the same way as title', () {
      final data = {
        'location': 'Building 7',
        'location_he': 'בניין 7',
      };
      expect(
        localizedNotificationField(data, 'location', languageCode: 'he'),
        'בניין 7',
      );
      expect(
        localizedNotificationField(data, 'location', languageCode: 'ar'),
        'Building 7',
      );
    });
  });
}
