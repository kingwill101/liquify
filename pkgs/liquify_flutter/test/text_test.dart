import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('text tag renders text content', (tester) async {
    await pumpTemplate(tester, '{% text value: "Hello" %}');

    expect(find.byType(Text), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
  });
}
