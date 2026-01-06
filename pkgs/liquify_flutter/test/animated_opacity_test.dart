import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('animated_opacity renders with duration and curve', (
    tester,
  ) async {
    await pumpTemplate(
      tester,
      '{% animated_opacity opacity: 0.4 duration: "240ms" curve: "easeInOut" %}'
      '{% text value: "Fade" %}'
      '{% endanimated_opacity %}',
    );

    final widget = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
    expect(widget.opacity, closeTo(0.4, 0.001));
    expect(widget.duration, const Duration(milliseconds: 240));
    expect(widget.curve, Curves.easeInOut);
  });
}
