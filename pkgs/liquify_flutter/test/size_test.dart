import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('size tag sets container width/height', (tester) async {
    await pumpTemplate(
      tester,
      '{% container %}{% size width: 100 height: 40 %}'
      '{% text value: "Size" %}{% endcontainer %}',
    );

    final containerFinder =
        find.ancestor(of: find.text('Size'), matching: find.byType(Container));
    final container = tester.widget<Container>(containerFinder.first);
    final constraints = container.constraints;
    expect(constraints, isNotNull);
    expect(constraints!.minWidth, 100);
    expect(constraints.maxWidth, 100);
    expect(constraints.minHeight, 40);
    expect(constraints.maxHeight, 40);
  });
}
