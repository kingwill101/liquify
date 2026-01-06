import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('grid tag renders GridView with columns and gap', (tester) async {
    await pumpTemplate(
      tester,
      '{% grid_view columns: 3 gap: 5 %}'
      '{% text value: "A" %}{% text value: "B" %}{% endgrid_view %}',
    );

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate = grid.gridDelegate
        as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 3);
    expect(delegate.crossAxisSpacing, 5);
    expect(delegate.mainAxisSpacing, 5);
  });
}
