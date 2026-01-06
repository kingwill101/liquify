import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('layout_builder wraps child', (tester) async {
    await pumpTemplate(
      tester,
      '{% layout_builder %}{% text value: "Layout" %}{% endlayout_builder %}',
    );

    expect(find.byType(LayoutBuilder), findsOneWidget);
    expect(find.text('Layout'), findsOneWidget);
  });
}
