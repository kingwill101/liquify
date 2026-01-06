import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('scaffold tag renders app bar and body', (tester) async {
    await pumpTemplate(tester, '''
{% scaffold backgroundColor: "#101214" %}
  {% app_bar title: "Header" elevation: 0 %}
  {% text value: "Body" %}
{% endscaffold %}
''');

    final scaffoldFinder = find.byWidgetPredicate(
      (widget) => widget is Scaffold && widget.appBar is AppBar,
    );
    expect(scaffoldFinder, findsOneWidget);
    final scaffold = tester.widget<Scaffold>(scaffoldFinder);
    expect(scaffold.appBar, isA<AppBar>());
    expect(find.text('Body'), findsOneWidget);
  });

  testWidgets('safe_area tag applies minimum padding', (tester) async {
    await pumpTemplate(tester, '''
{% safe_area minimum: 12 %}
  {% text value: "Safe" %}
{% endsafe_area %}
''');

    final safeArea = tester.widget<SafeArea>(find.byType(SafeArea));
    expect(safeArea.minimum, const EdgeInsets.all(12));
  });
}
