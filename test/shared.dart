import 'dart:convert';

import 'package:liquify/parser.dart';
import 'package:liquify/src/util.dart';

void testParser(String source, void Function(Document document) testFunction) {
  try {
    final document = Document(parseInput(source));
    try {
      testFunction(document);
    } catch (e) {
      print('Error: $e');
      printAST(document, 0);

      JsonEncoder encoder = JsonEncoder.withIndent('  ');
      final encoded = encoder.convert(document);
      print(encoded);

      return;
    }
  } catch (e) {
    rethrow;
  }
}
