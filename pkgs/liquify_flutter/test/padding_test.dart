import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('padding tag sets container padding', (tester) async {
    await pumpTemplate(
      tester,
      '{% container %}{% padding all: 12 %}'
      '{% text value: "Pad" %}{% endcontainer %}',
    );

    final containerFinder = find.ancestor(
      of: find.text('Pad'),
      matching: find.byType(Container),
    );
    final container = tester.widget<Container>(containerFinder.first);
    expect(container.padding, const EdgeInsets.all(12));
  });
}
