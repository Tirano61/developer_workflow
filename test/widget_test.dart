import 'package:flutter_test/flutter_test.dart';

import 'package:developer_workflow/app.dart';

void main() {
  testWidgets('App bootstrap smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Develop Workflow - Integracion REST'), findsOneWidget);
    expect(find.text('Fase 2: Applications + Indicators'), findsOneWidget);
  });
}
