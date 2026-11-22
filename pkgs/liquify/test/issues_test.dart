import 'package:liquify/liquify.dart' show Template;
import 'package:liquify/src/context.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:test/test.dart';
import 'support/shared.dart';

void main() {
  late Evaluator evaluator;

  setUp(() {
    evaluator = Evaluator(Environment());
  });

  tearDown(() {
    evaluator.context.clear();
  });

  test("issue #23", () async {
    await testParser(
      '''
{% assign name = "hello" %}
{% if name contains "ello" %}
These shoes are awesome! {{name}}
{% endif %}
    ''',
      (document) {
        evaluator.evaluateNodes(document.children);
        expect(
          evaluator.buffer.toString().trim(),
          equals('These shoes are awesome! hello'),
        );
      },
    );
  });

  group('issue #43', () {
    test('for treats a negative offset as zero', () async {
      final template = Template.parse(
        '{% for i in (0..3) offset: -2 %}{{ i }} {% endfor %}',
      );

      expect(template.render(), '0 1 2 3 ');
      expect(await template.renderAsync(), '0 1 2 3 ');
    });

    test('descending range produces empty output', () async {
      final template = Template.parse(
        "{{ (start..end) | join: '#' }}",
        data: {'start': 5, 'end': 1},
      );

      expect(template.render(), isEmpty);
      expect(await template.renderAsync(), isEmpty);
    });

    test('for runs its else block for a descending range', () async {
      final template = Template.parse(
        '{% for i in (5..1) %}{{ i }}{% else %}empty{% endfor %}',
      );

      expect(template.render(), 'empty');
      expect(await template.renderAsync(), 'empty');
    });

    test('tablerow treats a negative offset as zero', () async {
      final template = Template.parse(
        '{% tablerow i in (1..3) offset: -1 %}{{ i }}{% endtablerow %}',
      );
      final expected = Template.parse(
        '{% tablerow i in (1..3) offset: 0 %}{{ i }}{% endtablerow %}',
      ).render();

      expect(template.render(), expected);
      expect(await template.renderAsync(), expected);
    });
  });
}
