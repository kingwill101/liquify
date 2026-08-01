import 'dart:convert';

import 'package:liquify/liquify.dart';
import 'package:test/test.dart';

import '../web/builtin_examples.dart';

void main() {
  group('playground built-in examples', () {
    for (final entry in builtinExamples.entries) {
      test('${entry.key} renders its expected output', () async {
        final example = entry.value;
        final data = jsonDecode(example.contextJson) as Map<String, dynamic>;
        final root = MapRoot(Map<String, String>.from(example.files));
        final template = Template.fromFile(example.entryFile, root, data: data);

        final output = await template.renderAsync();

        for (final fragment in example.expectedOutput) {
          expect(output, contains(fragment), reason: 'Missing: $fragment');
        }
      });
    }
  });
}
