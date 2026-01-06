import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('animated_container maps sizing and duration', (tester) async {
    await pumpTemplate(
      tester,
      '{% animated_container width: 120 height: 48 duration: 300 curve: "ease" color: "#112233" %}'
      '{% endanimated_container %}',
    );

    final widget = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(widget.constraints?.maxWidth, 120);
    expect(widget.constraints?.maxHeight, 48);
    expect(widget.duration, const Duration(milliseconds: 300));
    expect(widget.curve, Curves.ease);
  });
}
