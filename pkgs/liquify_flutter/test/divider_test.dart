import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('divider tag renders with properties', (tester) async {
    await pumpTemplate(
      tester,
      '{% divider height: 12 thickness: 2 color: "#ff0000" %}',
    );

    final divider = tester.widget<Divider>(find.byType(Divider));
    expect(divider.height, 12);
    expect(divider.thickness, 2);
    expect(divider.color, const Color(0xffff0000));
  });
}
