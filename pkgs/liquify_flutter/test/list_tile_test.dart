import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('list_tile tag renders title and subtitle', (tester) async {
    await pumpTemplate(
      tester,
      '{% list_tile title: "Account" subtitle: "Profile" %}{% endlist_tile %}',
    );

    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('list_tile tag supports extra layout props', (tester) async {
    await pumpTemplate(
      tester,
      '{% list_tile title: "Account" subtitle: "Details" isThreeLine: true minVerticalPadding: 12 shape: "rounded" selectedColor: "#ff0000" %}{% endlist_tile %}',
    );

    final tile = tester.widget<ListTile>(find.byType(ListTile));
    expect(tile.isThreeLine, isTrue);
    expect(tile.minVerticalPadding, 12);
    expect(tile.selectedColor, const Color(0xFFFF0000));
    expect(tile.shape, isA<RoundedRectangleBorder>());
  });
}
