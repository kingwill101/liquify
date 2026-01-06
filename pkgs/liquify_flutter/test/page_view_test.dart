import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('page_view renders pages with properties', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% page_view scrollDirection: "vertical" pageSnapping: false %}
  {% text value: "One" %}
  {% text value: "Two" %}
{% endpage_view %}
''',
    );

    expect(find.byType(PageView), findsOneWidget);
    final widget = tester.widget<PageView>(find.byType(PageView));
    expect(widget.scrollDirection, Axis.vertical);
    expect(widget.pageSnapping, isFalse);
    expect(find.text('One'), findsOneWidget);
  });

  testWidgets('page_view enforces strict args', (tester) async {
    expect(
      () => pumpTemplate(
        tester,
        '{% page_view unknown: 1 %}{% endpage_view %}',
        strictTags: true,
      ),
      throwsException,
    );
  });
}
