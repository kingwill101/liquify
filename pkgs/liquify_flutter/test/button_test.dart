import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquify/liquify.dart';

import 'test_utils.dart';

void main() {
  testWidgets('button tag renders label and invokes drop action',
      (tester) async {
    var tapped = false;
    await pumpTemplate(
      tester,
      '{% text_button text: "Tap", action: tapAction %}',
      data: {'tapAction': TapActionDrop(() => tapped = true)},
    );

    final button = tester.widget<TextButton>(find.byType(TextButton));
    expect(button.child, isA<Text>());
    expect((button.child as Text).data, 'Tap');
    expect(button.onPressed, isNotNull);
    button.onPressed!();
    expect(tapped, isTrue);
  });

  testWidgets('button action string resolves from actions map',
      (tester) async {
    var tapped = false;
    await pumpTemplate(
      tester,
      '{% text_button text: "Tap", action: "do_it" %}',
      data: {
        'actions': {
          'do_it': () => tapped = true,
        },
      },
    );

    final button = tester.widget<TextButton>(find.byType(TextButton));
    expect(button.onPressed, isNotNull);
    button.onPressed!();
    expect(tapped, isTrue);
  });

  testWidgets('button action string resolves from actions drop',
      (tester) async {
    var tapped = false;
    await pumpTemplate(
      tester,
      '{% text_button text: "Tap", action: "do_it" %}',
      data: {'actions': NamedActionDrop(() => tapped = true)},
    );

    final button = tester.widget<TextButton>(find.byType(TextButton));
    expect(button.onPressed, isNotNull);
    button.onPressed!();
    expect(tapped, isTrue);
  });

  testWidgets('text_button renders icon variant', (tester) async {
    await pumpTemplate(
      tester,
      '{% text_button text: "Add" icon: "add" %}',
    );

    expect(find.byWidgetPredicate((widget) => widget is TextButton), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}

class NamedActionDrop extends Drop {
  NamedActionDrop(this.onTap) {
    invokable = const [#do_it];
  }

  final VoidCallback onTap;

  @override
  dynamic invoke(Symbol symbol) {
    onTap();
    return null;
  }
}
