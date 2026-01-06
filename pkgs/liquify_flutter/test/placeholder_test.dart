import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('placeholder renders', (tester) async {
    await pumpTemplate(tester, '''
{% placeholder fallbackWidth: 80 fallbackHeight: 60 %}
''');

    expect(find.byType(Placeholder), findsOneWidget);
  });
}
