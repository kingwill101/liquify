import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('scroll_view renders SingleChildScrollView with properties',
      (tester) async {
    await pumpTemplate(
      tester,
      '{% scroll_view direction: "horizontal" reverse: true padding: 8 physics: "never" %}'
      '{% text value: "A" %}{% endscroll_view %}',
    );

    final scrollView =
        tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
    expect(scrollView.scrollDirection, Axis.horizontal);
    expect(scrollView.reverse, isTrue);
    expect(scrollView.padding, const EdgeInsets.all(8));
    expect(scrollView.physics, isA<NeverScrollableScrollPhysics>());
  });
}
