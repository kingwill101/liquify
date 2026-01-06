import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('listener wires pointer callback', (tester) async {
    var fired = false;
    await pumpTemplate(
      tester,
      '''
{% listener key: "listener-test" onPointerDown: "pressed" %}
  {% text value: "Press" %}
{% endlistener %}
''',
      data: {
        'actions': {
          'pressed': () => fired = true,
        }
      },
    );

    final widget =
        tester.widget<Listener>(find.byKey(const ValueKey('listener-test')));
    expect(widget.onPointerDown, isNotNull);
    widget.onPointerDown!(const PointerDownEvent());
    expect(fired, isTrue);
  });

  testWidgets('listener enforces strict args', (tester) async {
    expect(
      () => pumpTemplate(
        tester,
        '{% listener unknown: 1 %}{% endlistener %}',
        strictTags: true,
      ),
      throwsException,
    );
  });
}
