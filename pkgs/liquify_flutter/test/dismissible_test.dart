import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('dismissible renders with key and callbacks', (tester) async {
    var dismissed = false;
    await pumpTemplate(
      tester,
      '''
{% dismissible key: "demo" onDismissed: "dismissed" direction: "endToStart" %}
  {% container %}
    {% background "#ef4444" %}
  {% endcontainer %}
  {% text value: "Swipe" %}
{% enddismissible %}
''',
      data: {
        'actions': {'dismissed': () => dismissed = true},
      },
    );

    final widget = tester.widget<Dismissible>(find.byType(Dismissible));
    expect(widget.direction, DismissDirection.endToStart);
    expect(widget.onDismissed, isNotNull);
    widget.onDismissed!(DismissDirection.endToStart);
    expect(dismissed, isTrue);
  });

  testWidgets('dismissible enforces strict args', (tester) async {
    expect(
      () => pumpTemplate(
        tester,
        '{% dismissible unknown: 1 %}{% enddismissible %}',
        strictTags: true,
      ),
      throwsException,
    );
  });
}
