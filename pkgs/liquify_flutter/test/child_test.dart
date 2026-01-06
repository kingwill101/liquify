import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('child tag overrides container children', (tester) async {
    await pumpTemplate(
      tester,
      '{% container %}'
      '{% text value: "Outer" %}'
      '{% child %}{% text value: "Inner" %}{% endchild %}'
      '{% endcontainer %}',
    );

    expect(find.text('Inner'), findsOneWidget);
    expect(find.text('Outer'), findsNothing);
  });
}
