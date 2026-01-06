import 'package:liquify/liquify.dart';
import 'package:liquify/parser.dart';

void main() {
  print('Custom Box Tag Example\n');

  // Register the custom tag
  TagRegistry.register('box', (content, filters) => BoxTag(content, filters));
  FilterRegistry.register('sum', (value, args, namedArgs) {
    if (value is! List) {
      return value;
    }
    return (value as List<int>).reduce((int a, int b) => a + b);
  });

  // Define the template
  final template = '''
Default box:
{% box %}
Hello, World!
This is a custom box tag.
{% endbox %}

Custom character box:
{% box * %}
Using a custom box character.
Multiple lines are supported.
{% endbox %}

Box with calculations:
{% box %}
Total: {{ items | size }}
Sum: {% for item in items %} {{ item }} {% unless forloop.last %} + {% endunless %}{% endfor %} = {{ items | sum }}
{% endbox %}
  ''';

  // Create a context with some variables
  final context = {
    'name': 'Alice',
    'age': 30,
    'items': [1, 2, 3, 4, 5],
  };

  // Parse and render the template
  final result = Template.parse(template, data: context);

  // Print the result
  print(result.render());
}

class BoxTag extends AbstractTag with CustomTagParser {
  BoxTag(super.content, super.filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    String content = evaluator.evaluate(body[0]).toString().trim();

    content = Template.parse(content, data: evaluator.context.all()).render();

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
  Parser parser() {
    return (tagStart() &
            string('box').trim() &
            any().starLazy(tagEnd()).flatten().optional() &
            tagEnd() &
            any()
                .starLazy(tagStart() & string('endbox').trim() & tagEnd())
                .flatten() &
            tagStart() &
            string('endbox').trim() &
            tagEnd())
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
