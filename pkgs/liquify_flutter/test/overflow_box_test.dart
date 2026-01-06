import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('overflow_box maps alignment and constraints', (tester) async {
    await pumpTemplate(
      tester,
      '{% overflow_box alignment: "bottomRight" minWidth: 10 maxWidth: 120 minHeight: 20 maxHeight: 80 %}'
      '{% text value: "Overflow" %}'
      '{% endoverflow_box %}',
    );

    final widget = tester.widget<OverflowBox>(find.byType(OverflowBox));
    expect(widget.alignment, Alignment.bottomRight);
    expect(widget.minWidth, 10);
    expect(widget.maxWidth, 120);
    expect(widget.minHeight, 20);
    expect(widget.maxHeight, 80);
  });
}
