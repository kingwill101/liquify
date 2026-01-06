import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('flex tag renders with direction', (tester) async {
    await pumpTemplate(
      tester,
      '{% flex direction: "horizontal" %}{% text value: "A" %}{% text value: "B" %}{% endflex %}',
    );

    expect(find.byType(Flex), findsOneWidget);
    final flex = tester.widget<Flex>(find.byType(Flex));
    expect(flex.direction, Axis.horizontal);
  });

  testWidgets('flex tag supports vertical direction', (tester) async {
    await pumpTemplate(
      tester,
      '{% flex direction: "vertical" %}'
      '{% text value: "One" %}'
      '{% text value: "Two" %}'
      '{% endflex %}',
    );

    final flex = tester.widget<Flex>(find.byType(Flex));
    expect(flex.direction, Axis.vertical);
    expect(flex.children.length, 2);
  });
}
