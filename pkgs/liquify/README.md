# Liquify - Liquid Template Engine for Dart

<p align="center">
  <img src="assets/logo.png" alt="Liquify Logo" width="200">
</p>

[![GitHub release](https://img.shields.io/github/release/kingwill101/liquify?include_prereleases=&sort=semver&color=blue)](https://github.com/kingwill101/liquify/releases/)
[![Pub Version](https://img.shields.io/pub/v/liquify)](https://pub.dev/packages/liquify)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/kingwill101/liquify/.github%2Fworkflows%2Fdart.yml)
[![License](https://img.shields.io/badge/License-MIT-blue)](#license)
[![issues - liquify](https://img.shields.io/github/issues/kingwill101/liquify)](https://github.com/kingwill101/liquify/issues)


Liquify is a comprehensive Dart implementation of the [Liquid template language](https://shopify.github.io/liquid/), originally created by Shopify. This high-performance library allows you to parse, render, and extend Liquid templates in your Dart and Flutter applications.

## Features

- Full support for standard Liquid syntax and semantics
- Synchronous and asynchronous rendering
- Custom delimiters (ERB-style, bracket-style, or your own)
- Environment-scoped filters and tags for security isolation
- Strict mode for security sandboxing
- Extensible architecture for custom tags and filters
- Template inheritance with layouts and blocks
- File system abstraction for template resolution
- High-performance parsing with caching
- Strong typing and null safety

## Installation

Add Liquify to your `pubspec.yaml`:

```yaml
dependencies:
  liquify: ^1.5.0
```

Then run `dart pub get` or `flutter pub get`.

## Quick Start

### Basic Template Rendering

```dart
import 'package:liquify/liquify.dart';

void main() {
  final template = Template.parse(
    'Hello, {{ name | upcase }}!',
    data: {'name': 'world'},
  );
  
  print(template.render()); // Output: Hello, WORLD!
}
```

### Using the Liquid Class

The `Liquid` class provides a convenient API, especially when using custom delimiters:

```dart
final liquid = Liquid();
final result = liquid.renderString('Hello, {{ name }}!', {'name': 'World'});
print(result); // Output: Hello, World!
```

### Async Rendering

Use async rendering for templates with async filters or includes:

```dart
final result = await template.renderAsync();
```

## Custom Delimiters

Liquify supports custom delimiters for integrating with other template systems or avoiding conflicts with frontend frameworks.

### ERB-Style Delimiters

```dart
final liquid = Liquid(config: LiquidConfig.erb);
final result = liquid.renderString(
  '<% if show %>Hello, <%= name %>!<% endif %>',
  {'show': true, 'name': 'World'},
);
print(result); // Output: Hello, World!
```

### Custom Delimiters

```dart
final liquid = Liquid.withDelimiters(
  tagStart: '[%',
  tagEnd: '%]',
  varStart: '[[',
  varEnd: ']]',
);

final result = liquid.renderString(
  '[% for item in items %][[ item ]] [% endfor %]',
  {'items': ['a', 'b', 'c']},
);
print(result); // Output: a b c
```

### Whitespace Control

Whitespace stripping works with custom delimiters using the `-` marker:

```dart
final liquid = Liquid.withDelimiters(tagStart: '[%', tagEnd: '%]', varStart: '[[', varEnd: ']]');

final result = liquid.renderString('Hello    [[- name ]]!', {'name': 'World'});
print(result); // Output: HelloWorld!
```

## Template Inheritance

Liquify supports template inheritance through the `layout` tag:

```liquid
<!-- layouts/base.liquid -->
<!DOCTYPE html>
<html>
<head><title>{% block title %}Default{% endblock %}</title></head>
<body>{% block content %}{% endblock %}</body>
</html>
```

```liquid
<!-- page.liquid -->
{% layout "layouts/base.liquid" %}
{% block title %}My Page{% endblock %}
{% block content %}<h1>Welcome!</h1>{% endblock %}
```

Variables can be passed to layouts:

```liquid
{% layout "layouts/base.liquid", title: page_title, year: 2024 %}
```

## File System and Template Resolution

### In-Memory Templates with MapRoot

```dart
final fs = MapRoot({
  'main.liquid': 'Hello {% render "partial.liquid" %}',
  'partial.liquid': 'World!',
});

final template = Template.fromFile('main.liquid', fs);
print(template.render()); // Output: Hello World!
```

### Custom Template Resolution

Implement the `Root` class for custom template sources:

```dart
class DatabaseRoot extends Root {
  @override
  Future<String?> resolveAsync(String path) async {
    return await database.getTemplate(path);
  }
}
```

## Security and Isolation

### Environment-Scoped Filters

Register filters that are isolated to a specific template:

```dart
final template = Template.parse(
  '{{ input | sanitize }}',
  data: {'input': '<script>alert("xss")</script>'},
  environmentSetup: (env) {
    env.registerLocalFilter('sanitize', (value, args, namedArgs) => 
      value.toString().replaceAll(RegExp(r'<[^>]*>'), ''));
  },
);

print(template.render()); // Output: alert("xss")
```

### Strict Mode

Block access to global filters and tags for untrusted content:

```dart
final secureEnv = Environment.withStrictMode();
secureEnv.registerLocalFilter('safe_filter', myFilter);

final template = Template.parse(source, environment: secureEnv);
```

### Environment Cloning

Create child environments that inherit from a parent:

```dart
final baseEnv = Environment();
baseEnv.registerLocalFilter('base', baseFilter);

final childEnv = baseEnv.clone();
childEnv.registerLocalFilter('child', childFilter);
// childEnv has access to both 'base' and 'child' filters
```

## Custom Tags and Filters

### Custom Filter

```dart
FilterRegistry.register('reverse_words', (value, args, namedArgs) {
  return value.toString().split(' ').reversed.join(' ');
});

// Usage: {{ "hello world" | reverse_words }} -> "world hello"
```

### Custom Tag

```dart
class ShoutTag extends AbstractTag with CustomTagParser {
  ShoutTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final text = evaluator.evaluate(content.first)?.toString() ?? '';
    buffer.write(text.toUpperCase());
  }

  @override
  Parser parser([LiquidConfig? config]) {
    return (createTagStart(config) &
            string('shout').trim() &
            ref0(expression).trim() &
            createTagEnd(config))
        .map((values) => Tag('shout', [values[2] as ASTNode]));
  }
}

TagRegistry.register('shout', (content, filters) => ShoutTag(content, filters));

// Usage: {% shout "hello" %} -> HELLO
```

For more examples, see the [example directory](example).

## API Documentation

Full API documentation is available at [pub.dev](https://pub.dev/documentation/liquify/latest/).

## Contributing

Contributions are welcome! Please open an issue first for major changes.

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgements

- [Shopify](https://shopify.github.io/liquid/) for the original Liquid template language
- [LiquidJS](https://github.com/harttle/liquidjs) for their comprehensive filter implementations
- [liquid_dart](https://github.com/ergonlabs/liquid_dart) for initial Dart implementation inspiration
