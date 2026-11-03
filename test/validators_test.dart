import 'package:flutter_test/flutter_test.dart';

import 'package:c2c/core/utils/validators.dart';

void main() {
  group('Validators.requiredField', () {
    const message = 'This field is required.';

    test('rejects null', () {
      expect(Validators.requiredField(null, message), message);
    });

    test('rejects empty string', () {
      expect(Validators.requiredField('', message), message);
    });

    test('rejects a single space', () {
      expect(Validators.requiredField(' ', message), message);
    });

    test('rejects multiple spaces', () {
      expect(Validators.requiredField('   ', message), message);
    });

    test('rejects a tab', () {
      expect(Validators.requiredField('\t', message), message);
    });

    test('accepts a normal name', () {
      expect(Validators.requiredField('John', message), isNull);
      expect(Validators.requiredField('Smith', message), isNull);
    });

    test('accepts a name padded with whitespace', () {
      expect(Validators.requiredField('  John  ', message), isNull);
    });
  });
}
