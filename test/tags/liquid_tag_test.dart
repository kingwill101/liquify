import 'package:liquify/src/context.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:test/test.dart';

import '../shared.dart';

void main() {
  late Evaluator evaluator;

  setUp(() {
    evaluator = Evaluator(Environment());
  });

  tearDown(() {
    evaluator.context.clear();
  });
  group('Liquid Tag', () {
    group('sync evaluation', () {
      test('assigns variable', () async {
        await testParser('''
    {% liquid
    assign my_variable = "string"
    %}
    ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.context.getVariable('my_variable'), 'string');
        });
      });

      test('ignores single-line comment', () async {
        await testParser('''
    {% liquid
    {# This is a single-line comment #}
    assign my_variable = "string"
    %}
    ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.context.getVariable('my_variable'), 'string');
        });
      });

      test('multiple operations', () async {
        await testParser('''
    {% liquid
    assign x = 5
    assign y = x | plus: 3
    assign z = y | times: 2
    %}
    {{ z }}
    ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().trim(), '16');
        });
      });

      test('ignores multi-line comment', () async {
        await testParser('''
    {% liquid
    ###############################
    # This is a comment
    # across multiple lines
    ###############################
    assign my_variable = "string"
    %}
    ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.context.getVariable('my_variable'), 'string');
        });
      });
    });

    group('async evaluation', () {
      test('assigns variable', () async {
        await testParser('''
    {% liquid
    assign my_variable = "string"
    %}
    ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.context.getVariable('my_variable'), 'string');
        });
      });

      test('multiple operations', () async {
        await testParser('''
    {% liquid
    assign x = 5
    assign y = x | plus: 3
    assign z = y | times: 2
    %}
    {{ z }}
    ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().trim(), '16');
        });
      });

      test('ignores single-line comment', () async {
        await testParser('''
    {% liquid
    # This is a single-line comment 
    assign my_variable = "string"
    %}
    ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.context.getVariable('my_variable'), 'string');
        });
      });

      test('ignores multi-line comment', () async {
        await testParser('''
    {% 
    ###############################
    # This is a comment
    # across multiple lines
    ###############################
    %}
    ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().trim(), '');
        });
      });
    });
  });
}
