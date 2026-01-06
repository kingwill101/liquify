import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('drawer renders child content', (tester) async {
    await pumpTemplate(
      tester,
      '{% drawer backgroundColor: "#141925" %}'
      '{% text value: "Inside" %}'
      '{% enddrawer %}',
    );

    final drawer = tester.widget<Drawer>(find.byType(Drawer));
    expect(drawer.backgroundColor, const Color(0xFF141925));
    expect(find.text('Inside'), findsOneWidget);
  });
}
