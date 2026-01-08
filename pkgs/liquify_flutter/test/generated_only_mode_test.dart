// Test that generated-only mode works for all generated tags
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquify/liquify.dart';
import 'package:liquify_flutter/liquify_flutter.dart';

Future<void> pumpGeneratedOnly(
  WidgetTester tester,
  String template, {
  Map<String, dynamic> data = const {},
}) async {
  final env = Environment();
  env.setRegister('_liquify_flutter_generated_only', true);
  env.setRegister('_liquify_flutter_strict_props', true);
  env.setRegister('_liquify_flutter_strict_tags', true);
  registerFlutterTags(environment: env);
  final widget = FlutterTemplate.parse(
    template,
    environment: env,
    data: data,
  ).render();
  await tester.pumpWidget(
    MaterialApp(
      home: ScaffoldMessenger(
        child: Scaffold(body: widget),
      ),
    ),
  );
}

class TapActionDrop extends Drop {
  TapActionDrop(this.onTap) {
    invokable = const [#tap, #clicked];
  }
  final VoidCallback onTap;
  @override
  dynamic invoke(Symbol symbol) {
    onTap();
    return null;
  }
}

void main() {
  group('generated-only mode', () {
    testWidgets('text widget', (tester) async {
      await pumpGeneratedOnly(tester, '{% text data: "Hello" %}');
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('row with children', (tester) async {
      await pumpGeneratedOnly(tester, '''
{% row %}{% text data: "A" %}{% text data: "B" %}{% endrow %}
      ''');
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('column with children', (tester) async {
      await pumpGeneratedOnly(tester, '''
{% column %}{% text data: "A" %}{% text data: "B" %}{% endcolumn %}
      ''');
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('container', (tester) async {
      await pumpGeneratedOnly(tester, '''
{% container %}{% text data: "Inside" %}{% endcontainer %}
      ''');
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('scaffold', (tester) async {
      await pumpGeneratedOnly(tester, '''
{% scaffold %}{% text data: "Body" %}{% endscaffold %}
      ''');
      // There are 2 scaffolds - one from pumpGeneratedOnly wrapper, one from template
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('gesture_detector with onTap', (tester) async {
      var tapped = false;
      await pumpGeneratedOnly(tester, '''
{% gesture_detector onTap: onTap %}{% text data: "Tap" %}{% endgesture_detector %}
      ''', data: {
        'onTap': () { tapped = true; },
      });
      await tester.tap(find.text('Tap'));
      expect(tapped, isTrue);
    });

    testWidgets('elevated_button with onPressed', (tester) async {
      var pressed = false;
      await pumpGeneratedOnly(tester, '''
{% elevated_button onPressed: onPressed %}{% text data: "Press" %}{% endelevated_button %}
      ''', data: {
        'onPressed': TapActionDrop(() { pressed = true; }),
      });
      await tester.tap(find.text('Press'));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('list_view with children', (tester) async {
      await pumpGeneratedOnly(tester, '''
{% list_view %}{% text data: "Item 1" %}{% text data: "Item 2" %}{% endlist_view %}
      ''');
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('stack with positioned', (tester) async {
      await pumpGeneratedOnly(tester, '''
{% stack %}
  {% positioned left: 0 top: 0 %}{% text data: "TL" %}{% endpositioned %}
{% endstack %}
      ''');
      expect(find.byType(Stack), findsWidgets);
      expect(find.byType(Positioned), findsOneWidget);
    });

    testWidgets('padding', (tester) async {
      await pumpGeneratedOnly(tester, '''
{% padding padding: 16 %}{% text data: "Padded" %}{% endpadding %}
      ''');
      expect(find.byType(Padding), findsOneWidget);
    });

    testWidgets('center', (tester) async {
      await pumpGeneratedOnly(tester, '''
{% center %}{% text data: "Centered" %}{% endcenter %}
      ''');
      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('sized_box', (tester) async {
      await pumpGeneratedOnly(tester, '''
{% sized_box width: 100 height: 50 %}{% endsized_box %}
      ''');
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('opacity', (tester) async {
      await pumpGeneratedOnly(tester, '''
{% opacity opacity: 0.5 %}{% text data: "Faded" %}{% endopacity %}
      ''');
      expect(find.byType(Opacity), findsOneWidget);
    });

    testWidgets('card', (tester) async {
      await pumpGeneratedOnly(tester, '''
{% card %}{% text data: "Card content" %}{% endcard %}
      ''');
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('icon', (tester) async {
      await pumpGeneratedOnly(tester, '''
{% icon icon: "add" %}{% endicon %}
      ''');
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('checkbox', (tester) async {
      await pumpGeneratedOnly(tester, '''
{% checkbox value: true onChanged: onChanged %}{% endcheckbox %}
      ''', data: {
        'onChanged': (bool? _) {},
      });
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('switch', (tester) async {
      await pumpGeneratedOnly(tester, '''
{% switch value: true onChanged: onChanged %}{% endswitch %}
      ''', data: {
        'onChanged': (bool _) {},
      });
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('slider', (tester) async {
      await pumpGeneratedOnly(tester, '''
{% slider value: 0.5 onChanged: onChanged %}{% endslider %}
      ''', data: {
        'onChanged': (double _) {},
      });
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('text_field', (tester) async {
      await pumpGeneratedOnly(tester, '''
{% text_field %}{% endtext_field %}
      ''');
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('divider', (tester) async {
      await pumpGeneratedOnly(tester, '''
{% divider %}{% enddivider %}
      ''');
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('circular_progress_indicator', (tester) async {
      await pumpGeneratedOnly(tester, '''
{% circular_progress_indicator %}{% endcircular_progress_indicator %}
      ''');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('linear_progress_indicator', (tester) async {
      await pumpGeneratedOnly(tester, '''
{% linear_progress_indicator %}{% endlinear_progress_indicator %}
      ''');
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
