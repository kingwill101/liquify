import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('popup_menu builds items', (tester) async {
    await pumpTemplate(
      tester,
      '{% popup_menu icon: "more_vert" %}'
      '{% popup_menu_item label: "Edit" value: "edit" %}'
      '{% popup_menu_divider %}'
      '{% popup_menu_item label: "Delete" value: "delete" %}'
      '{% endpopup_menu %}',
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.byType(PopupMenuDivider), findsOneWidget);
  });

  testWidgets('popup_menu_item enforces strict args', (tester) async {
    expect(
      () => pumpTemplate(
        tester,
        '{% popup_menu %}'
        '{% popup_menu_item label: "Edit" unknown: 1 %}'
        '{% endpopup_menu %}',
        strictTags: true,
      ),
      throwsException,
    );
  });
}
