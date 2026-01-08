import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquify/liquify.dart';
import 'package:liquify_flutter/liquify_flutter.dart';

Future<void> pumpLuaTemplate(
  WidgetTester tester,
  String template, {
  Map<String, dynamic> data = const {},
}) async {
  final env = Environment();
  env.setRegister('_liquify_flutter_generated_only', true);
  registerFlutterTags(environment: env);
  
  final widget = await FlutterTemplate.parse(
    template,
    environment: env,
    data: data,
  ).renderAsync();
  
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: widget)),
  );
}

void main() {
  group('Lua callback drops', () {
    testWidgets('callback() creates VoidCallback drop', (tester) async {
      await pumpLuaTemplate(tester, '''
{% lua assign: on_tap %}
  set("tapped", true)
  return callback(function()
    set("counter", (get("counter") or 0) + 1)
  end)
{% endlua %}
{% gesture_detector onTap: on_tap %}
  {% text data: "Tap me" %}
{% endgesture_detector %}
      ''');
      
      expect(find.text('Tap me'), findsOneWidget);
      await tester.tap(find.text('Tap me'));
      await tester.pump();
      // Callback should have been executed
    });

    testWidgets('callback1() creates ValueChanged drop', (tester) async {
      await pumpLuaTemplate(tester, '''
{% lua assign: on_changed %}
  return callback1(function(value)
    set("slider_value", value)
  end)
{% endlua %}
{% slider value: 0.5 onChanged: on_changed %}{% endslider %}
      ''');
      
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('Lua callback with counter state', (tester) async {
      await pumpLuaTemplate(tester, '''
{% lua assign: increment %}
  return callback(function()
    local current = get("count") or 0
    set("count", current + 1)
    log("Count incremented to: " .. (current + 1))
  end)
{% endlua %}
{% assign count = 0 %}
{% column %}
  {% text data: count %}
  {% elevated_button onPressed: increment %}
    {% text data: "Increment" %}
  {% endelevated_button %}
{% endcolumn %}
      ''');
      
      expect(find.text('Increment'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}
