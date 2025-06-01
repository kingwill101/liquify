# File System Integration Examples

This document demonstrates how to work with template files, including loading templates from file systems, template inclusion patterns, and error handling for missing files.

## Overview

The file system example showcases:
- Virtual file system creation with MapRoot
- Template loading from files
- Template inclusion and rendering
- Template composition patterns
- Error handling for missing files

## Complete Example Code

```dart
import 'package:liquify/liquify.dart';

void main() {
  // Create a simple file system structure using MapRoot
  final fs = MapRoot({
    'resume.liquid': '''
Name: {{ name }}
Skills: {{ skills | join: ", " }}
{% render 'greeting.liquid' with name: name, greeting: "Welcome" %}
Experience:
{% render 'list.liquid' with items: experience %}
''',
    'greeting.liquid': '{{ greeting }}, {{ name }}!',
    'list.liquid': '{% for item in items %}- {{ item }}\n{% endfor %}',
  });

  // Create a context with some variables
  final context = {
    'name': 'Alice Johnson',
    'skills': ['Dart', 'Flutter', 'Liquid'],
    'experience': [
      '5 years as a Software Developer',
      '3 years of Flutter development',
      '2 years of Dart programming'
    ],
  };

  // Example 1: Render resume (which includes greeting and list)
  print('Example 1: Render resume (including greeting and list)');
  final resumeTemplate = Template.fromFile('resume.liquid', fs, data: context);
  print(resumeTemplate.render());

  // Example 2: Render greeting directly
  print('\nExample 2: Render greeting directly');
  final greetingTemplate = Template.fromFile('greeting.liquid', fs,
      data: {'name': 'Bob', 'greeting': 'Good morning'});
  print(greetingTemplate.render());

  // Example 3: Render list directly
  print('\nExample 3: Render list directly');
  final listTemplate = Template.fromFile('list.liquid', fs, data: {
    'items': ['Item 1', 'Item 2', 'Item 3']
  });
  print(listTemplate.render());

  // Example 4: Attempt to render non-existent file
  print('\nExample 4: Attempt to render non-existent file');
  try {
    Template.fromFile('nonexistent.liquid', fs, data: context);
  } catch (e) {
    print('Error: $e');
  }
}
```

## File System Structure

### Virtual File System Creation

```dart
final fs = MapRoot({
  'resume.liquid': '''[resume template content]''',
  'greeting.liquid': '''[greeting template content]''',
  'list.liquid': '''[list template content]''',
});
```

#### MapRoot Features
- **Virtual File System**: Creates in-memory file system for testing
- **Path-based Access**: Files accessed by string paths
- **Template Storage**: Maps file paths to template content
- **Development Tool**: Ideal for examples and testing

### Template Files

#### Main Resume Template: `resume.liquid`
```liquid
Name: {{ name }}
Skills: {{ skills | join: ", " }}
{% render 'greeting.liquid' with name: name, greeting: "Welcome" %}
Experience:
{% render 'list.liquid' with items: experience %}
```

**Features Demonstrated:**
- Variable interpolation: `{{ name }}`
- Filter usage: `{{ skills | join: ", " }}`
- Template inclusion: `{% render 'greeting.liquid' %}`
- Variable passing: `with name: name, greeting: "Welcome"`

#### Greeting Template: `greeting.liquid`
```liquid
{{ greeting }}, {{ name }}!
```

**Features Demonstrated:**
- Simple variable output
- Reusable template components
- Parameter acceptance from parent templates

#### List Template: `list.liquid`
```liquid
{% for item in items %}- {{ item }}
{% endfor %}
```

**Features Demonstrated:**
- Loop-based content generation
- Array parameter processing
- Formatted output generation

## Template Loading Patterns

### Loading from File System

```dart
final resumeTemplate = Template.fromFile('resume.liquid', fs, data: context);
```

#### Parameters
- **File Path**: `'resume.liquid'` - Path to template file
- **File System**: `fs` - File system abstraction
- **Data Context**: `data: context` - Variables for template

#### Features
- **Path Resolution**: Resolves template paths relative to file system root
- **Context Integration**: Merges provided data with template variables
- **Lazy Loading**: Templates loaded only when accessed

### Direct Template Rendering

```dart
print(resumeTemplate.render());
```

- **Synchronous Rendering**: Immediate template processing
- **String Output**: Returns rendered template as string
- **Error Propagation**: Throws exceptions for template errors

## Template Inclusion Patterns

### Render Tag Usage

```liquid
{% render 'greeting.liquid' with name: name, greeting: "Welcome" %}
```

#### Syntax Components
- **Template Path**: `'greeting.liquid'` - Path to included template
- **Variable Passing**: `with name: name, greeting: "Welcome"`
- **Scoped Context**: Included template receives specified variables

#### Variable Scope
```liquid
{% render 'greeting.liquid' with name: name, greeting: "Welcome" %}
```
- **Explicit Variables**: Only specified variables passed to included template
- **Isolated Scope**: Included template doesn't access parent variables directly
- **Return Integration**: Rendered content inserted at inclusion point

### Multiple Template Inclusion

```liquid
Experience:
{% render 'list.liquid' with items: experience %}
```

- **Sequential Inclusion**: Multiple templates can be included in sequence
- **Context Switching**: Each inclusion can have different variable context
- **Content Composition**: Build complex output from simple components

## Example Outputs

### Example 1: Complete Resume

```
Example 1: Render resume (including greeting and list)
Name: Alice Johnson
Skills: Dart, Flutter, Liquid
Welcome, Alice Johnson!
Experience:
- 5 years as a Software Developer
- 3 years of Flutter development
- 2 years of Dart programming
```

