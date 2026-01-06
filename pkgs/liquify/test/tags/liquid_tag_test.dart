import 'package:liquify/src/context.dart';
import 'package:liquify/src/evaluator.dart';
import '../support/shared.dart';
import '../support/golden_harness.dart';

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
        await testParser(
          '''
    {% liquid
    assign my_variable = "string"
    %}
    ''',
          (document) {
            evaluator.evaluateNodes(document.children);
            expect(evaluator.context.getVariable('my_variable'), 'string');
          },
        );
      });

      test('ignores single-line comment', () async {
        await testParser(
          '''
    {% liquid
    {# This is a single-line comment #}
    assign my_variable = "string"
    %}
    ''',
          (document) {
            evaluator.evaluateNodes(document.children);
            expect(evaluator.context.getVariable('my_variable'), 'string');
          },
        );
      });

      test('multiple operations', () async {
        await testParser(
          '''
    {% liquid
    assign x = 5
    assign y = x | plus: 3
    assign z = y | times: 2
    %}
    {{ z }}
    ''',
          (document) {
            evaluator.evaluateNodes(document.children);
            expect(evaluator.buffer.toString().trim(), '16');
          },
        );
      });

      test('ignores multi-line comment', () async {
        await testParser(
          '''
    {% liquid
    ###############################
    # This is a comment
    # across multiple lines
    ###############################
    assign my_variable = "string"
    %}
    ''',
          (document) {
            evaluator.evaluateNodes(document.children);
            expect(evaluator.context.getVariable('my_variable'), 'string');
          },
        );
      });

      test('supports shorthand syntax', () async {
        await testParser(
          '''
    {%- liquid
      for value in array
        echo value
        unless forloop.last
          echo '#'
        endunless
      endfor
    -%}
    ''',
          (document) {
            evaluator.context.setVariable('array', [1, 2, 3]);
            evaluator.evaluateNodes(document.children);
            expect(evaluator.buffer.toString(), '1#2#3');
          },
        );
      });

      test('supports shorthand syntax with assignments and filters', () async {
        await testParser(
          '''
    {%- liquid
      for value in array
        assign double_value = value | times: 2
        echo double_value | times: 2
        unless forloop.last
          echo '#'
        endunless
      endfor
    
      echo '#'
      echo double_value
    -%}
    ''',
          (document) {
            evaluator.context.setVariable('array', [1, 2, 3]);
            evaluator.evaluateNodes(document.children);
            expect(evaluator.buffer.toString(), '4#8#12#6');
          },
        );
      });

      test('handles empty tag', () async {
        await testParser(
          '{% liquid %}',
          (document) {
            evaluator.evaluateNodes(document.children);
            expect(evaluator.buffer.toString(), '');
          },
        );
      });

      test('handles lines containing only whitespace', () async {
        await testParser(
          '{% liquid \n'
          '  echo \'hello \' \n'
          '    \n'
          '\t\n'
          '  echo \'goodbye\'\n'
          '%}',
          (document) {
            evaluator.evaluateNodes(document.children);
            expect(evaluator.buffer.toString(), 'hello goodbye');
          },
        );
      });

      test('fails with carriage return terminated tags', () async {
        final src = [
          '{%- liquid',
          '  for value in array',
          '    echo value',
          '    unless forloop.last',
          '      echo "#"',
          '    endunless',
          'endfor',
          '-%}',
        ].join('\r');
        expect(
          () => testParser(src, (_) {}),
          throwsException,
        );
      });
    });

    group('async evaluation', () {
      test('assigns variable', () async {
        await testParser(
          '''
    {% liquid
    assign my_variable = "string"
    %}
    ''',
          (document) async {
            await evaluator.evaluateNodesAsync(document.children);
            expect(evaluator.context.getVariable('my_variable'), 'string');
          },
        );
      });

      test('multiple operations', () async {
        await testParser(
          '''
    {% liquid
    assign x = 5
    assign y = x | plus: 3
    assign z = y | times: 2
    %}
    {{ z }}
    ''',
          (document) async {
            await evaluator.evaluateNodesAsync(document.children);
            expect(evaluator.buffer.toString().trim(), '16');
          },
        );
      });

      test('ignores single-line comment', () async {
        await testParser(
          '''
    {% liquid
    # This is a single-line comment 
    assign my_variable = "string"
    %}
    ''',
          (document) async {
            await evaluator.evaluateNodesAsync(document.children);
            expect(evaluator.context.getVariable('my_variable'), 'string');
          },
        );
      });

      test('ignores multi-line comment', () async {
        await testParser(
          '''
    {% 
    ###############################
    # This is a comment
    # across multiple lines
    ###############################
    %}
    ''',
          (document) async {
            await evaluator.evaluateNodesAsync(document.children);
            expect(evaluator.buffer.toString().trim(), '');
          },
        );
      });

      test('supports shorthand syntax', () async {
        await testParser(
          '''
    {%- liquid
      for value in array
        echo value
        unless forloop.last
          echo '#'
        endunless
      endfor
    -%}
    ''',
          (document) async {
            evaluator.context.setVariable('array', [1, 2, 3]);
            await evaluator.evaluateNodesAsync(document.children);
            expect(evaluator.buffer.toString(), '1#2#3');
          },
        );
      });

      test('supports shorthand syntax with assignments and filters', () async {
        await testParser(
          '''
    {%- liquid
      for value in array
        assign double_value = value | times: 2
        echo double_value | times: 2
        unless forloop.last
          echo '#'
        endunless
      endfor
    
      echo '#'
      echo double_value
    -%}
    ''',
          (document) async {
            evaluator.context.setVariable('array', [1, 2, 3]);
            await evaluator.evaluateNodesAsync(document.children);
            expect(evaluator.buffer.toString(), '4#8#12#6');
          },
        );
      });

      test('handles empty tag', () async {
        await testParser(
          '{% liquid %}',
          (document) async {
            await evaluator.evaluateNodesAsync(document.children);
            expect(evaluator.buffer.toString(), '');
          },
        );
      });

      test('handles lines containing only whitespace', () async {
        await testParser(
          '{% liquid \n'
          '  echo \'hello \' \n'
          '    \n'
          '\t\n'
          '  echo \'goodbye\'\n'
          '%}',
          (document) async {
            await evaluator.evaluateNodesAsync(document.children);
            expect(evaluator.buffer.toString(), 'hello goodbye');
          },
        );
      });

      test('fails with carriage return terminated tags', () async {
        final src = [
          '{%- liquid',
          '  for value in array',
          '    echo value',
          '    unless forloop.last',
          '      echo "#"',
          '    endunless',
          'endfor',
          '-%}',
        ].join('\r');
        expect(
          () => testParser(src, (_) {}),
          throwsException,
        );
      });
    });
  });
}
