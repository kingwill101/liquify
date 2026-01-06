import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('list tag renders ListView with gap', (tester) async {
    await pumpTemplate(
      tester,
      '{% list_view gap: 4 %}{% text value: "A" %}{% text value: "B" %}{% endlist_view %}',
    );

    final listView = tester.widget<ListView>(find.byType(ListView));
    final delegate = listView.childrenDelegate as SliverChildListDelegate;
    expect(delegate.children.length, 3);
  });
}
