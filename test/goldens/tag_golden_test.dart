import 'dart:io';

import 'package:liquify/liquify.dart';
import '../support/golden_harness.dart';
class GoldenCase {
  final String name;
  final String template;
  final Root? root;

  const GoldenCase(this.name, this.template, {this.root});
}

String _readGolden(String name) {
  return File('test/goldens/$name.golden').readAsStringSync();
}

String _renderTemplate(GoldenCase testCase) {
  final template = testCase.root == null
      ? Template.parse(testCase.template)
      : Template.parse(testCase.template, root: testCase.root);
  return template.render();
}

void main() {
  final layoutRoot = MapRoot({
    'layouts/base.liquid':
        'Header-{% block content %}Base{% endblock %}-Footer',
  });

  final renderRoot = MapRoot({
    'partial.liquid': 'Hi {{ name }}',
  });

  final cases = <GoldenCase>[
    GoldenCase('assign', '{% assign foo = "bar" %}{{ foo }}'),
    GoldenCase('block', 'Before{% block foo %}bar{% endblock %}After'),
    GoldenCase(
      'layout_block_super',
      '{% layout "layouts/base.liquid" %}'
      '{% block content %}Child+{{ super() }}{% endblock %}',
      root: layoutRoot,
    ),
    GoldenCase('super', 'Before{{ super() }}After'),
    GoldenCase(
        'break', '{% for i in (1..3) %}{{ i }}{% break %}{% endfor %}'),
    GoldenCase('capture',
        '{% capture msg %}Hello{% endcapture %}{{ msg }}'),
    GoldenCase(
      'case',
      '{% assign a = 2 %}'
      '{% case a %}{% when 1 %}one{% when 2 %}two{% else %}other{% endcase %}',
    ),
    GoldenCase('comment',
        '{% comment %}This should not render{% endcomment %}World'),
    GoldenCase('continue',
        '{% for i in (1..3) %}{% if i == 2 %}{% continue %}{% endif %}{{ i }}{% endfor %}'),
    GoldenCase('cycle',
        '{% cycle "a","b","c" %}{% cycle "a","b","c" %}{% cycle "a","b","c" %}'),
    GoldenCase('decrement',
        '{% decrement counter %},{% decrement counter %}'),
    GoldenCase('doc', '{% doc %}Hidden docs{% enddoc %}World'),
    GoldenCase('echo', '{% echo "hi" %}'),
    GoldenCase('for', '{% for i in (1..3) %}{{ i }}{% endfor %}'),
    GoldenCase('if', '{% if true %}yes{% endif %}'),
    GoldenCase('elsif',
        '{% if false %}no{% elsif true %}yes{% endif %}'),
    GoldenCase('increment',
        '{% increment counter %},{% increment counter %}'),
    GoldenCase('liquid', '{% liquid echo "bar" %}'),
    GoldenCase('raw', '{% raw %}{{ not parsed }}{% endraw %}'),
    GoldenCase('render', '{% render "partial.liquid", name: "World" %}',
        root: renderRoot),
    GoldenCase('repeat', '{% repeat 3 %}Hi{% endrepeat %}'),
    GoldenCase('tablerow',
        '{% tablerow i in (1..2) cols:1 %}{{ i }}{% endtablerow %}'),
    GoldenCase('unless', '{% unless false %}yes{% endunless %}'),
  ];

  for (final testCase in cases) {
    test('golden ${testCase.name}', () {
      final actual = _renderTemplate(testCase);
      final expected = _readGolden(testCase.name);
      expect(actual, expected);
    });
  }
}
