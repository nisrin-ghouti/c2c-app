import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:c2c/core/l10n/generated/app_localizations.dart';
import 'package:c2c/features/onboarding/presentation/screens/language_selection_screen.dart';

void main() {
  testWidgets('LanguageSelectionScreen renders all three language options',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LanguageSelectionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // English's native name and reference name are identical, so it
    // legitimately renders twice; Hebrew/Arabic are unambiguous.
    expect(find.text('English'), findsNWidgets(2));
    expect(find.text('עברית'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
  });
}
