import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() {
  testWidgets('ignore_pointer renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% ignore_pointer ignoring: true %}{% text data: "Sample" %}{% endignore_pointer %}
      '''
    );
    expect(find.byType(IgnorePointer), findsWidgets);
  });
}
