import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('decorated_box renders child', (tester) async {
    await pumpTemplate(tester, '''
{% decorated_box decoration: "#0f172a" %}
  {% text value: "Decor" %}
{% enddecorated_box %}
''');

    expect(find.byType(DecoratedBox), findsWidgets);
    expect(find.text('Decor'), findsOneWidget);
  });
}
