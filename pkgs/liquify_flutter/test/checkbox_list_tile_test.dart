import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('checkbox_list_tile renders title and value', (tester) async {
    await pumpTemplate(
      tester,
      '{% checkbox_list_tile title: "Alerts" value: true adaptive: true fillColor: "#2563eb" overlayColor: "#22c55e" checkboxScaleFactor: 1.2 titleAlignment: "center" isError: true %}',
    );

    expect(find.byType(CheckboxListTile), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    final tile = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
    expect(tile.value, isTrue);
    expect(
      tile.fillColor?.resolve(const <WidgetState>{}),
      const Color(0xff2563eb),
    );
    expect(
      tile.overlayColor?.resolve(const <WidgetState>{}),
      const Color(0xff22c55e),
    );
    expect(tile.checkboxScaleFactor, 1.2);
    expect(tile.titleAlignment, ListTileTitleAlignment.center);
    expect(tile.isError, isTrue);
  });
}
