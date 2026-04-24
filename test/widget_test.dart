import 'package:flutter_test/flutter_test.dart';

import 'package:test_kanban/app/app.dart';

void main() {
  testWidgets('App boots and shows app bar title', (tester) async {
    await tester.pumpWidget(const KanbanApp());
    await tester.pump();
    expect(find.text('Канбан-доска'), findsOneWidget);
  });
}
