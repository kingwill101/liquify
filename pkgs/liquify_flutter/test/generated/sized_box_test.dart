import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() {
  testWidgets('sized_box renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% sized_box width: 120 height: 80 %}{% endsized_box %}
      '''
    );
    expect(find.byType(SizedBox), findsWidgets);
  });
}
