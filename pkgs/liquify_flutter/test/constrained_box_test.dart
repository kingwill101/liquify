import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('constrained_box maps constraints', (tester) async {
    await pumpTemplate(
      tester,
      '{% constrained_box key: "box" constraints: constraints %}'
      '{% text value: "Box" %}'
      '{% endconstrained_box %}',
      data: {
        'constraints': {
          'minWidth': 40,
          'maxWidth': 80,
          'minHeight': 20,
          'maxHeight': 60,
        },
      },
    );

    final widget = tester.widget<ConstrainedBox>(
      find.byKey(const ValueKey('box')),
    );
    expect(widget.constraints.minWidth, 40);
    expect(widget.constraints.maxWidth, 80);
    expect(widget.constraints.minHeight, 20);
    expect(widget.constraints.maxHeight, 60);
  });
}
