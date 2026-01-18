import 'package:liquify/parser.dart';
import 'package:test/test.dart';

/// A custom tag using standard {% %} delimiters (default)
/// Usage: {% hello name %}
class HelloTag extends AbstractTag with CustomTagParser {
  HelloTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final name = content.isNotEmpty
        ? evaluator.evaluate(content.first)
        : 'World';
    buffer.write('Hello, $name!');
  }

  // Uses default TagDelimiterType.tag - no override needed

  @override
  Parser parser([LiquidConfig? config]) {
    // Use createTagStart/createTagEnd to support custom delimiters
    return (createTagStart(config) &
            string('hello').trim() &
            ref0(expression).optional().trim() &
            createTagEnd(config))
        .map((values) {
          final expr = values[2];
          return Tag('hello', expr != null ? [expr as ASTNode] : []);
        });
  }
}

/// A custom tag using {{ }} variable-style delimiters
/// Usage: {{ greet("name") }}
class GreetTag extends AbstractTag with CustomTagParser {
  GreetTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final name = content.isNotEmpty
        ? evaluator.evaluate(content.first)
        : 'World';
    buffer.write('Greetings, $name!');
  }

  @override
  TagDelimiterType get delimiterType => TagDelimiterType.variable;

  @override
  Parser parser([LiquidConfig? config]) {
    // Matches: {{ greet("name") }} or {{ greet(variable) }}
    // Use createVarStart/createVarEnd to support custom delimiters
    return (createVarStart(config) &
            string('greet').trim() &
            char('(').trim() &
            ref0(expression).trim() &
            char(')').trim() &
            createVarEnd(config))
        .map((values) {
          final expr = values[3] as ASTNode;
          return Tag('greet', [expr]);
        });
  }
}

/// A custom tag using {{ }} delimiters with no arguments
/// Usage: {{ now() }}
class NowTag extends AbstractTag with CustomTagParser {
  NowTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    buffer.write('NOW');
  }

  @override
  TagDelimiterType get delimiterType => TagDelimiterType.variable;

  @override
  Parser parser([LiquidConfig? config]) {
    // Use createVarStart/createVarEnd to support custom delimiters
    return (createVarStart(config) &
            string('now').trim() &
            char('(').trim() &
            char(')').trim() &
            createVarEnd(config))
        .map((_) {
          return Tag('now', []);
        });
  }
}