**Composition Breakdown:**
1. Direct variable: `Name: Alice Johnson`
2. Filtered array: `Skills: Dart, Flutter, Liquid`
3. Included greeting: `Welcome, Alice Johnson!`
4. Included list: Experience items with bullet points

### Example 2: Direct Greeting

```
Example 2: Render greeting directly
Good morning, Bob!
```

**Features:**
- Different data context
- Direct template loading
- Independent variable scope

### Example 3: Direct List

```
Example 3: Render list directly
- Item 1
- Item 2
- Item 3
```

**Features:**
- Simplified data structure
- Loop-based rendering
- Consistent formatting

### Example 4: Error Handling

```
Example 4: Attempt to render non-existent file
Error: [specific error message about missing file]
```

**Error Handling:**
- Graceful exception handling
- Clear error messages
- Development debugging support

## Advanced File System Patterns

### Hierarchical File Organization

```dart
final fs = MapRoot({
  'layouts/base.liquid': '''[base layout]''',
  'layouts/post.liquid': '''[post layout]''',
  'partials/header.liquid': '''[header partial]''',
  'partials/footer.liquid': '''[footer partial]''',
  'pages/home.liquid': '''[home page]''',
  'pages/about.liquid': '''[about page]''',
});
```

### Directory-based Inclusion

```liquid
{% render 'partials/header.liquid' %}
{% render 'layouts/base.liquid' %}
{% render 'partials/footer.liquid' %}
```

### Conditional File Loading

```liquid
{% if user.is_admin %}
  {% render 'admin/dashboard.liquid' %}
{% else %}
  {% render 'user/profile.liquid' %}
{% endif %}
```

## Real File System Integration

### Using Actual Files

```dart
import 'dart:io';

// Create file system from actual directory
final fs = FileSystemRoot(Directory('templates'));

// Load template from file
final template = Template.fromFile('user/profile.liquid', fs);
```

### Async File Loading

```dart
final template = await Template.fromFileAsync('large-template.liquid', fs);
final result = await template.renderAsync(data: context);
```

## Error Handling Strategies

### Missing File Handling

```dart
try {
  final template = Template.fromFile('missing.liquid', fs, data: context);
  print(template.render());
} catch (e) {
  print('Template not found: $e');
  // Provide fallback content
  print('Using default template');
}
```

### Template Error Handling

```dart
try {
  final template = Template.fromFile('template.liquid', fs, data: context);
  print(template.render());
} catch (e) {
  if (e is TemplateNotFoundException) {
    print('Template file not found');
  } else if (e is TemplateSyntaxException) {
    print('Template syntax error: $e');
  } else {
    print('Unexpected error: $e');
  }
}
```

### Graceful Degradation

```dart
String renderTemplate(String path, Map<String, dynamic> data) {
  try {
    final template = Template.fromFile(path, fs, data: data);
    return template.render();
  } catch (e) {
    // Log error and return fallback
    print('Template error: $e');
    return 'Content temporarily unavailable';
  }
}
```

## Performance Considerations

### Template Caching

```dart
final Map<String, Template> templateCache = {};

Template getCachedTemplate(String path) {
  templateCache[path] ??= Template.fromFile(path, fs);
  return templateCache[path]!;
}
```

### Lazy Loading

```dart
class LazyTemplate {
  final String path;
  final FileSystem fs;
  Template? _template;
  
  LazyTemplate(this.path, this.fs);
  
  Template get template {
    _template ??= Template.fromFile(path, fs);
    return _template!;
  }
}
```

### Precompilation

```dart
// Precompile frequently used templates
final commonTemplates = {
  'header': Template.fromFile('partials/header.liquid', fs),
  'footer': Template.fromFile('partials/footer.liquid', fs),
  'navigation': Template.fromFile('partials/nav.liquid', fs),
};
```

## Testing File System Templates

### Mock File System

```dart
void testTemplateInclusion() {
  final mockFs = MapRoot({
    'parent.liquid': '{% render "child.liquid" with message: "Hello" %}',
    'child.liquid': '{{ message }}, World!',
  });
  
  final template = Template.fromFile('parent.liquid', mockFs);
  final result = template.render();
  
  assert(result.trim() == 'Hello, World!');
}
```

### Integration Testing

```dart
void testRealFileSystem() async {
  final tempDir = Directory.systemTemp.createTempSync();
  
  // Create test files
  File('${tempDir.path}/test.liquid').writeAsStringSync('Hello {{ name }}');
  
  final fs = FileSystemRoot(tempDir);
  final template = Template.fromFile('test.liquid', fs, data: {'name': 'World'});
  
  assert(template.render() == 'Hello World');
  
  // Cleanup
  tempDir.deleteSync(recursive: true);
}
```

## Related Examples

- [Template Layouts](template-layouts.md) - Layout inheritance with file systems
- [Basic Usage](basic-usage.md) - Template fundamentals
- [Custom Tags](custom-tags.md) - Custom tag with file integration

## Best Practices

1. **Use MapRoot for Testing**: Virtual file systems for unit tests and examples
2. **Handle Missing Files**: Always wrap file operations in try-catch blocks
3. **Cache Templates**: Cache parsed templates for better performance
4. **Organize Hierarchically**: Use directory structure for template organization
5. **Validate Paths**: Check template paths before loading
6. **Provide Fallbacks**: Have default content for missing templates
7. **Log Errors**: Log template errors for debugging and monitoring 