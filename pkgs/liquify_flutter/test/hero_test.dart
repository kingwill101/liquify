import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('hero tag renders with tag', (tester) async {
    await pumpTemplate(
      tester,
      '{% hero tag: "sample" %}'
      '{% text value: "Hero" %}'
      '{% endhero %}',
    );

    final widget = tester.widget<Hero>(find.byType(Hero));
    expect(widget.tag, 'sample');
  });
}

