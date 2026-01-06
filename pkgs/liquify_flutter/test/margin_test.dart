import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('margin tag wraps container', (tester) async {
    await pumpTemplate(
      tester,
      '{% container %}{% margin horizontal: 8 vertical: 4 %}'
      '{% text value: "Margin" %}{% endcontainer %}',
    );

    final containerFinder = find.ancestor(
      of: find.text('Margin'),
      matching: find.byType(Container),
    );
    final container = tester.widget<Container>(containerFinder.first);
    expect(
      container.margin,
      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  });
}
