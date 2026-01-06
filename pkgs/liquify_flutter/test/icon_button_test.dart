import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('icon_button variants render', (tester) async {
    await pumpTemplate(
      tester,
      '{% row spacing: 8 %}'
      '{% icon_button icon: "add" %}'
      '{% icon_button_filled icon: "add" %}'
      '{% icon_button_filled_tonal icon: "add" %}'
      '{% icon_button_outlined icon: "add" %}'
      '{% endrow %}',
    );

    expect(find.byType(IconButton), findsNWidgets(4));
    expect(find.byIcon(Icons.add), findsNWidgets(4));
  });
}
