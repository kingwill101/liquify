import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() {
  testWidgets('colored_box renders', (tester) async {
    await pumpTemplate(tester, '''
{% colored_box color: "#FF0000" %}{% text value: "Sample" %}{% endcolored_box %}
      ''');
    expect(find.byType(ColoredBox), findsWidgets);
  });
}
