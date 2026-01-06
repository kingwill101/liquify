import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('snackbar renders content and action', (tester) async {
    await pumpTemplate(
      tester,
      '{% snackbar content: "Saved" duration: 1200 %}'
      '{% snack_bar_action label: "Undo" action: "undo" %}'
      '{% endsnackbar %}',
    );

    expect(find.text('Saved'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byType(SnackBarAction), findsOneWidget);
  });

  testWidgets('snackbar enforces strict args', (tester) async {
    expect(
      () => pumpTemplate(
        tester,
        '{% snackbar content: "Saved" unknown: 1 %}{% endsnackbar %}',
        strictTags: true,
      ),
      throwsException,
    );
  });
}
