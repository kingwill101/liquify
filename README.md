# Liquify - Liquid Template Engine for Dart

Liquify is a Dart implementation of the Liquid template language, originally created by Shopify. This library allows you to parse and render Liquid templates in your Dart and Flutter applications.

## Features

- Full support for standard Liquid syntax
- Custom tag and filter creation
- Extensible architecture
- Efficient parsing and rendering

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  liquify:
    git: https://github.com/yourorganization/liquify.git
```

Then run `dart pub get` or `flutter pub get` to install the package.

## Usage

Basic usage of Liquify involves parsing a template string and providing data:

```dart
import 'package:liquify/liquify.dart';

void main() {
  final result = Template.parse('''
    {% assign my_name = "Bob" %}
    {{ user.name.first | upper }}
    {{ my_name }}
  ''', data: {
    'user': {
      'name': {'first': 'Bob'}
    },
  });

  print(result);
}
```

This will output:
```
BOB
Bob
```

## Custom Tags

Liquify allows you to create custom tags. Here's an example of a custom `box` tag that wraps content in a styled div:

```dart
import 'package:liquify/parser.dart';

class BoxTag extends BaseTag with CustomTagParser {
  String? style;

  BoxTag(super.content, super.filters);

  @override
  void preprocess(Evaluator evaluator) {
    if (content.isNotEmpty && content[0] is Literal) {
      style = (content[0] as Literal).value;
    }
  }

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    buffer.write('<div style="${style ?? ''}">\n');
    for (final node in body) {
      evaluator.evaluate(node);
    }
    buffer.write('\n</div>');
  }

  @override
  Parser parser() {
    return seq3(
      tagStart() & string('box').trim(),
      ref0(expression).optional().trim(),
      tagEnd(),
    )
    .seq(ref0(content))
    .seq(tagStart() & string('endbox').trim() & tagEnd())
    .map((values) {
      final styleArg = values[0][1];
      final bodyContent = values[1];
      return Tag('box',
        styleArg != null ? [styleArg] : [],
        body: bodyContent
      );
    });
  }

  Parser content() {
    return any().starLazy(tagStart() & string('endbox').trim() & tagEnd());
  }
}
```

To use this custom tag:

```dart
import 'package:liquify/liquify.dart';

void main() {
  TagRegistry.register('box', (content, filters) => BoxTag(content, filters));

  final template = '''
    {% box "color: blue; padding: 10px;" %}
      This content will be in a blue box with padding.
    {% endbox %}
  ''';

  final result = Template.parse(template);
  print(result);
}
```

## Documentation

For more detailed documentation, please refer to the [API reference](link-to-your-api-docs).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the [MIT License](LICENSE).
