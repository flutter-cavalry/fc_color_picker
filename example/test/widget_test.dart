import 'package:fc_color_picker_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens and closes the color picker', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('fc_color_picker'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);

    await tester.tap(find.text('Pick a color'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
  });
}
