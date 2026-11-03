import 'package:c2c/core/l10n/generated/app_localizations.dart';
import 'package:c2c/core/theme/app_colors.dart';
import 'package:c2c/features/auth/presentation/widgets/spam_folder_note.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Locale locale) => MaterialApp(
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: const Scaffold(body: SpamFolderNote()),
);

void main() {
  testWidgets('renders in the app red, not muted grey', (tester) async {
    await tester.pumpWidget(_wrap(const Locale('en')));
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.style?.color, AppColors.destructive);
    expect(text.style?.color, isNot(AppColors.mutedForeground));
  });

  testWidgets('shows the exact wording in each language', (tester) async {
    await tester.pumpWidget(_wrap(const Locale('he')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'אם לא מצאתם את המייל בתיבת הדואר הנכנס, בדקו גם בתיקיית הספאם.',
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(_wrap(const Locale('en')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "If you can't find the email in your inbox, please check your spam "
        'folder.',
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(_wrap(const Locale('ar')));
    await tester.pumpAndSettle();
    expect(find.textContaining('البريد الإلكتروني'), findsOneWidget);
  });
}
