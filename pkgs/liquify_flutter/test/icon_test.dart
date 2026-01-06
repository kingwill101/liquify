import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('icon tag renders icon data', (tester) async {
    await pumpTemplate(
      tester,
      '{% icon name: "add" size: 20 color: "#00ff00" %}',
    );

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon, Icons.add);
    expect(icon.size, 20);
    expect(icon.color, const Color(0xff00ff00));
  });
}
