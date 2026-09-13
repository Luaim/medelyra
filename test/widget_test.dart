import 'package:flutter_test/flutter_test.dart';

import 'package:medelyra/main.dart';

void main() {
  testWidgets('Medelyra app starts successfully', (tester) async {
    await tester.pumpWidget(const MedelyraApp());

    await tester.pump();

    expect(find.byType(MedelyraApp), findsOneWidget);
  });
}
