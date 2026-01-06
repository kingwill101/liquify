import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('action_chip triggers action callback', (tester) async {
    var pressed = false;
    await pumpTemplate(
      tester,
      '{% action_chip label: "New" action: "tap" %}',
      data: {
        'actions': {'tap': () => pressed = true},
      },
    );

    final chip = tester.widget<ActionChip>(find.byType(ActionChip));
    expect(chip.onPressed, isNotNull);
    chip.onPressed!();
    expect(pressed, isTrue);
  });

  testWidgets('choice_chip renders selected and emits change', (tester) async {
    bool? selected;
    await pumpTemplate(
      tester,
      '{% choice_chip label: "Daily" selected: true selectAction: "select" %}',
      data: {
        'actions': {'select': (bool value) => selected = value},
      },
    );

    final chip = tester.widget<ChoiceChip>(find.byType(ChoiceChip));
    expect(chip.selected, isTrue);
    expect(chip.onSelected, isNotNull);
    chip.onSelected!(false);
    expect(selected, isFalse);
  });

  testWidgets('chip tag supports label style and shape', (tester) async {
    await pumpTemplate(
      tester,
      '{% chip label: "New" labelStyle: style shape: "stadium" %}',
      data: {
        'style': {'fontSize': 14, 'color': '#ff0000'},
      },
    );

    final chip = tester.widget<Chip>(find.byType(Chip));
    expect(chip.labelStyle?.fontSize, 14);
    expect(chip.labelStyle?.color, const Color(0xFFFF0000));
    expect(chip.shape, isA<StadiumBorder>());
  });

  testWidgets('chip tag rejects unknown label style keys in strict mode', (
    tester,
  ) async {
    expect(
      () => pumpTemplate(
        tester,
        '{% chip label: "New" labelStyle: style %}',
        data: {
          'style': {'fontSize': 12, 'unknown': 2},
        },
        strictProps: true,
      ),
      throwsException,
    );
  });
}
