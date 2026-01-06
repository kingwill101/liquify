import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('shader_mask renders child', (tester) async {
    await pumpTemplate(tester, '''
{% shader_mask %}
  {% text value: "Masked" %}
{% endshader_mask %}
''');

    expect(find.byType(ShaderMask), findsOneWidget);
    expect(find.text('Masked'), findsOneWidget);
  });
}
