import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('mouse_region wires hover callback', (tester) async {
    var hovered = false;
    await pumpTemplate(
      tester,
      '''
{% mouse_region key: "mouse-test" onHover: "hover" %}
  {% text value: "Hover" %}
{% endmouse_region %}
''',
      data: {
        'actions': {'hover': () => hovered = true},
      },
    );

    final widget = tester.widget<MouseRegion>(
      find.byKey(const ValueKey('mouse-test')),
    );
    expect(widget.onHover, isNotNull);
    widget.onHover!(const PointerHoverEvent());
    expect(hovered, isTrue);
  });

  testWidgets('mouse_region enforces strict args', (tester) async {
    expect(
      () => pumpTemplate(
        tester,
        '{% mouse_region unknown: 1 %}{% endmouse_region %}',
        strictTags: true,
      ),
      throwsException,
    );
  });
}
