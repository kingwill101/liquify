import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('intrinsic_width applies step sizing', (tester) async {
    await pumpTemplate(
      tester,
      '{% intrinsic_width stepWidth: 20 stepHeight: 10 %}'
      '{% text value: "Width" %}'
      '{% endintrinsic_width %}',
    );

    final widget = tester.widget<IntrinsicWidth>(find.byType(IntrinsicWidth));
    expect(widget.stepWidth, 20);
    expect(widget.stepHeight, 10);
  });
}

