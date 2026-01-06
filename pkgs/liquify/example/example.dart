import 'package:liquify/liquify.dart';
import 'package:liquify/parser.dart';

void main() {
  // Basic Template Rendering
  basicTemplateRendering();

  // Custom Tag
  customTagExample();

  // Custom Filter
  customFilterExample();
}

void basicTemplateRendering() {
  print('\n--- Basic Template Rendering ---');

  final data = {
    'name': 'Alice',
    'items': ['apple', 'banana', 'cherry'],
  };

  final result = Template.parse(
    'Hello, {{ name | upcase }}! Your items are: {% for item in items %}{{ item }}{% unless forloop.last %}, {% endunless %}{% endfor %}.',
    data: data,
  );

  print(result.render());
  // Output: Hello, ALICE! Your items are: apple, banana, cherry.
}

void customTagExample() {
  print('\n--- Custom Tag Example ---');

  // Register the custom tag
  TagRegistry.register(
    'reverse',
    (content, filters) => ReverseTag(content, filters),
  );

  // Use the custom tag
  final result = Template.parse('{% reverse %}Hello, World!{% endreverse %}');
  print(result.render());
  // Output: !dlroW ,olleH
}

void customFilterExample() {
  print('\n--- Custom Filter Example ---');

  // Register a custom filter
  FilterRegistry.register('multiply', (value, args, _) {
    final multiplier = args.isNotEmpty ? args[0] as num : 2;
    return (value as num) * multiplier;
  });

  // Use the custom filter
  final result = Template.parse(
    '{{ price | multiply: 1.1 | round }}',
    data: {'price': 100},
  );
  print(result.render());
  // Output: 110
}

class ReverseTag extends AbstractTag with CustomTagParser {
  ReverseTag(super.content, super.filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    String result = content
        .map((node) => evaluator.evaluate(node).toString())
        .join('')
        .split('')
        .reversed
        .join('');
    buffer.write(result);
  }

  @override
  Parser parser() {
    return (tagStart() &
            string('reverse').trim() &
            tagEnd() &
            any()
                .starLazy(tagStart() & string('endreverse').trim() & tagEnd())
                .flatten() &
            tagStart() &
            string('endreverse').trim() &
            tagEnd())
        .map((values) {
          return Tag("reverse", [TextNode(values[3])]);
        });
  }
}
