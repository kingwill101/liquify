# Liquify - Powerful Liquid Template Engine for Dart

Liquify is a comprehensive Dart implementation of the Liquid template language, originally created by Shopify. This high-performance library allows you to parse, render, and extend Liquid templates in your Dart and Flutter applications.

## Features

- Full support for standard Liquid syntax and semantics
- Extensible architecture for custom tags and filters
- High-performance parsing and rendering
- Strong typing and null safety
- Comprehensive error handling and reporting
- Support for complex data structures and nested objects
- Easy integration with Dart and Flutter projects
- Extensive set of built-in filters ported from LiquidJS

## Installation

Add Liquify to your package's `pubspec.yaml` file:

```yaml
dependencies:
  liquify: ^0.5.0
```

Or, for the latest development version:

```yaml
dependencies:
  liquify:
    git: https://github.com/kingwill101/liquify.git
```

Then run `dart pub get` or `flutter pub get` to install the package.

## Usage

### Basic Template Rendering

```dart
import 'package:liquify/liquify.dart';

void main() {
  final data = {
    'name': 'Alice',
    'items': ['apple', 'banana', 'cherry']
  };

  final result = Template.parse(
    'Hello, {{ name | upcase }}! Your items are: {% for item in items %}{{ item }}{% unless forloop.last %}, {% endunless %}{% endfor %}.',
    data: data
  );

  print(result);
  // Output: Hello, ALICE! Your items are: apple, banana, cherry.
}
```

### Custom Tags

Liquify allows you to create and use custom tags. Here's an example of a custom `reverse` tag:

```dart
import 'package:liquify/liquify.dart';

class ReverseTag extends AbstractTag with CustomTagParser {
  ReverseTag(List<ASTNode> content, List<Filter> filters) : super(content, filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    String result = content.map((node) => evaluator.evaluate(node).toString()).join('').split('').reversed.join('');
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

void main() {
  // Register the custom tag
  TagRegistry.register('reverse', (content, filters) => ReverseTag(content, filters));

  // Use the custom tag
  final result = Template.parse('{% reverse %}Hello, World!{% endreverse %}');
  print(result);
  // Output: !dlroW ,olleH
}
```

### Custom Filters

You can also create custom filters:

```dart
import 'package:liquify/liquify.dart';

void main() {
  // Register a custom filter
  FilterRegistry.register('multiply', (value, args, _) {
    final multiplier = args.isNotEmpty ? args[0] as num : 2;
    return (value as num) * multiplier;
  });

  // Use the custom filter
  final result = Template.parse('{{ price | multiply: 1.1 | round }}', data: {'price': 100});
  print(result);
  // Output: 110
}
```

## API Documentation

Detailed API documentation is available [here](https://pub.dev/documentation/liquify/latest/).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgements

- Shopify for the original Liquid template language
- The Dart team for the excellent language and tools
- [LiquidJS](https://github.com/harttle/liquidjs) for their comprehensive set of filters, which we've ported to Dart
- [liquid_dart](https://github.com/ergonlabs/liquid_dart) for their initial Dart implementation, which served as inspiration for this project

## Related Projects

- [LiquidJS](https://github.com/harttle/liquidjs): A popular JavaScript implementation of Liquid templates
- [liquid_dart](https://github.com/ergonlabs/liquid_dart): An earlier Dart implementation of Liquid templates (now unmaintained)

Liquify aims to provide a modern, maintained, and feature-rich Liquid template engine for the Dart ecosystem, building upon the work of these excellent projects.
