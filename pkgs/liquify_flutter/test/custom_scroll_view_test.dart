import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('custom_scroll_view wraps box children in slivers', (
    tester,
  ) async {
    await pumpTemplate(tester, '''
{% custom_scroll_view %}
  {% text value: "Inline" %}
{% endcustom_scroll_view %}
''');

    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byType(SliverToBoxAdapter), findsOneWidget);
    expect(find.text('Inline'), findsOneWidget);
  });
}
