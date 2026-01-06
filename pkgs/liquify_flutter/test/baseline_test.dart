import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('baseline tag wraps child', (tester) async {
    await pumpTemplate(
      tester,
      '{% baseline baseline: 20 baselineType: "alphabetic" %}{% text value: "Base" %}{% endbaseline %}',
    );

    expect(find.byType(Baseline), findsOneWidget);
    final baseline = tester.widget<Baseline>(find.byType(Baseline));
    expect(baseline.baseline, 20);
    expect(baseline.baselineType, TextBaseline.alphabetic);
  });
}
