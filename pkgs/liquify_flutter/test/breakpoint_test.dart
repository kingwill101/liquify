import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquify/liquify.dart';
import 'package:liquify_flutter/liquify_flutter.dart';

void main() {
  Future<void> pumpBreakpointTemplate(
    WidgetTester tester,
    String template, {
    required Size size,
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: size, devicePixelRatio: 1.0),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final env = Environment();
              env.setRegister('_liquify_flutter_context', context);
              registerFlutterTags(environment: env);
              return FlutterTemplate.parse(template, environment: env).render();
            },
          ),
        ),
      ),
    );
  }

  testWidgets('breakpoint tag renders matching block', (tester) async {
    await pumpBreakpointTemplate(
      tester,
      size: const Size(500, 800),
      '{% breakpoint xs %}{% text value: "xs" %}{% endbreakpoint %}'
      '{% breakpoint sm %}{% text value: "sm" %}{% endbreakpoint %}'
      '{% breakpoint md %}{% text value: "md" %}{% endbreakpoint %}',
    );

    expect(find.text('xs'), findsOneWidget);
    expect(find.text('sm'), findsNothing);
    expect(find.text('md'), findsNothing);
  });

  testWidgets('breakpoint tag supports min/max and except', (tester) async {
    await pumpBreakpointTemplate(
      tester,
      size: const Size(800, 600),
      '{% breakpoint min: "sm" max: "lg" %}'
      '{% text value: "between" %}'
      '{% endbreakpoint %}'
      '{% breakpoint except: "md" %}'
      '{% text value: "not-md" %}'
      '{% endbreakpoint %}',
    );

    expect(find.text('between'), findsOneWidget);
    expect(find.text('not-md'), findsNothing);
  });

  testWidgets('responsive filter returns breakpoint value', (tester) async {
    await pumpBreakpointTemplate(
      tester,
      size: const Size(600, 800),
      '{% assign size = "" | responsive: xs: 8, sm: 12, md: 16, default: 20 %}'
      '{% text value: size %}',
    );

    expect(find.text('12'), findsOneWidget);
  });
}
