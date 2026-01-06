import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('material_banner renders content', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% material_banner content: "Banner" %}
  {% button text: "Ok" %}
{% endmaterial_banner %}
''',
    );

    expect(find.byType(MaterialBanner), findsOneWidget);
    expect(find.text('Banner'), findsOneWidget);
  });
}
