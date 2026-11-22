import 'package:liquify/liquify.dart';
import 'package:liquify/src/ast.dart' show TextNode;
import 'package:liquify/src/evaluator.dart';
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

    test(
      'binds partial arguments and keeps render assignments isolated',
      () async {
        final template = Template.parse(
          "{% include 'item' for items as entry %}|{{ saved }}|"
          "{% render 'item' with fallback as entry %}|"
          "{% render 'indexed' for items %}|{{ saved }}",
          data: {
            'items': ['a', 'b'],
            'fallback': 'c',
          },
          root: MapRoot({
            'item': '{{ entry }}{% assign saved = entry %}',
            'indexed': '{{ forloop.index }}:{{ indexed }};',
          }),
        );

        const expected = 'ab|b|c|1:a;2:b;|b';
        expect(template.render(), expected);
        expect(await template.renderAsync(), expected);
      },
    );

    test('ifchanged writes only when the rendered contents change', () async {
      final template = Template.parse(
        '{% for n in values %}{% ifchanged %}{{n}}{% endifchanged %}{% endfor %}',
        data: {
          'values': [1, 1, 2, 2, 1],
        },
      );
      expect(template.render(), '121');
      expect(template.render(), '121');
      expect(await template.renderAsync(), '121');
    });

    test(
      'counters start from supplied data without overriding assignments',
      () async {
        Template template() => Template.parse(
          '{% increment n %}|{{n}}|{% decrement n %}|{{n}}|'
          '{% assign n = 42 %}{% increment n %}|{{n}}',
          data: {'n': 5},
        );

        expect(template().render(), '5|6|5|5|5|42');
        expect(await template().renderAsync(), '5|6|5|5|5|42');
      },
    );

    test(
      'capture recognizes closing tags only between complete elements',
      () async {
        final template = Template.parse(
          '{% capture x %}{{ "{% endcapture %}" }}'
          '{% raw %}{% endcapture %}{% endraw %}'
          '{% comment %}{% endcapture %}{% endcomment %}'
          '{% capture nested %}inner{% endcapture %}{{ nested }}'
          '{% endcapture %}{{ x }}',
        );
        const expected = '{% endcapture %}{% endcapture %}inner';
        expect(template.render(), expected);
        expect(await template.renderAsync(), expected);
      },
    );

    test(
      'include evaluates named arguments in order without leaking them',
      () async {
        Template template() => Template.parse(
          "{% include 'pair' x: 'new', y: x %}|{{x}}|{{saved}}|"
          "{% include 'counter' %}{% include 'counter' %}",
          data: {'x': 'old'},
          root: MapRoot({
            'pair': '{{x}}:{{y}}{% assign saved = y %}',
            'counter': '{% increment count %}',
          }),
        );
        expect(template().render(), 'new:new|old|new|01');
        expect(await template().renderAsync(), 'new:new|old|new|01');
      },
    );

    test('counter names do not interfere with loop metadata', () async {
      Template template() => Template.parse(
        '{% increment forloop %}{% for n in (1..2) %}{{forloop.index}}{% endfor %}'
        '{% increment tablerowloop %}'
        '{% tablerow n in (1..1) %}{{tablerowloop.index}}{% endtablerow %}',
      );
      const expected = '0120<tr class="row1">\n<td class="col1">1</td></tr>\n';
      expect(template().render(), expected);
      expect(await template().renderAsync(), expected);
    });

    test(
      'tablerow closes its cell and row when break interrupts the body',
      () async {
        final template = Template.parse(
          '{% tablerow n in (1..3) cols:2 %}{{n}}{% break %}ignored{% endtablerow %}',
        );
        const expected = '<tr class="row1">\n<td class="col1">1</td></tr>\n';
        expect(template.render(), expected);
        expect(await template.renderAsync(), expected);
      },
    );

    test(
      'tablerow continue closes its cell and advances to the next row',
      () async {
        final template = Template.parse(
          '{% tablerow n in (1..3) cols:2 %}{{n}}'
          '{% if n == 2 %}{% continue %}{% endif %}!{% endtablerow %}',
        );
        const expected =
            '<tr class="row1">\n'
            '<td class="col1">1!</td><td class="col2">2</td></tr>\n'
            '<tr class="row2"><td class="col1">3!</td></tr>\n';
        expect(template.render(), expected);
        expect(await template.renderAsync(), expected);
      },
    );

    test(
      'strict dot lookup uses the filters registered in its environment',
      () async {
        final environment = Environment.withStrictMode({
          'items': [1, 2],
          'record': {'size': 'key'},
        });
        final source = '{{ items.size }}|{{ record.size }}';

        expect(
          Template.parse(source, environment: environment).render(),
          '|key',
        );
        environment.registerLocalFilter('size', (value, _, _) => 42);
        final template = Template.parse(source, environment: environment);
        expect(template.render(), '42|key');
        expect(await template.renderAsync(), '42|key');
      },
    );

    test('an environment with constant registers can render text', () async {
      final evaluator = Evaluator(Environment({}, const {}));
      final nodes = [TextNode('hello')];

      expect(evaluator.evaluateNodes(nodes), 'hello');
      evaluator.buffer.clear();
      expect(await evaluator.evaluateNodesAsync(nodes), 'hello');
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
