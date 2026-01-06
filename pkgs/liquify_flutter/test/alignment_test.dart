import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('alignment tag sets container alignment', (tester) async {
    await pumpTemplate(
      tester,
      '{% container %}{% alignment value: "center" %}'
      '{% text value: "Align" %}{% endcontainer %}',
    );

    final containerFinder =
        find.ancestor(of: find.text('Align'), matching: find.byType(Container));
    final container = tester.widget<Container>(containerFinder.first);
    expect(container.alignment, Alignment.center);
  });
}
