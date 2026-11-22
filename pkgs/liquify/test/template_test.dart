import 'package:liquify/src/template.dart';
import 'package:test/test.dart';

void main() {
  group('Template', () {
    test('sync render', () {
      final template = Template.parse(
        'Hello {{ name }}!',
        data: {'name': 'World'},
      );
      expect(template.render(), equals('Hello World!'));
    });

    test('async render', () async {
      final template = Template.parse(
        'Hello {{ name }}!',
        data: {'name': 'World'},
      );
      expect(await template.renderAsync(), equals('Hello World!'));
    });

    test('async render with complex template', () async {
      final template = Template.parse(
        '''
        {% for item in items %}
          {% if item > 2 %}
            {{ item }}
          {% endif %}
        {% endfor %}
      ''',
        data: {
          'items': [1, 2, 3, 4, 5],
        },
      );

      final result = await template.renderAsync();
      expect(result.replaceAll(RegExp(r'\s+'), ' ').trim(), '3 4 5');
    });

    test('buffer clearing', () async {
      final template = Template.parse('{{ value }}', data: {'value': 'test'});

      // First render
      expect(await template.renderAsync(clearBuffer: false), equals('test'));

      // Second render should append to buffer if not cleared
      expect(
        await template.renderAsync(clearBuffer: false),
        equals('testtest'),
      );

      // Third render should start fresh with cleared buffer
      expect(await template.renderAsync(clearBuffer: true), equals('test'));
    });

    test('loop continuation is scoped to each render', () async {
      final template = Template.parse(
        '{% if true %}{% for n in (1..3) offset:continue limit:1 %}'
        '{{n}}{% endfor %}{% endif %}|'
        '{% for n in (1..3) offset:continue %}{{n}}{% endfor %}',
      );

      expect(template.render(), '1|23');
      expect(template.render(), '1|23');
      expect(await template.renderAsync(), '1|23');
      expect(await template.renderAsync(), '1|23');
    });

    test('evaluates chained dynamic and negative lookups', () async {
      final template = Template.parse(
        '{{ rows[key].name }}|{{ data.rows[-1].name }}|{{ text.missing }}',
        data: {
          'key': 0,
          'rows': [
            {'name': 'first'},
          ],
          'data': {
            'rows': [
              {'name': 'last'},
            ],
          },
          'text': 'ignored',
        },
      );

      expect(template.render(), 'first|last|');
      expect(await template.renderAsync(), 'first|last|');
    });

    test('renders the Liquid string representation of collections', () async {
      final template = Template.parse(
        '{{ items }}|{{ record }}|{{ record.first }}',
        data: {
          'items': [
            1,
            null,
            [2, 3],
          ],
          'record': {'key': 'value'},
        },
      );

      expect(template.render(), '123|{"key"=>"value"}|keyvalue');
      expect(await template.renderAsync(), '123|{"key"=>"value"}|keyvalue');
    });

    test('a trim marker consumes the entire preceding whitespace run', () {
      final template = Template.parse(
        'A \r\n\t {%- if true -%} B {%- endif -%} C',
      );

      expect(template.render(), 'ABC');
    });

    test('uses Liquid collection semantics for for and tablerow', () async {
      final template = Template.parse(
        '{% for c in text limit:0 offset:9 %}{{c}}{% endfor %}|'
        '{% tablerow p in record cols:1 %}{{p.first}}:'
        '{{tablerowloop.col0}}:{{tablerowloop.col_last}}{% endtablerow %}|'
        '{% tablerow x in empty_list %}{{x}}{% endtablerow %}',
        data: {
          'text': 'abc',
          'record': {'a': 1, 'b': 2},
          'empty_list': [],
        },
      );
      const expected =
          'abc|<tr class="row1">\n<td class="col1">a:0:true</td>'
          '</tr>\n<tr class="row2"><td class="col1">b:0:true</td></tr>\n'
          '|<tr class="row1">\n</tr>\n';

      expect(template.render(), expected);
      expect(await template.renderAsync(), expected);
    });

    test('context updates between renders', () async {
      final template = Template.parse('{{ greeting }} {{ name }}!');

      template.updateContext({'greeting': 'Hello', 'name': 'World'});
      expect(await template.renderAsync(), equals('Hello World!'));

      template.updateContext({'greeting': 'Goodbye'});
      expect(await template.renderAsync(), equals('Goodbye World!'));
    });
  });
}
