import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('navigation_drawer renders destinations', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% navigation_drawer selectedIndex: 0 %}
  {% drawer_header %}
    {% text value: "Header" %}
  {% enddrawer_header %}
  {% navigation_drawer_destination label: "Inbox" icon: "inbox" %}
  {% navigation_drawer_destination label: "Starred" icon: "star" %}
{% endnavigation_drawer %}
''',
    );

    expect(find.byType(NavigationDrawer), findsOneWidget);
    expect(find.byType(NavigationDrawerDestination), findsNWidgets(2));
    expect(find.byType(DrawerHeader), findsOneWidget);
    expect(find.text('Header'), findsOneWidget);
  });
}
