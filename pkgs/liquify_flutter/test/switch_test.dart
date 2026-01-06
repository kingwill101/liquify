import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('switch tag renders with initial value', (tester) async {
    await pumpTemplate(tester, '{% switch value: true %}');

    final sw = tester.widget<Switch>(find.byType(Switch));
    expect(sw.value, isTrue);
  });
}
