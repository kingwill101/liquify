import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('avatar tag renders circle avatar with text', (tester) async {
    await pumpTemplate(tester, '{% avatar text: "KD" %}');

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.child, isA<Text>());
    expect((avatar.child as Text).data, 'KD');
  });

  testWidgets('avatar tag accepts child widget override', (tester) async {
    const icon = Icon(Icons.star);
    await pumpTemplate(
      tester,
      '{% avatar child: child %}',
      data: {
        'child': icon,
      },
    );

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.child, icon);
  });
}
