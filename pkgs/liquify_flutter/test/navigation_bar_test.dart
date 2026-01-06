import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('navigation_bar renders destinations', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% navigation_bar selectedIndex: 0 %}
  {% navigation_bar_destination label: "Home" icon: "home" %}
  {% navigation_bar_destination label: "Search" icon: "search" %}
{% endnavigation_bar %}
''',
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
  });
}
