import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquify/liquify.dart';
import 'package:liquify_flutter/liquify_flutter.dart';

import 'test_utils.dart';

void main() {
  testWidgets('named args override property tags', (tester) async {
    await pumpTemplate(
      tester,
      '{% container padding: 4 %}'
      '{% padding all: 12 %}'
      '{% text value: "Box" %}'
      '{% endcontainer %}',
    );

    final containerFinder =
        find.ancestor(of: find.text('Box'), matching: find.byType(Container));
    final container = tester.widget<Container>(containerFinder.first);
    expect(container.padding, const EdgeInsets.all(4));
  });

  testWidgets('property tags set global defaults', (tester) async {
    await pumpTemplate(
      tester,
      '{% padding all: 10 %}'
      '{% container %}'
      '{% text value: "Box" %}'
      '{% endcontainer %}',
    );

    final containerFinder =
        find.ancestor(of: find.text('Box'), matching: find.byType(Container));
    final container = tester.widget<Container>(containerFinder.first);
    expect(container.padding, const EdgeInsets.all(10));
  });

  testWidgets('property defaults apply to text and icon', (tester) async {
    await pumpTemplate(
      tester,
      '{% background color: "#ff0000" %}'
      '{% text value: "Hello" %}'
      '{% icon name: "favorite" %}',
    );

    final textWidget = tester.widget<Text>(find.text('Hello'));
    expect(textWidget.style?.color, const Color(0xFFFF0000));

    final iconWidget = tester.widget<Icon>(find.byType(Icon));
    expect(iconWidget.color, const Color(0xFFFF0000));
  });

  testWidgets('size defaults apply to spacer width and height', (tester) async {
    await pumpTemplate(
      tester,
      '{% size width: 120 height: 80 %}'
      '{% spacer %}',
    );

    final sizedBoxFinder = find.byWidgetPredicate(
      (widget) =>
          widget is SizedBox &&
          widget.width == 120 &&
          widget.height == 80,
    );
    expect(sizedBoxFinder, findsOneWidget);
  });

  testWidgets('edge_inset filter builds EdgeInsets', (tester) async {
    await pumpTemplate(
      tester,
      '{% assign pad = "" | edge_inset: all: 6 %}'
      '{% container padding: pad %}'
      '{% text value: "Box" %}'
      '{% endcontainer %}',
    );

    final containerFinder =
        find.ancestor(of: find.text('Box'), matching: find.byType(Container));
    final container = tester.widget<Container>(containerFinder.first);
    expect(container.padding, const EdgeInsets.all(6));
  });

  testWidgets('property tags do not render output', (tester) async {
    final env = Environment();
    registerFlutterTags(environment: env);
    final widget = FlutterTemplate.parse(
      '{% padding all: 8 %}{% text value: "Only" %}',
      environment: env,
    ).render();

    expect(widget, isA<Text>());
  });
}
