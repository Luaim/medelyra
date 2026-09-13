import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:medelyra/main.dart' as app;
import 'package:medelyra/onboarding/onboarding_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete onboarding flow', (tester) async {
    await app.main();

    await tester.pumpWidget(
      const app.MedelyraApp(
        initialPage: OnboardingPage(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(OnboardingPage), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
  });
}
