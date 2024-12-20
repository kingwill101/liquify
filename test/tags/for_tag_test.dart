import 'package:test/test.dart';
import '../shared.dart';
import 'shared.dart';

void main() {
  late TagTestCase fixture;

  setUp(() {
    fixture = TagTestCase()..setUp();
  });

  tearDown(() {
    fixture.tearDown();
  });

  group('ForTag', () {
    test('basic iteration', () async {
      testParser('{% for item in (1..3) %}{{ item }}{% endfor %}',
          (document) async {
        await fixture.evaluator.evaluate(document);
        expect(fixture.evaluator.buffer.toString(), '123');
      });
    });

    test('else block', () async {
      testParser(
          '{% for item in (1..0) %}{{ item }}{% else %}No items{% endfor %}',
          (document) async {
        await fixture.evaluator.evaluate(document);
        expect(fixture.evaluator.buffer.toString(), 'No items');
      });
    });

    test('break tag', () async {
      testParser('''{% for item in (1..5) %}
           {% if item == 3 %}{% break %}{% endif %}
           {{ item }}
           {% endfor %}''', (document) async {
        await fixture.evaluator.evaluate(document);
        expect(
            fixture.evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ''),
            '12');
      });
    });

    test('continue tag', () async {
      testParser('''{% for item in (1..5) %}
           {% if item == 3 %}{% continue %}{% endif %}
           {{ item }}
           {% endfor %}''', (document) async {
        await fixture.evaluator.evaluate(document);
        expect(
            fixture.evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ''),
            '1245');
      });
    });

    test('limit parameter', () async {
      testParser('{% for item in (1..5) limit:3 %}{{ item }}{% endfor %}',
          (document) async {
        await fixture.evaluator.evaluate(document);
        expect(fixture.evaluator.buffer.toString(), '123');
      });
    });

    test('offset parameter', () async {
      testParser('{% for item in (1..5) offset:2 %}{{ item }}{% endfor %}',
          (document) async {
        await fixture.evaluator.evaluate(document);
        expect(fixture.evaluator.buffer.toString(), '345');
      });
    });

    test('reversed parameter', () async {
      testParser('{% for item in (1..3) reversed %}{{ item }}{% endfor %}',
          (document) async {
        await fixture.evaluator.evaluate(document);
        expect(fixture.evaluator.buffer.toString(), '321');
      });
    });

    test('forloop object properties', () async {
      testParser('''{% for item in (1..3) %}
           Index:{{ forloop.index }},
           Index0:{{ forloop.index0 }},
           First:{{ forloop.first }},
           Last:{{ forloop.last }}
           {% endfor %}''', (document) async {
        await fixture.evaluator.evaluate(document);
        expect(
            fixture.evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ''),
            'Index:1,Index0:0,First:true,Last:falseIndex:2,Index0:1,First:false,Last:falseIndex:3,Index0:2,First:false,Last:true');
      });
    });

    test('nested loops', () async {
      testParser('''{% for i in (1..2) %}
             {% for j in (1..2) %}
               {{i}}-{{j}}
             {% endfor %}
           {% endfor %}''', (document) async {
        await fixture.evaluator.evaluate(document);
        expect(
            fixture.evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ''),
            '1-11-22-12-2');
      });
    });
  });
}
