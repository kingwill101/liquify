import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('stack tag renders alignment', (tester) async {
    await pumpTemplate(
      tester,
      '{% stack alignment: "center" %}{% text value: "A" %}{% endstack %}',
    );

    final stackFinder = find.ancestor(
      of: find.text('A'),
      matching: find.byType(Stack),
    );
    final stack = tester.widget<Stack>(stackFinder.first);
    expect(stack.alignment, Alignment.center);
  });
}
