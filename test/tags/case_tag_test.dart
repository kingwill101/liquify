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
    test('case tag with single match', () {
      testParser(
          '{% assign handle = "cake" %}'
          '{% case handle %}'
          '{% when "cake" %}'
          'This is a cake'
          '{% when "cookie" %}'
          'This is a cookie'
          '{% else %}'
          'This is not a cake nor a cookie'
          '{% endcase %}',
          (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString().trim(), 'This is a cake');
      });
    });
    test('case tag with multiple values in when', () {
      testParser(
          '{% assign handle = "biscuit" %}'
          '{% case handle %}'
          '{% when "cake" %}'
          'This is a cake'
          '{% when "cookie", "biscuit" %}'
          'This is a cookie or biscuit'
          '{% else %}'
          'This is something else'
          '{% endcase %}', (document) {
        evaluator.evaluate(document);
        expect(
            evaluator.buffer.toString().trim(), 'This is a cookie or biscuit');
      });
    });
  });

  test('case tag with else condition', () {
    testParser(
        '{% assign handle = "pie" %}'
        '{% case handle %}'
        '{% when "cake" %}'
        'This is a cake'
        '{% when "cookie" %}'
        'This is a cookie'
        '{% else %}'
        'This is neither a cake nor a cookie'
        '{% endcase %}', (document) {
      evaluator.evaluate(document);
      expect(evaluator.buffer.toString().trim(),
          'This is neither a cake nor a cookie');
    });
  });

  test('case tag with no matching condition and no else', () {
    testParser(
        '{% assign handle = "pie" %}'
        '{% case handle %}'
        '{% when "cake" %}'
        'This is a cake'
        '{% when "cookie" %}'
        'This is a cookie'
        '{% endcase %}', (document) {
      evaluator.evaluate(document);
      expect(evaluator.buffer.toString(), '');
    });
  });
}