import 'dart:convert';

import 'package:liquify/parser.dart';
import 'package:liquify/src/grammar/grammar.dart';
import 'package:liquify/src/registry.dart';
import 'package:liquify/src/util.dart';
import 'package:petitparser/debug.dart';
import 'package:petitparser/reflection.dart';
import 'package:test/test.dart';

Result parse(String input,
    {bool enableTrace = false, bool shouldLint = false}) {
  final parser = LiquidGrammar().build();

  if (shouldLint) {
    print(linter(parser).join('\n\n'));
  }

  if (enableTrace) {
    return trace(parser).parse(input);
  } else {
    return parser.parse(input);
  }
}

void testParser(String source, void Function(Document document) testFunction) {
  registerBuiltIns();

  try {
    final result = parse(source);
    if (result is Success) {
      final document = result.value as Document;
      try {
        testFunction(document);
      } catch (e) {
        print('Error: $e');
        printAST(document, 0);

        JsonEncoder encoder = JsonEncoder.withIndent('  ');
        final encoded = encoder.convert(document);
        print(encoded);

        rethrow;
      }
    } else {
      final lineAndColumn = Token.lineAndColumnOf(source, result.position);

      fail(
          'Parsing failed:  Error ${result.message} at ${lineAndColumn.join(':')}');
    }
  } catch (e, trace) {
    print("source: $source");
    print('Error: $e');
    print('Trace: $trace');
    rethrow;
  }
}
