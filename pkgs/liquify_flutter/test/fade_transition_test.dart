import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('fade_transition builds with opacity animation', (tester) async {
    await pumpTemplate(
      tester,
      '{% fade_transition opacity: 0.6 %}'
      '{% text value: "Hello" %}'
      '{% endfade_transition %}',
    );

    final widget = tester.widget<FadeTransition>(
      find.byWidgetPredicate(
        (widget) =>
            widget is FadeTransition &&
            widget.child is Text &&
            (widget.child as Text).data == 'Hello',
      ),
    );
    expect(widget.opacity.value, closeTo(0.6, 0.001));
  });
}
