import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('slider tag renders with value', (tester) async {
    await pumpTemplate(tester, '{% slider value: 0.4 min: 0 max: 1 %}');

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, closeTo(0.4, 0.001));
  });

  testWidgets('slider tag wires start/end callbacks and semantics', (tester) async {
    double? startValue;
    double? endValue;
    await pumpTemplate(
      tester,
      '{% slider value: 0.5 onChangeStart: "start" onChangeEnd: "end" semanticFormatterCallback: "Value {value}" %}',
      data: {
        'actions': {
          'start': (double value) => startValue = value,
          'end': (double value) => endValue = value,
        },
      },
    );

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChangeStart?.call(0.2);
    slider.onChangeEnd?.call(0.8);

    expect(startValue, 0.2);
    expect(endValue, 0.8);
    expect(slider.semanticFormatterCallback?.call(0.3), 'Value 0.3');
  });
}
