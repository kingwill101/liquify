import 'dart:async';
import 'dart:convert';

import 'package:liquify/liquify.dart';
import 'package:liquify/parser.dart';

FutureOr<void> testParser(String source,
    FutureOr<void> Function(Document document) testFunction) async {
  try {
    final document = Document(parseInput(source));
    try {
      await testFunction(document);
    } catch (e) {
      print('Error: $e');
      printAST(document, 0);

      JsonEncoder encoder = JsonEncoder.withIndent('  ');
      final encoded = encoder.convert(document);
      print(encoded);

      rethrow;
    }
  } catch (e) {
    rethrow;
  }
}
