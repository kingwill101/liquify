import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('stepper tag renders and emits step taps', (tester) async {
    int? selected;
    await pumpTemplate(
      tester,
      '{% stepper steps: steps currentStep: 0 action: "step" %}',
      data: {
        'steps': [
          {'title': 'Plan', 'content': 'Outline'},
          {'title': 'Build', 'content': 'Implement'},
          {'title': 'Ship', 'content': 'Release'},
        ],
        'actions': {
          'step': (int index) => selected = index,
        },
      },
    );

    final stepper = tester.widget<Stepper>(find.byType(Stepper));
    expect(stepper.currentStep, 0);
    expect(stepper.onStepTapped, isNotNull);
    stepper.onStepTapped?.call(2);
    expect(selected, 2);
  });
}
