# Basic Usage Examples

This document covers fundamental Liquid template operations including variable interpolation, filters, loops, and custom extensions.

## Overview

The basic usage example demonstrates:
- Simple template rendering with variables
- Custom tag creation and registration
- Custom filter implementation
- Complex template logic with loops and conditionals

## Complete Example Code

```dart
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
```

## Basic Template Rendering

### Code
```dart
void basicTemplateRendering() {
  print('\n--- Basic Template Rendering ---');

  final data = {
    'name': 'Alice',
    'items': ['apple', 'banana', 'cherry']
  };

  final result = Template.parse(
      'Hello, {{ name | upcase }}! Your items are: {% for item in items %}{{ item }}{% unless forloop.last %}, {% endunless %}{% endfor %}.',
      data: data);

  print(result.render());
  // Output: Hello, ALICE! Your items are: apple, banana, cherry.
}
```

### Features Demonstrated

#### Variable Interpolation
```liquid
{{ name | upcase }}
```
- Outputs the `name` variable
- Applies the `upcase` filter to convert to uppercase
- Result: `ALICE`

#### Loops with Conditionals
```liquid
{% for item in items %}{{ item }}{% unless forloop.last %}, {% endunless %}{% endfor %}
```
- Iterates through the `items` array
- Uses `forloop.last` to detect the final iteration
- Adds commas between items but not after the last one
- Result: `apple, banana, cherry`

### Expected Output
```
--- Basic Template Rendering ---
Hello, ALICE! Your items are: apple, banana, cherry.
```

## Custom Tag Example

### Code
```dart
void customTagExample() {
  print('\n--- Custom Tag Example ---');

  // Register the custom tag
  TagRegistry.register(
      'reverse', (content, filters) => ReverseTag(content, filters));

  // Use the custom tag
  final result = Template.parse('{% reverse %}Hello, World!{% endreverse %}');
  print(result.render());
  // Output: !dlroW ,olleH
}
```

### Custom Tag Implementation
```dart
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
```

### Features Demonstrated

#### Tag Registration
```dart
TagRegistry.register('reverse', (content, filters) => ReverseTag(content, filters));
```
- Registers a custom tag named `reverse`
- Associates it with the `ReverseTag` implementation

#### Block Tag Parsing
```liquid
{% reverse %}Hello, World!{% endreverse %}
```
- Creates a block tag with opening and closing syntax
- Captures content between the tags
- Processes the content and returns modified result

#### String Manipulation
- Takes the captured content
- Splits it into individual characters
- Reverses the order
- Joins back into a string

### Expected Output
```
--- Custom Tag Example ---
!dlroW ,olleH
```

## Custom Filter Example

### Code
```dart
void customFilterExample() {
  print('\n--- Custom Filter Example ---');

  // Register a custom filter
  FilterRegistry.register('multiply', (value, args, _) {
    final multiplier = args.isNotEmpty ? args[0] as num : 2;
    return (value as num) * multiplier;
  });

  // Use the custom filter
  final result = Template.parse('{{ price | multiply: 1.1 | round }}',
      data: {'price': 100});
  print(result.render());
  // Output: 110
}
```

### Features Demonstrated

#### Filter Registration
```dart
FilterRegistry.register('multiply', (value, args, _) { ... });
```
- Registers a custom filter named `multiply`
- Takes input value and arguments
- Returns transformed result

#### Filter Arguments
```liquid
{{ price | multiply: 1.1 | round }}
```
- `multiply: 1.1` passes `1.1` as an argument to the filter
- Multiplies the price by 1.1 (adding 10%)
- Chains with `round` filter to round the result

#### Filter Logic
```dart
final multiplier = args.isNotEmpty ? args[0] as num : 2;
return (value as num) * multiplier;
```
- Uses first argument as multiplier, defaults to 2
- Performs multiplication operation
- Returns numeric result

### Expected Output
```
--- Custom Filter Example ---
110
```

## Usage Patterns

### Data Context Setup
```dart
final data = {
  'name': 'Alice',
  'items': ['apple', 'banana', 'cherry'],
  'price': 100
};
```
- Simple map structure for template variables
- Supports nested data and arrays
- Type-flexible (strings, numbers, arrays, objects)

### Template Parsing
```dart
final result = Template.parse(template_string, data: data);
```
- Parses template with variable context
- Returns renderable template object
- Supports both simple and complex templates

### Extension Registration
```dart
// Tags
TagRegistry.register('tag_name', constructor);

// Filters  
FilterRegistry.register('filter_name', function);
```
- Global registration affects all subsequent templates
- Extensions are immediately available after registration
- Can override built-in tags/filters

## Error Handling

### Invalid Template Syntax
```dart
try {
  final result = Template.parse('{{ invalid | filter }}');
  print(result.render());
} catch (e) {
  print('Template error: $e');
}
```

### Missing Data
```dart
// This will render empty/null for missing variables
final result = Template.parse('{{ missing_var }}', data: {});
```

### Type Errors in Filters
```dart
// Will throw if incompatible types are used
final result = Template.parse('{{ "text" | multiply: 2 }}');
```

## Performance Considerations

1. **Template Caching** - Parse templates once, render many times
2. **Extension Registration** - Register custom tags/filters at startup
3. **Data Preparation** - Prepare context data efficiently
4. **Filter Chaining** - Order filters for optimal performance

```dart
// Efficient pattern
final template = Template.parse(template_string);
for (final data in datasets) {
  print(template.render(data: data));
}
```

## Related Examples

- [Template Layouts](template-layouts.md) - Layout inheritance patterns
- [Custom Tags](custom-tags.md) - Advanced tag development
- [Drop Objects](drop-objects.md) - Custom object models 