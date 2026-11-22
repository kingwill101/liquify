@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:liquify/liquify.dart' show MapRoot, Template;
import 'package:test/test.dart';

Future<void> main() async {
  final library = await Isolate.resolvePackageUri(
    Uri.parse('package:liquify/liquify.dart'),
  );
  final fixtureFile = File.fromUri(
    library!.resolve('../tool/liquid_compat/issue_42.json'),
  );
  final fixtures = jsonDecode(await fixtureFile.readAsString()) as List;

  group('issue #42 Shopify Liquid compatibility', () {
    for (final fixture in fixtures.cast<Map<String, dynamic>>()) {
      test(fixture['label'] as String, () async {
        final partials = fixture['partials'] as Map<String, dynamic>? ?? {};
        Template template() => Template.parse(
          fixture['source'] as String,
          data: fixture['data'] as Map<String, dynamic>? ?? {},
          root: MapRoot(partials.cast<String, String>()),
        );

        final expectedFragment = fixture['expected_contains'] as String?;
        final expected = expectedFragment == null
            ? equals(fixture['expected'])
            : contains(expectedFragment);
        expect(template().render(), expected);
        expect(await template().renderAsync(), expected);
      });
    }
  });
}
