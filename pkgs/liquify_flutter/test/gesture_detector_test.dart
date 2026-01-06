import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('gesture_detector wires tap callback', (tester) async {
    var tapped = false;
    await pumpTemplate(
      tester,
      '''
{% gesture_detector onTap: "tap" %}
  {% text value: "Tap" %}
{% endgesture_detector %}
''',
      data: {
        'actions': {
          'tap': () => tapped = true,
        }
      },
    );

    final widget = tester.widget<GestureDetector>(find.byType(GestureDetector));
    expect(widget.onTap, isNotNull);
    widget.onTap!();
    expect(tapped, isTrue);
  });

  testWidgets('gesture_detector enforces strict args', (tester) async {
    expect(
      () => pumpTemplate(
        tester,
        '{% gesture_detector unknown: 1 %}{% endgesture_detector %}',
        strictTags: true,
      ),
      throwsException,
    );
  });
}
