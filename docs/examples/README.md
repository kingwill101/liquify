# Examples

This directory contains comprehensive examples demonstrating various features and capabilities of the Liquid Grammar library.

## Quick Start Examples

### [Basic Usage](basic-usage.md)
- Template rendering fundamentals
- Variable interpolation
- Filters and data transformation
- Custom filters and tags

### [Template Layouts](template-layouts.md)
- Layout inheritance patterns
- Block definitions and overrides
- Multi-level template hierarchies
- Dynamic layout selection

### [File System Integration](file-system.md)
- Template loading from files
- Template inclusion and rendering
- File system abstraction
- Error handling for missing files

## Advanced Examples

### [Custom Tags](custom-tags.md)
- Creating custom tag implementations
- Parser integration patterns
- Complex tag logic with multiple blocks
- Tag registration and usage

### [Drop Objects](drop-objects.md)
- Custom object model integration
- Property access patterns
- Method invocation from templates
- Nested object hierarchies

## Example Categories

| Category | Description | Examples |
|----------|-------------|----------|
| **Basic** | Fundamental template operations | Variable output, loops, conditionals |
| **Filters** | Data transformation examples | Custom filters, filter chaining |
| **Tags** | Control flow and custom logic | Custom tags, block tags |
| **Layouts** | Template inheritance | Layout systems, block overrides |
| **Objects** | Custom data models | Drop classes, property access |
| **Files** | File system integration | Template loading, includes |

## Running Examples

All examples are self-contained Dart programs that can be run directly:

```bash
# Run basic example
dart run example/example.dart

# Run layout example
dart run example/layout.dart

# Run custom tag example
dart run example/custom_tag.dart

# Run drop objects example
dart run example/drop.dart

# Run file system example
dart run example/fs.dart
```

## Example Output

Each example produces formatted output demonstrating the specific features:

- **Template rendering results** - Showing the final generated content
- **Feature demonstrations** - Highlighting specific functionality
- **Error handling** - Showing graceful failure modes
- **Performance patterns** - Efficient usage examples

## Related Documentation

- [Tags Documentation](../tags/) - Complete tag reference
- [Filters Documentation](../filters/) - Complete filter reference
- [API Reference](../api/) - Core library documentation

## Contributing Examples

When adding new examples:

1. Create self-contained, runnable examples
2. Include comprehensive comments
3. Demonstrate both basic and advanced usage
4. Show error handling patterns
5. Provide expected output in comments 