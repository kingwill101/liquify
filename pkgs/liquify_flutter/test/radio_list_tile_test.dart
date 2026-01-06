// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('radio_list_tile binds group value', (tester) async {
    await pumpTemplate(
      tester,
      '{% radio_list_tile title: "Daily" value: "Daily" groupValue: "Daily" %}',
    );

    expect(find.byType(RadioListTile<String>), findsOneWidget);
    final tile = tester.widget<RadioListTile<String>>(
      find.byType(RadioListTile<String>),
    );
    expect(tile.groupValue, 'Daily');
  });
}
