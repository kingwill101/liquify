import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('bottom_sheet renders child content', (tester) async {
    await pumpTemplate(
      tester,
      '{% bottom_sheet enableDrag: false %}'
      '{% text value: "Sheet content" %}'
      '{% endbottom_sheet %}',
    );

    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.enableDrag, isFalse);
    expect(find.text('Sheet content'), findsOneWidget);
  });

  testWidgets('bottom_sheet enforces strict args', (tester) async {
    expect(
      () => pumpTemplate(
        tester,
        '{% bottom_sheet unknown: 1 %}{% endbottom_sheet %}',
        strictTags: true,
      ),
      throwsException,
    );
  });
}
