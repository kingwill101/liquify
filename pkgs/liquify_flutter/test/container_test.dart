import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('container tag uses named args', (tester) async {
    await pumpTemplate(
      tester,
      '{% container padding: 8 margin: 4 alignment: "center" '
      'color: "#ff0000" width: 120 height: 80 %}'
      '{% text value: "Box" %}{% endcontainer %}',
    );

    final containerFinder =
        find.ancestor(of: find.text('Box'), matching: find.byType(Container));
    final container = tester.widget<Container>(containerFinder.first);
    expect(container.margin, const EdgeInsets.all(4));
    expect(container.padding, const EdgeInsets.all(8));
    expect(container.alignment, Alignment.center);
    expect(container.color, const Color(0xffff0000));
    final constraints = container.constraints;
    expect(constraints, isNotNull);
    expect(constraints!.minWidth, 120);
    expect(constraints.maxWidth, 120);
    expect(constraints.minHeight, 80);
    expect(constraints.maxHeight, 80);
  });
}
