import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('intrinsic_height wraps child', (tester) async {
    await pumpTemplate(
      tester,
      '{% intrinsic_height %}'
      '{% row %}{% text value: "A" %}{% endrow %}'
      '{% endintrinsic_height %}',
    );

    expect(find.byType(IntrinsicHeight), findsOneWidget);
  });
}

