import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('floating_action_button renders extended variant', (tester) async {
    await pumpTemplate(
      tester,
      '{% floating_action_button icon: "add" label: "Create" %}'
      '{% endfloating_action_button %}',
    );

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
  });

  testWidgets('floating_action_button enforces strict args', (tester) async {
    expect(
      () => pumpTemplate(
        tester,
        '{% floating_action_button unknown: 1 %}{% endfloating_action_button %}',
        strictTags: true,
      ),
      throwsException,
    );
  });
}
