import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('textfield tag renders decoration and obscure', (tester) async {
    await pumpTemplate(
      tester,
      '{% text_field label: "Email" hint: "Enter" obscure: true %}',
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isTrue);
    expect(field.decoration?.labelText, 'Email');
    expect(field.decoration?.hintText, 'Enter');
  });
}
