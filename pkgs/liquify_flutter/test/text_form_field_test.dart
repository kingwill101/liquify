import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('text_form_field sets initial value', (tester) async {
    await pumpTemplate(
      tester,
      '{% text_form_field label: "Email" initialValue: "hello@liquify.dev" %}',
    );

    expect(find.byType(TextFormField), findsOneWidget);
    final field = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(field.initialValue, 'hello@liquify.dev');
    expect(field.autovalidateMode, AutovalidateMode.disabled);
  });
}
