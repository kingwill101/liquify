import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('visibility toggles child', (tester) async {
    await pumpTemplate(tester, '''
{% visibility visible: false replacement: "Hidden" %}
  {% text value: "Visible" %}
{% endvisibility %}
''');

    final widget = tester.widget<Visibility>(find.byType(Visibility));
    expect(widget.visible, isFalse);
    expect(find.text('Hidden'), findsOneWidget);
  });

  testWidgets('visibility enforces strict args', (tester) async {
    expect(
      () => pumpTemplate(
        tester,
        '{% visibility unknown: 1 %}{% endvisibility %}',
        strictTags: true,
      ),
      throwsException,
    );
  });
}
