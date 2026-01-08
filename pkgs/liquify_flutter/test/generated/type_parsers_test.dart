import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquify_flutter/src/generated/callback_drops.dart';
import 'package:liquify_flutter/src/generated/type_parsers.dart';

void main() {
  test('parseGeneratedMainAxisAlignment resolves strings', () {
    expect(
      parseGeneratedMainAxisAlignment('center'),
      MainAxisAlignment.center,
    );
    expect(
      parseGeneratedMainAxisAlignment('SpaceBetween'),
      MainAxisAlignment.spaceBetween,
    );
  });

  test('parseGeneratedBoxConstraints builds constraints', () {
    final constraints = parseGeneratedBoxConstraints({
      'minWidth': 12,
      'maxWidth': 120,
      'minHeight': 4,
      'maxHeight': 40,
    });
    expect(constraints, isNotNull);
    expect(constraints!.minWidth, 12);
    expect(constraints.maxWidth, 120);
    expect(constraints.minHeight, 4);
    expect(constraints.maxHeight, 40);
  });

  test('parseGeneratedBoxConstraints supports named constructors', () {
    final constraints = parseGeneratedBoxConstraints({
      'constructor': 'tightFor',
      'args': {'width': 80, 'height': 24},
    });
    expect(constraints, isNotNull);
    expect(constraints!.minWidth, 80);
    expect(constraints.maxWidth, 80);
    expect(constraints.minHeight, 24);
    expect(constraints.maxHeight, 24);
  });

  test('GeneratedGestureTapCallbackDrop invokes callback', () {
    var tapped = false;
    final drop = GeneratedGestureTapCallbackDrop(() {
      tapped = true;
    });
    drop.invoke(#tap);
    expect(tapped, isTrue);
  });
}
