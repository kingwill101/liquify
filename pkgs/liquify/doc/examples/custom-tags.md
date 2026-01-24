# Custom Tag Examples

This document demonstrates how to create sophisticated custom tags with complex parsing logic, multi-line content processing, and dynamic behavior.

## Overview

The custom tag example showcases:
- Advanced block tag implementation
- Custom parser development
- Multi-line content processing
- Dynamic tag parameters
- Template content evaluation

## Complete Example Code

```dart
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
```

## Box Tag Implementation

### Complete Tag Class

```dart
class BoxTag extends AbstractTag with CustomTagParser {
  BoxTag(super.content, super.filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    String content = evaluator.evaluate(body[0]).toString().trim();

    content = Template.parse(
      content,
      data: evaluator.context.all(),
    ).render();

    String boxChar = this.content.isNotEmpty
        ? evaluator.evaluate(this.content[0]).toString()
        : '+';

    List<String> lines = content.split('\n');
    int maxLength =
        lines.map((line) => line.length).reduce((a, b) => a > b ? a : b);

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
      return Tag("box", boxChar != null ? [boxChar] : [],
          body: [TextNode(values[4])]);
    });
  }
}
```

## Key Features Demonstrated

### Parser Technology

Custom tags in Liquid Grammar are built using **PetitParser**, a powerful parser combinator library that's exposed through the `liquify/parser` import. This provides developers with:

- **Parser Combinators**: Compose complex parsers from simple building blocks
- **Quality of Life Helpers**: Pre-built parsers for common Liquid syntax patterns
- **Flexible Parsing**: Handle complex tag syntax with optional parameters
- **Error Handling**: Built-in error reporting and recovery

```dart
import 'package:liquify/parser.dart';  // Exposes PetitParser with Liquid helpers
```

#### Key Parser Helpers Available

- `tagStart()` - Matches `{%` opening tags
- `tagEnd()` - Matches `%}` closing tags  
- `string(name)` - Matches specific string literals
- `any()` - Matches any character
- `starLazy()` - Lazy repetition until terminator
- `flatten()` - Converts parsed results to strings
- `optional()` - Makes parser components optional

### Tag Registration

```dart
TagRegistry.register('box', (content, filters) => BoxTag(content, filters));
```

- Registers the custom tag globally
- Makes it available in all templates
- Associates tag name with implementation class

### Parser Implementation

Custom tag parsers are built by combining PetitParser primitives with Liquid-specific helpers. The parser defines the syntax structure of your custom tag:

```dart
@override
Parser parser() {
  return (tagStart() &              // Matches {%
          string('box').trim() &    // Matches 'box' with whitespace handling
          any().starLazy(tagEnd()).flatten().optional() &  // Optional parameters
          tagEnd() &                // Matches %}
          any()                     // Body content
              .starLazy(tagStart() & string('endbox').trim() & tagEnd())
              .flatten() &
          tagStart() &              // Matches {% for closing
          string('endbox').trim() & // Matches 'endbox'
          tagEnd())                 // Matches %}
      .map((values) {              // Transform parsed values into Tag object
    var boxChar = values[2] != null ? TextNode(values[2]) : null;
    return Tag("box", boxChar != null ? [boxChar] : [],
        body: [TextNode(values[4])]);
  });
}
```

#### PetitParser Combinator Patterns

The parser uses **combinator composition** where simple parsers are combined using operators:

- **Sequence (`&`)**: Matches parsers in order: `tagStart() & string('box') & tagEnd()`
- **Choice (`|`)**: Matches any of several alternatives: `string('true') | string('false')`
- **Repetition (`.star()`)**: Matches zero or more: `any().star()`
- **Lazy Repetition (`.starLazy()`)**: Matches until terminator: `any().starLazy(tagEnd())`
- **Optional (`.optional()`)**: Makes component optional: `parameter().optional()`
- **Transformation (`.map()`)**: Converts parse results: `.map((values) => Tag(...))`

#### Advanced Parser Patterns

```dart
// Complex parameter parsing
Parser parameterParser() {
  return (identifier() & 
          char(':').trim() & 
          (quotedString() | number() | identifier()))
      .map((values) => Parameter(values[0], values[2]));
}

// Multiple parameter support  
Parser parametersParser() {
  return parameterParser()
      .separatedBy(char(',').trim())
      .map((list) => list.elements);
}

// Complete tag with parameters
Parser complexTagParser() {
  return (tagStart() &
          string('mytag').trim() &
          parametersParser().optional() &
          tagEnd())
      .map((values) => MyTag(values[2] ?? []));
}
```

### Content Evaluation

```dart
@override
dynamic evaluate(Evaluator evaluator, Buffer buffer) {
  String content = evaluator.evaluate(body[0]).toString().trim();

  content = Template.parse(
    content,
    data: evaluator.context.all(),
  ).render();

  String boxChar = this.content.isNotEmpty
      ? evaluator.evaluate(this.content[0]).toString()
      : '+';

  // Box rendering logic...
}
```

#### Evaluation Steps

1. **Extract Content**: Get the body content from parsed tag
2. **Template Processing**: Parse and render any Liquid syntax within the content
3. **Parameter Handling**: Evaluate optional box character parameter
4. **Box Rendering**: Create the visual box structure

### Template-in-Template Processing

```dart
content = Template.parse(
  content,
  data: evaluator.context.all(),
).render();
```

- Processes Liquid syntax within tag content
- Evaluates variables, filters, and loops
- Provides full template functionality inside custom tags

### Dynamic Box Rendering

```dart
List<String> lines = content.split('\n');
int maxLength = lines.map((line) => line.length).reduce((a, b) => a > b ? a : b);

String topBottom = boxChar * (maxLength);
buffer.writeln(topBottom);

for (String line in lines) {
  buffer.writeln('$boxChar ${line.padRight(maxLength)} $boxChar');
}

buffer.writeln(topBottom);
```

