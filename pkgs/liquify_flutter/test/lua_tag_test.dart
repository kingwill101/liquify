import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquify/liquify.dart';
import 'package:liquify_flutter/liquify_flutter.dart';

Future<Widget> _renderLuaTemplate(String template) async {
  final env = Environment();
  env.setRegister('_liquify_flutter_strict_props', true);
  env.setRegister('_liquify_flutter_strict_tags', true);
  registerFlutterTags(environment: env);
  return FlutterTemplate.parse(template, environment: env).renderAsync();
}

void main() {
  testWidgets('lua tag assigns data for Liquid templates', (tester) async {
    const template = r'''
{% lua assign: payload %}
  return { label = "Lua", count = 3 }
{% endlua %}
{% text value: payload.label %}
{% text value: payload.count %}
''';
    final widget = await _renderLuaTemplate(template);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
    expect(find.text('Lua'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  test('lua tag rejects unknown api in strict mode', () async {
    const template = r'''
{% lua %}
  unknown_api()
{% endlua %}
''';
    await expectLater(_renderLuaTemplate(template), throwsA(isA<Exception>()));
  });
}
