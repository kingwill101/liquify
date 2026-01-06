import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('clip_path renders child', (tester) async {
    await pumpTemplate(tester, '''
{% clip_path %}
  {% text value: "Clipped" %}
{% endclip_path %}
''');

    expect(find.byType(ClipPath), findsOneWidget);
    expect(find.text('Clipped'), findsOneWidget);
  });
}
