import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('sized_box tag renders sized box', (tester) async {
    await pumpTemplate(tester, '{% sized_box width: 12 height: 12 %}');

    final spacer = tester.widget<SizedBox>(find.byType(SizedBox));
    expect(spacer.width, 12);
    expect(spacer.height, 12);
  });
}
