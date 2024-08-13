import 'package:test/test.dart';
import 'package:liquid_grammar/liquid_grammar.dart';

void main() {
  final parser = LiquidGrammarDefinition().build();

  group('Liquid Grammar Tests', () {
    // Basic Tags
    test('Simple assign tag', () {
      var result = parser.parse('{% assign myVariable = "Hello World" %}');
      expect(result.isSuccess, isTrue);
      expect(result.value, [
        {
          'type': 'tag',
          'content': {
            'name': 'assign',
            'arguments': [
              {
                'type': 'assignment',
                'variable': 'myVariable',
                'value': {'type': 'string', 'value': 'Hello World'}
              }
            ]
          }
        }
      ]);
    });

    test('If tag with condition', () {
      var result = parser.parse('{% if user.name == "John" %}Hello John!{% endif %}');
      expect(result.isSuccess, isTrue);
      expect(result.value, [
        {
          'type': 'tag',
          'content': {
            'name': 'if',
            'arguments': [
              {
                'type': 'comparison',
                'left': {'type': 'variable', 'path': 'user.name'},
                'operator': '==',
                'right': {'type': 'string', 'value': 'John'}
              }
            ]
          }
        }
      ]);
    });

    test('For loop tag', () {
      var result = parser.parse('{% for item in collection %}{{ item.name }}{% endfor %}');
      expect(result.isSuccess, isTrue);
      expect(result.value, [
        {
          'type': 'tag',
          'content': {
            'name': 'for',
            'arguments': [
              {'type': 'variable', 'path': 'item'},
              {'type': 'variable', 'path': 'collection'}
            ]
          }
        }
      ]);
    });

    // Raw and Comment Tags
    test('Raw tag', () {
      var result = parser.parse('{% raw %}This is {{ raw }} content{% endraw %}');
      expect(result.isSuccess, isTrue);
      expect(result.value, [
        {
          'type': 'tag',
          'content': {
            'name': 'raw',
            'arguments': [
              'This is {{ raw }} content'
            ]
          }
        }
      ]);
    });

    test('Comment tag', () {
      var result = parser.parse('{% comment %}This is a comment{% endcomment %}');
      expect(result.isSuccess, isTrue);
      expect(result.value, [
        {
          'type': 'tag',
          'content': {
            'name': 'comment',
            'arguments': [
              'This is a comment'
            ]
          }
        }
      ]);
    });

    // Custom Tags
    test('Custom tag with arguments', () {
      var result = parser.parse('{% custom_tag arg1 arg2 key: value %}');
      expect(result.isSuccess, isTrue);
      expect(result.value, [
        {
          'type': 'tag',
          'content': {
            'name': 'custom_tag',
            'arguments': [
              {'type': 'variable', 'path': 'arg1'},
              {'type': 'variable', 'path': 'arg2'},
              {'type': 'assignment', 'variable': 'key', 'value': {'type': 'variable', 'path': 'value'}}
            ]
          }
        }
      ]);
    });

    // Nested Tags
    test('Nested tags', () {
      var result = parser.parse('{% if condition %}{% assign var = "value" %}{% endif %}');
      expect(result.isSuccess, isTrue);
      expect(result.value, [
        {
          'type': 'tag',
          'content': {
            'name': 'if',
            'arguments': [
              {'type': 'variable', 'path': 'condition'}
            ]
          }
        },
        {
          'type': 'tag',
          'content': {
            'name': 'assign',
            'arguments': [
              {
                'type': 'assignment',
                'variable': 'var',
                'value': {'type': 'string', 'value': 'value'}
              }
            ]
          }
        }
      ]);
    });

    // Complex Expressions
    test('Tag with comparison', () {
      var result = parser.parse('{% if user.age >= 18 %}Adult{% endif %}');
      expect(result.isSuccess, isTrue);
      expect(result.value, [
        {
          'type': 'tag',
          'content': {
            'name': 'if',
            'arguments': [
              {
                'type': 'comparison',
                'left': {'type': 'variable', 'path': 'user.age'},
                'operator': '>=',
                'right': {'type': 'number', 'value': 18}
              }
            ]
          }
        }
      ]);
    });

    test('Tag with multiple comparisons', () {
      var result = parser.parse('{% if user.age >= 18 and user.age <= 65 %}Working age{% endif %}');
      expect(result.isSuccess, isTrue);
      expect(result.value, [
        {
          'type': 'tag',
          'content': {
            'name': 'if',
            'arguments': [
              {
                'type': 'comparison',
                'left': {'type': 'variable', 'path': 'user.age'},
                'operator': '>=',
                'right': {'type': 'number', 'value': 18}
              },
              {
                'type': 'comparison',
                'left': {'type': 'variable', 'path': 'user.age'},
                'operator': '<=',
                'right': {'type': 'number', 'value': 65}
              }
            ]
          }
        }
      ]);
    });

    // Filters
    test('Output with filter', () {
      var result = parser.parse('{{ user.name | upcase }}');
      expect(result.isSuccess, isTrue);
      expect(result.value, [
        {
          'type': 'output',
          'content': {
            'type': 'filterChain',
            'base': {'type': 'variable', 'path': 'user.name'},
            'filters': [
              {'name': 'upcase', 'argument': null}
            ]
          }
        }
      ]);
    });

    test('Output with multiple filters', () {
      var result = parser.parse('{{ user.name | upcase | escape }}');
      expect(result.isSuccess, isTrue);
      expect(result.value, [
        {
          'type': 'output',
          'content': {
            'type': 'filterChain',
            'base': {'type': 'variable', 'path': 'user.name'},
            'filters': [
              {'name': 'upcase', 'argument': null},
              {'name': 'escape', 'argument': null}
            ]
          }
        }
      ]);
    });

    test('Output with filter and arguments', () {
      var result = parser.parse('{{ article.published_at | date: "%Y-%m-%d" }}');
      expect(result.isSuccess, isTrue);
      expect(result.value, [
        {
          'type': 'output',
          'content': {
            'type': 'filterChain',
            'base': {'type': 'variable', 'path': 'article.published_at'},
            'filters': [
              {'name': 'date', 'argument': {'type': 'string', 'value': '%Y-%m-%d'}}
            ]
          }
        }
      ]);
    });

    // Edge Cases
    test('Empty tag', () {
      var result = parser.parse('{% %}');
      expect(result.isSuccess, isTrue);
      expect(result.value, [
        {
          'type': 'tag',
          'content': {
            'name': '',
            'arguments': []
          }
        }
      ]);
    });

    test('Tag with only spaces', () {
      var result = parser.parse('{%    %}');
      expect(result.isSuccess, isTrue);
      expect(result.value, [
        {
          'type': 'tag',
          'content': {
            'name': '',
            'arguments': []
          }
        }
      ]);
    });

    test('Output with only spaces', () {
      var result = parser.parse('{{    }}');
      expect(result.isSuccess, isTrue);
      expect(result.value, [
        {
          'type': 'output',
          'content': ''
        }
      ]);
    });

    test('Unclosed tag', () {
      var result = parser.parse('{% assign myVariable = "Hello World"');
      expect(result.isSuccess, isFalse);
    });

    test('Unclosed output', () {
      var result = parser.parse('{{ user.name');
      expect(result.isSuccess, isFalse);
    });

    test('Nested outputs', () {
      var result = parser.parse('{{ "{{ user.name }}" }}');
      expect(result.isSuccess, isTrue);
      expect(result.value, [
        {
          'type': 'output',
          'content': {
            'type': 'string',
            'value': '{{ user.name }}'
          }
        }
      ]);
    });

    test('Mixed content', () {
      var result = parser.parse('Hello {{ user.name }}! {% if user %}Welcome{% endif %}');
      expect(result.isSuccess, isTrue);
      expect(result.value, [
        'Hello ',
        {
          'type': 'output',
          'content': {'type': 'variable', 'path': 'user.name'}
        },
        '! ',
        {
          'type': 'tag',
          'content': {
            'name': 'if',
            'arguments': [
              {'type': 'variable', 'path': 'user'}
            ]
          }
        },
        'Welcome'
      ]);
    });

    // Complex edge cases
    test('Complex nested structures', () {
      var result = parser.parse(r'''
        {% if user %}
          {% for item in user.items %}
            {{ item.name | upcase }}
          {% endfor %}
        {% endif %}
      ''');
      expect(result.isSuccess, isTrue);
      expect(result.value, [
        {
          'type': 'tag',
          'content': {
            'name': 'if',
            'arguments': [
              {'type': 'variable', 'path': 'user'}
            ]
          }
        },
        '\n          ',
        {
          'type': 'tag',
          'content': {
            'name': 'for',
            'arguments': [
              {'type': 'variable', 'path': 'item'},
              {'type': 'variable', 'path': 'user.items'}
            ]
          }
        },
        '\n            ',
        {
          'type': 'output',
          'content': {
            'type': 'filterChain',
            'base': {'type': 'variable', 'path': 'item.name'},
            'filters': [
              {'name': 'upcase', 'argument': null}
            ]
          }
        },
        '\n          ',
        {
          'type': 'tag',
          'content': {
            'name': 'endfor',
            'arguments': []
          }
        },
        '\n        ',
        {
          'type': 'tag',
          'content': {
            'name': 'endif',
            'arguments': []
          }
        },
        '\n      '
      ]);
    });
  });
}
