import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('background tag sets container color', (tester) async {
    await pumpTemplate(
      tester,
      '{% container %}{% background color: "#00ff00" %}'
      '{% text value: "BG" %}{% endcontainer %}',
    );

    final containerFinder = find.ancestor(
      of: find.text('BG'),
      matching: find.byType(Container),
    );
    final container = tester.widget<Container>(containerFinder.first);
    expect(container.color, const Color(0xff00ff00));
  });
}
