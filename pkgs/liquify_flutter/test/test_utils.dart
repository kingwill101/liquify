import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquify/liquify.dart';
import 'package:liquify_flutter/liquify_flutter.dart';

Future<void> pumpTemplate(
  WidgetTester tester,
  String template, {
  Map<String, dynamic> data = const {},
  bool strictProps = true,
  bool strictTags = true,
}) async {
  final env = Environment();
  if (strictProps) {
    env.setRegister('_liquify_flutter_strict_props', true);
  }
  if (strictTags) {
    env.setRegister('_liquify_flutter_strict_tags', true);
  }
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