- Calculates maximum line length for consistent box width
- Creates top and bottom borders
- Pads each line and adds side borders
- Outputs formatted box structure

## Usage Examples

### Default Box

```liquid
{% box %}
Hello, World!
This is a custom box tag.
{% endbox %}
```

**Output:**
```
+++++++++++++++++++++++++++
+ Hello, World!           +
+ This is a custom box tag. +
+++++++++++++++++++++++++++
```

### Custom Character Box

```liquid
{% box * %}
Using a custom box character.
Multiple lines are supported.
{% endbox %}
```

**Output:**
```
*********************************
* Using a custom box character.  *
* Multiple lines are supported.  *
*********************************
```

### Box with Template Logic

```liquid
{% box %}
Total: {{ items | size }}
Sum: {% for item in items %} {{ item }} {% unless forloop.last %} + {% endunless %}{% endfor %} = {{ items | sum }}
{% endbox %}
```

**Output:**
```
++++++++++++++++++++++++++
+ Total: 5               +
+ Sum:  1  +  2  +  3  +  4  +  5  = 15 +
++++++++++++++++++++++++++
```

## Custom Filter Integration

The example also demonstrates custom filter registration:

```dart
FilterRegistry.register('sum', (value, args, namedArgs) {
  if (value is! List) {
    return value;
  }
  return (value as List<int>).reduce((int a, int b) => a + b);
});
```

### Features

- **Type Safety**: Checks input type before processing
- **Error Handling**: Returns original value for incompatible types
- **List Processing**: Sums numeric array elements
- **Integration**: Works seamlessly with existing filter chain

## Advanced Tag Patterns

### Multi-Parameter Tags

```dart
// Parser for: {% box char: '*', width: 40 %}
any().starLazy(tagEnd()).flatten().optional() & // Parameters section
```

### Nested Tag Support

```dart
// Allow nested Liquid syntax
content = Template.parse(content, data: evaluator.context.all()).render();
```

### Conditional Tag Logic

```dart
String boxChar = this.content.isNotEmpty
    ? evaluator.evaluate(this.content[0]).toString()
    : '+';
```

### Dynamic Content Processing

```dart
List<String> lines = content.split('\n');
int maxLength = lines.map((line) => line.length).reduce((a, b) => a > b ? a : b);
```

## Error Handling

### Parser Error Handling

```dart
try {
  var boxChar = values[2] != null ? TextNode(values[2]) : null;
} catch (e) {
  // Handle parsing errors
  return Tag("box", [], body: [TextNode("Error processing tag")]);
}
```

### Evaluation Error Handling

```dart
try {
  String content = evaluator.evaluate(body[0]).toString().trim();
} catch (e) {
  buffer.write("Error: Could not evaluate tag content");
  return;
}
```

## Performance Considerations

1. **Content Caching**: Cache processed template content when possible
2. **Lazy Evaluation**: Only process content when tag is actually rendered
3. **Minimal Parsing**: Keep parser logic simple and efficient
4. **Buffer Usage**: Use buffer efficiently for output generation

```dart
// Efficient pattern
if (cached_content == null) {
  cached_content = Template.parse(content, data: context).render();
}
buffer.write(cached_content);
```

## Testing Custom Tags

```dart
void testBoxTag() {
  TagRegistry.register('box', (content, filters) => BoxTag(content, filters));
  
  final template = '{% box %}Test content{% endbox %}';
  final result = Template.parse(template).render();
  
  assert(result.contains('Test content'));
  assert(result.contains('+'));
}
```

## Related Examples

- [Basic Usage](basic-usage.md) - Filter and tag registration
- [Template Layouts](template-layouts.md) - Block tag usage
- [Drop Objects](drop-objects.md) - Custom object integration

## Best Practices

1. **Extend AbstractTag**: Use the base class for consistent behavior
2. **Implement CustomTagParser**: Required for custom parsing logic
3. **Handle Edge Cases**: Check for null content, empty parameters
4. **Use Buffer Efficiently**: Write output directly to buffer
5. **Support Template Syntax**: Allow Liquid code within tag content
6. **Provide Defaults**: Sensible defaults for optional parameters

## PetitParser Resources

For developers wanting to build more sophisticated custom tag parsers:

### Official Documentation
- [PetitParser Documentation](https://pub.dev/packages/petitparser) - Complete API reference
- [Parser Combinators Guide](https://github.com/petitparser/dart-petitparser) - Theory and examples

### Common Parser Patterns
```dart
// Identifier parsing (variable names, etc.)
Parser identifier() => letter().seq(word().star()).flatten();

// Number parsing (integers and floats)
Parser number() => digit().plus().seq(char('.').seq(digit().plus()).optional()).flatten();

// Quoted string parsing
Parser quotedString() => char('"').seq(char('"').neg().star()).seq(char('"')).pick(1).flatten();

// Whitespace handling
Parser ws() => whitespace().star();
Parser token(Parser parser) => parser.trim(ws());

// Comma-separated lists
Parser<List<T>> listOf<T>(Parser<T> parser) => 
    parser.separatedBy(char(',').trim()).map((result) => result.elements);
```

### Error Handling in Parsers
```dart
Parser safeParser() {
  return myComplexParser().or(
    // Fallback parser for error recovery
    any().starLazy(tagEnd()).map((_) => ErrorTag("Parse failed"))
  );
}
```

### Debugging Parser Issues
```dart
// Add debug output to understand parsing
Parser debugParser() {
  return myParser().map((result) {
    print('Parsed: $result');
    return result;
  });
}
``` 