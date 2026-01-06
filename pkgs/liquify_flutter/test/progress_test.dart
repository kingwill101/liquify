import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('progress tag renders linear indicator', (tester) async {
    await pumpTemplate(tester, '{% progress type: "linear" value: 0.6 %}');

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, closeTo(0.6, 0.001));
  });

  testWidgets('progress tag renders circular indicator', (tester) async {
    await pumpTemplate(tester, '{% progress type: "circular" value: 0.3 %}');

    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator, skipOffstage: false),
    );
    expect(indicator.value, closeTo(0.3, 0.001));
  });

  testWidgets('progress tag supports linear advanced properties', (
    tester,
  ) async {
    await pumpTemplate(
      tester,
      '{% progress type: "linear" value: 0.4 minHeight: 6 '
      'borderRadius: 8 trackGap: 3 stopIndicatorColor: "#ff0000" '
      'stopIndicatorRadius: 2 semanticsLabel: "Downloading" '
      'semanticsValue: "40%" valueColor: "#00ff00" %}',
    );

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.minHeight, 6);
    expect(indicator.borderRadius, BorderRadius.circular(8));
    expect(indicator.trackGap, 3);
    expect(indicator.stopIndicatorColor, const Color(0xffff0000));
    expect(indicator.stopIndicatorRadius, 2);
    expect(indicator.semanticsLabel, 'Downloading');
    expect(indicator.semanticsValue, '40%');
    expect(indicator.valueColor?.value, const Color(0xff00ff00));
  });

  testWidgets('progress tag supports circular advanced properties', (
    tester,
  ) async {
    await pumpTemplate(
      tester,
      '{% progress type: "circular" value: 0.2 strokeWidth: 5 '
      'strokeAlign: "inside" strokeCap: "round" '
      'constraints: indicator_constraints padding: indicator_padding '
      'trackGap: 2 %}',
      data: {
        'indicator_constraints': const BoxConstraints.tightFor(
          width: 32,
          height: 32,
        ),
        'indicator_padding': const EdgeInsets.symmetric(horizontal: 4),
      },
    );

    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator, skipOffstage: false),
    );
    expect(indicator.strokeWidth, 5);
    expect(indicator.strokeAlign, CircularProgressIndicator.strokeAlignInside);
    expect(indicator.strokeCap, StrokeCap.round);
    expect(
      indicator.constraints,
      const BoxConstraints.tightFor(width: 32, height: 32),
    );
    expect(indicator.padding, const EdgeInsets.symmetric(horizontal: 4));
    expect(indicator.trackGap, 2);
  });
}
