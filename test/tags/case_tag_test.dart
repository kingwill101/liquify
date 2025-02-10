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
  group('Case/when tag', () {
    group('sync evaluation', () {
      test('case tag with single match', () async {
        await testParser(
            '{% assign handle = "cake" %}'
            '{% case handle %}'
            '{% when "cake" %}'
            'This is a cake'
            '{% when "cookie" %}'
            'This is a cookie'
            '{% else %}'
            'This is not a cake nor a cookie'
            '{% endcase %}', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().trim(), 'This is a cake');
        });
      });

      test('case tag with multiple values in when', () async {
        await testParser(
            '{% assign handle = "biscuit" %}'
            '{% case handle %}'
            '{% when "cake" %}'
            'This is a cake'
            '{% when "cookie", "biscuit" %}'
            'This is a cookie or biscuit'
            '{% else %}'
            'This is something else'
            '{% endcase %}', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().trim(),
              'This is a cookie or biscuit');
        });
      });

      test('case tag with else condition', () async {
        await testParser(
            '{% assign handle = "pie" %}'
            '{% case handle %}'
            '{% when "cake" %}'
            'This is a cake'
            '{% when "cookie" %}'
            'This is a cookie'
            '{% else %}'
            'This is neither a cake nor a cookie'
            '{% endcase %}', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().trim(),
              'This is neither a cake nor a cookie');
        });
      });

      test('case tag with no matching condition and no else', () async {
        await testParser(
            '{% assign handle = "pie" %}'
            '{% case handle %}'
            '{% when "cake" %}'
            'This is a cake'
            '{% when "cookie" %}'
            'This is a cookie'
            '{% endcase %}', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), '');
        });
      });
    });

    group('async evaluation', () {
      test('case tag with single match', () async {
        await testParser(
            '{% assign handle = "cake" %}'
            '{% case handle %}'
            '{% when "cake" %}'
            'This is a cake'
            '{% when "cookie" %}'
            'This is a cookie'
            '{% else %}'
            'This is not a cake nor a cookie'
            '{% endcase %}', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().trim(), 'This is a cake');
        });
      });

      test('case tag with multiple values in when', () async {
        await testParser(
            '{% assign handle = "biscuit" %}'
            '{% case handle %}'
            '{% when "cake" %}'
            'This is a cake'
            '{% when "cookie", "biscuit" %}'
            'This is a cookie or biscuit'
            '{% else %}'
            'This is something else'
            '{% endcase %}', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().trim(),
              'This is a cookie or biscuit');
        });
      });

      test('case tag with else condition', () async {
        await testParser(
            '{% assign handle = "pie" %}'
            '{% case handle %}'
            '{% when "cake" %}'
            'This is a cake'
            '{% when "cookie" %}'
            'This is a cookie'
            '{% else %}'
            'This is neither a cake nor a cookie'
            '{% endcase %}', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().trim(),
              'This is neither a cake nor a cookie');
        });
      });

      test('case tag with no matching condition and no else', () async {
        await testParser(
            '{% assign handle = "pie" %}'
            '{% case handle %}'
            '{% when "cake" %}'
            'This is a cake'
            '{% when "cookie" %}'
            'This is a cookie'
            '{% endcase %}', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), '');
        });
      });
    });
  });
}
