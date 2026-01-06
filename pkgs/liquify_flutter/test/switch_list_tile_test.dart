import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('switch_list_tile renders title and value', (tester) async {
    await pumpTemplate(
      tester,
      '{% switch_list_tile title: "Auto sync" value: true adaptive: true applyCupertinoTheme: true activeThumbColor: "#ff0000" overlayColor: "#00ff00" dragStartBehavior: "down" %}',
    );

    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(find.text('Auto sync'), findsOneWidget);
    final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(tile.value, isTrue);
    expect(tile.applyCupertinoTheme, isTrue);
    expect(tile.activeThumbColor, const Color(0xffff0000));
    expect(
      tile.overlayColor?.resolve(const <WidgetState>{}),
      const Color(0xff00ff00),
    );
    expect(tile.dragStartBehavior, DragStartBehavior.down);
  });
}
