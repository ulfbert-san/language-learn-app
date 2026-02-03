import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:language_learn_app/app.dart';

void main() {
  testWidgets('App starts and shows home page', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LanguageLearnApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that the app shows the Language Learn title
    expect(find.text('Language Learn'), findsWidgets);
  });
}
