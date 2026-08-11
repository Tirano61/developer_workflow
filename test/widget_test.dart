import 'package:flutter_test/flutter_test.dart';

import 'package:developer_workflow/app.dart';

void main() {
  testWidgets('App bootstrap smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Develop Workflow'), findsWidgets);
    expect(
      find.text('Base de frontend lista para crecer por features.'),
      findsOneWidget,
    );
  });
}
