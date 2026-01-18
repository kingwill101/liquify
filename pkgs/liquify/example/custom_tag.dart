import 'package:liquify/liquify.dart';
import 'package:liquify/parser.dart';

void main() {
  // Register the custom tag (works with any delimiters)
  TagRegistry.register('box', (content, filters) => BoxTag(content, filters));
  FilterRegistry.register('sum', (value, args, namedArgs) {
    if (value is! List) {
      return value;
    }
    return (value as List<int>).reduce((int a, int b) => a + b);
  });

  // Example 1: Standard delimiters
  standardDelimitersExample();

  // Example 2: Custom delimiters with custom tags
  customDelimitersExample();

  // Example 3: ERB-style delimiters with custom tags
  erbDelimitersExample();
}

/// Custom tag with standard Liquid delimiters ({% %})
void standardDelimitersExample() {
  print('=== Standard Delimiters ===\n');

  final template = '''
{% box %}
Hello, World!
This is a custom box tag.
{% endbox %}

{% box * %}
Using a custom box character.
{% endbox %}
''';

  final result = Template.parse(
    template,
    data: {
      'items': [1, 2, 3],
    },
  );
  print(result.render());
}

/// Custom tag with custom delimiters ([% %])
void customDelimitersExample() {
  print('\n=== Custom Delimiters ([% %]) ===\n');

  // Create a Liquid instance with custom delimiters
  final liquid = Liquid(
    config: LiquidConfig(
      tagStart: '[%',
      tagEnd: '%]',
      varStart: '[[',
      varEnd: ']]',
    ),
  );

  // The custom tag automatically works with the custom delimiters
  // because BoxTag.parser() uses createTagStart/createTagEnd
  final template = liquid.parse('''
[% box %]
Custom delimiters work!
Value: [[ name ]]
[% endbox %]

[% box # %]
Different box character.
[% endbox %]
''');

  print(template.render({'name': 'Alice'}));
}

/// Custom tag with ERB-style delimiters (<% %>)
void erbDelimitersExample() {
  print('\n=== ERB-Style Delimiters (<% %>) ===\n');

  // Use the ERB preset
  final liquid = Liquid(config: LiquidConfig.erb);

  final template = liquid.parse('''
<% box %>
ERB-style delimiters!
User: <%= user %>
<% endbox %>
''');

  print(template.render({'user': 'Bob'}));
}

class BoxTag extends AbstractTag with CustomTagParser {
  BoxTag(super.content, super.filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    String content = evaluator.evaluate(body[0]).toString().trim();

    // Use the config from the environment to re-parse with the same delimiters
    final config = evaluator.context.config;
    final liquid = Liquid(config: config ?? LiquidConfig.standard);
    content = liquid.renderString(content, evaluator.context.all());

    String boxChar = this.content.isNotEmpty
        ? evaluator.evaluate(this.content[0]).toString()
        : '+';

    List<String> lines = content.split('\n');
    int maxLength = lines
        .map((line) => line.length)
        .reduce((a, b) => a > b ? a : b);

    String topBottom = boxChar * (maxLength);
    buffer.writeln(topBottom);

    for (String line in lines) {
      buffer.writeln('$boxChar ${line.padRight(maxLength)} $boxChar');
    }

    buffer.writeln(topBottom);
  }

  @override
  Parser parser([LiquidConfig? config]) {
    final start = createTagStart(config);
    final end = createTagEnd(config);
    return (start &
            string('box').trim() &
            any().starLazy(end).flatten().optional() &
            end &
            any().starLazy(start & string('endbox').trim() & end).flatten() &
            start &
            string('endbox').trim() &
            end)
        .map((values) {
          var boxChar = values[2] != null ? TextNode(values[2]) : null;
          return Tag(
            "box",
            boxChar != null ? [boxChar] : [],
            body: [TextNode(values[4])],
          );
        });
  }
}
