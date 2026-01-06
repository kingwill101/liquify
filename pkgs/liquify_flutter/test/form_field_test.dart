import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('form_field shows validation error', (tester) async {
    await pumpTemplate(
      tester,
      '{% form_field autovalidateMode: "always" validator: "Required" %}'
      '{% text value: "Field content" %}'
      '{% endform_field %}',
    );

    expect(
      find.byWidgetPredicate((widget) => widget is FormField<String>),
      findsOneWidget,
    );
    expect(find.text('Field content'), findsOneWidget);
    expect(find.text('Required'), findsOneWidget);
  });
}
