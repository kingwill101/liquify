import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('dropdown tag renders and emits selection', (tester) async {
    String? selected;
    await pumpTemplate(
      tester,
      '{% dropdown items: items value: "Daily" action: "pick" %}',
      data: {
        'items': [
          {'label': 'Daily', 'value': 'Daily'},
          {'label': 'Weekly', 'value': 'Weekly'},
        ],
        'actions': {
          'pick': (String value) => selected = value,
        },
      },
    );

    final dropdownFinder = find.byWidgetPredicate(
      (widget) => widget is DropdownButton<String>,
    );
    final dropdown =
        tester.widget<DropdownButton<String>>(dropdownFinder);
    expect(dropdown.value, 'Daily');
    expect(dropdown.onChanged, isNotNull);
    dropdown.onChanged?.call('Weekly');
    expect(selected, 'Weekly');
  });

  testWidgets('dropdown tag applies menu properties', (tester) async {
    await pumpTemplate(
      tester,
      '{% dropdown items: items iconSize: 30 elevation: 4 menuMaxHeight: 240 dropdownColor: "#112233" padding: 8 alignment: "center" %}',
      data: {
        'items': [
          {'label': 'Daily', 'value': 'Daily'},
          {'label': 'Weekly', 'value': 'Weekly'},
        ],
      },
    );

    final dropdown =
        tester.widget<DropdownButton<String>>(find.byType(DropdownButton<String>));
    expect(dropdown.iconSize, 30);
    expect(dropdown.elevation, 4);
    expect(dropdown.menuMaxHeight, 240);
    expect(dropdown.dropdownColor, const Color(0xFF112233));
    expect(dropdown.padding, const EdgeInsets.all(8));
    expect(dropdown.alignment, Alignment.center);
  });
}