void main() {
  late Evaluator evaluator;

  setUpAll(() {
    // Register our custom tags
    TagRegistry.register(
      'hello',
      (content, filters) => HelloTag(content, filters),
    );
    TagRegistry.register(
      'greet',
      (content, filters) => GreetTag(content, filters),
    );
    TagRegistry.register('now', (content, filters) => NowTag(content, filters));
  });

  setUp(() {
    evaluator = Evaluator(Environment());
  });

  tearDown(() {
    evaluator.context.clear();
  });

  group('Custom Tag Delimiter Types', () {
    group('TagDelimiterType.tag ({% %} syntax)', () {
      test('parses custom tag with standard delimiters', () {
        final source = '{% hello "Alice" %}';
        final nodes = parseInput(source);
        final document = Document(nodes);

        evaluator.evaluateNodes(document.children);
        expect(evaluator.buffer.toString(), equals('Hello, Alice!'));
      });

      test('parses custom tag with variable argument', () {
        final source = '{% assign name = "Bob" %}{% hello name %}';
        final nodes = parseInput(source);
        final document = Document(nodes);

        evaluator.evaluateNodes(document.children);
        expect(evaluator.buffer.toString(), equals('Hello, Bob!'));
      });

      test('parses custom tag without argument', () {
        final source = '{% hello %}';
        final nodes = parseInput(source);
        final document = Document(nodes);

        evaluator.evaluateNodes(document.children);
        expect(evaluator.buffer.toString(), equals('Hello, World!'));
      });

      test('custom tag with {% %} does NOT parse with {{ }} delimiters', () {
        // This should be treated as a variable lookup, not our custom tag
        final source = '{{ hello }}';
        final nodes = parseInput(source);
        final document = Document(nodes);

        // 'hello' is undefined, so it outputs empty
        evaluator.evaluateNodes(document.children);
        expect(evaluator.buffer.toString(), equals(''));
      });
    });

    group('TagDelimiterType.variable ({{ }} syntax)', () {
      test('parses custom tag with variable delimiters', () {
        final source = '{{ greet("Carol") }}';
        final nodes = parseInput(source);
        final document = Document(nodes);

        evaluator.evaluateNodes(document.children);
        expect(evaluator.buffer.toString(), equals('Greetings, Carol!'));
      });

      test('parses custom tag with variable argument', () {
        final source = '{% assign name = "Dave" %}{{ greet(name) }}';
        final nodes = parseInput(source);
        final document = Document(nodes);

        evaluator.evaluateNodes(document.children);
        expect(evaluator.buffer.toString(), equals('Greetings, Dave!'));
      });

      test('parses custom tag with no arguments', () {
        final source = '{{ now() }}';
        final nodes = parseInput(source);
        final document = Document(nodes);

        evaluator.evaluateNodes(document.children);
        expect(evaluator.buffer.toString(), equals('NOW'));
      });

      test('tag still works with {% %} via generic parser', () {
        // Note: The custom parser's delimiterType only controls which delimiter
        // triggers the custom parser. The generic tag parser can still parse
        // {% greet(...) %} and the tag factory will create a GreetTag.
        // This is by design - delimiterType is about WHICH custom parser runs,
        // not about restricting the tag to only one delimiter type.
        final source = '{% greet("Eve") %}';
        final nodes = parseInput(source);
        final document = Document(nodes);

        // The generic tag parser creates a Tag('greet', ...) which the
        // tag factory turns into a GreetTag
        evaluator.evaluateNodes(document.children);
        expect(evaluator.buffer.toString(), equals('Greetings, Eve!'));
      });
    });

    group('Mixed delimiter types in same template', () {
      test('both custom tag types work together', () {
        final source = '{% hello "Frank" %} and {{ greet("Grace") }}';
        final nodes = parseInput(source);
        final document = Document(nodes);

        evaluator.evaluateNodes(document.children);
        expect(
          evaluator.buffer.toString(),
          equals('Hello, Frank! and Greetings, Grace!'),
        );
      });

      test('custom tags work with standard Liquid tags', () {
        final source =
            '{% assign items = "a,b,c" | split: "," %}{% for item in items %}{{ greet(item) }} {% endfor %}{% hello "end" %}';
        final nodes = parseInput(source);
        final document = Document(nodes);

        evaluator.evaluateNodes(document.children);
        final output = evaluator.buffer.toString();
        expect(output, contains('Greetings, a!'));
        expect(output, contains('Greetings, b!'));
        expect(output, contains('Greetings, c!'));
        expect(output, contains('Hello, end!'));
      });

      test('custom tags work with standard variables', () {
        final source = '{{ now() }} - {% assign x = 42 %}{{ x }}';
        final nodes = parseInput(source);
        final document = Document(nodes);

        evaluator.evaluateNodes(document.children);
        expect(evaluator.buffer.toString(), equals('NOW - 42'));
      });
    });

    group('Edge cases', () {
      test('whitespace handling in variable-style custom tag', () {
        final source = '{{  greet( "spaces" )  }}';
        final nodes = parseInput(source);
        final document = Document(nodes);

        evaluator.evaluateNodes(document.children);
        expect(evaluator.buffer.toString(), equals('Greetings, spaces!'));
      });

      test('whitespace handling in tag-style custom tag', () {
        final source = '{%  hello  "spaces"  %}';
        final nodes = parseInput(source);
        final document = Document(nodes);

        evaluator.evaluateNodes(document.children);
        expect(evaluator.buffer.toString(), equals('Hello, spaces!'));
      });

      test('{{- variant strips preceding whitespace with custom tags', () {
        // Liquid's whitespace stripping: {{- strips whitespace before the tag
        final source = 'before {{- now() }} after';
        final nodes = parseInput(source);
        final document = Document(nodes);

        evaluator.evaluateNodes(document.children);
        // {{- strips preceding whitespace
        expect(evaluator.buffer.toString(), equals('beforeNOW after'));
      });

      test('{%- variant strips preceding whitespace with custom tags', () {
        // Liquid's whitespace stripping: {%- strips whitespace before the tag
        final source = 'before {%- hello "test" %} after';
        final nodes = parseInput(source);
        final document = Document(nodes);

        evaluator.evaluateNodes(document.children);
        // {%- strips preceding whitespace
        expect(evaluator.buffer.toString(), equals('beforeHello, test! after'));
      });
    });
  });
}
