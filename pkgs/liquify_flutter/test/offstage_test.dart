import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('offstage renders child when false', (tester) async {
    await pumpTemplate(tester, '''
{% offstage offstage: false %}
  {% text value: "Onstage" %}
{% endoffstage %}
''');

    final widget = tester.widget<Offstage>(find.byType(Offstage).first);
    expect(widget.offstage, isFalse);
    expect(find.text('Onstage'), findsOneWidget);
  });

  testWidgets('offstage enforces strict args', (tester) async {
    expect(
      () => pumpTemplate(
        tester,
        '{% offstage unknown: 1 %}{% endoffstage %}',
        strictTags: true,
      ),
      throwsException,
    );
  });
}
