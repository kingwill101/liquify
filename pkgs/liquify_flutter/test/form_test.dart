import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('form tag renders child with autovalidate mode', (tester) async {
    await pumpTemplate(
      tester,
      '{% form autovalidateMode: "always" %}{% text value: "Form body" %}{% endform %}',
    );

    expect(find.byType(Form), findsOneWidget);
    expect(find.text('Form body'), findsOneWidget);
    final form = tester.widget<Form>(find.byType(Form));
    expect(form.autovalidateMode, AutovalidateMode.always);
  });
}
