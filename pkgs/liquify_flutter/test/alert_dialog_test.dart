import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('alert_dialog renders title/content and actions', (tester) async {
    await pumpTemplate(
      tester,
      '{% alert_dialog title: "Confirm" content: "Are you sure?" %}'
      '{% button text: "Cancel" %}'
      '{% button text: "Delete" %}'
      '{% endalert_dialog %}',
    );

    final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
    expect(dialog.title, isNotNull);
    expect(dialog.content, isNotNull);
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('Are you sure?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('alert_dialog enforces strict args', (tester) async {
    expect(
      () => pumpTemplate(
        tester,
        '{% alert_dialog title: "Confirm" unknown: 1 %}{% endalert_dialog %}',
        strictTags: true,
      ),
      throwsException,
    );
  });
}
