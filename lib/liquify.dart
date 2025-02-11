/// Liquify: Core components for Liquid template parsing and rendering in Dart
///
/// This library provides a comprehensive implementation of the Liquid template language
/// for Dart applications, supporting both synchronous and asynchronous rendering,
/// custom tags, filters, and file system integration.
///
/// Key Components:
///
/// 1. [Template]: The main entry point for template processing. Supports both string
///    and file-based templates with sync/async rendering:
///    ```dart
///    // String-based template
///    final template = Template.parse('Hello {{ name }}!', data: {'name': 'World'});
///
///    // Sync rendering
///    print(template.render()); // Output: Hello World!
///
///    // Async rendering
///    print(await template.renderAsync()); // Output: Hello World!
///
///    // File-based template with custom root
///    final root = Root.memory({'header.liquid': 'Welcome {{ user }}!'});
///    final fileTemplate = Template.fromFile('header.liquid', root);
///    ```
///
/// 2. [TagRegistry]: Registry for custom Liquid tags. Supports both sync and async tags:
///    ```dart
///    // Register a custom tag
///    TagRegistry.register('mytag', (content, filters) {
///      return MyCustomTag(content, filters);
///    });
///    ```
///
/// 3. [FilterRegistry]: Registry for custom filters. Supports both sync and async filters:
///    ```dart
///    // Register a sync filter
///    FilterRegistry.register('uppercase', (input) => input.toString().toUpperCase());
///
///    // Register an async filter
///    FilterRegistry.register('fetchData', (input) async =>
///      await someAsyncOperation(input));
///    ```
///
/// 4. [Root]: File system abstraction for template resolution:
///    ```dart
///    // Create an in-memory file system
///    final root = Root.memory({
///      'layout.liquid': '{% include "header.liquid" %}{{ content }}',
///      'header.liquid': 'Header: {{ title }}'
///    });
///
///    // Or use the actual file system
///    final root = Root.fs('/path/to/templates');
///    ```
///
/// Advanced Usage Example:
/// ```dart
/// Future<void> main() async {
///   // Setup template environment
///   final root = Root.memory({
///     'layout.liquid': '''
///       {% include "header.liquid" %}
///       {{ content | uppercase }}
///       {% for item in items %}
///         - {{ item }}
///       {% endfor %}
///     '''
///   });
///
///   // Create and configure template
///   final template = Template.fromFile('layout.liquid', root)
///     ..updateContext({
///       'title': 'Welcome',
///       'content': 'Main content',
///       'items': ['a', 'b', 'c']
///     });
///
///   // Render asynchronously
///   final result = await template.renderAsync();
///   print(result);
/// }
/// ```
///
/// Features:
/// - Sync and async rendering support
/// - File system abstraction for template resolution
/// - Custom tags and filters (both sync and async)
/// - Context management with nested scopes
/// - Full Liquid syntax support including control flow and iteration
/// - Drop interface for custom object behavior
///
/// For detailed API documentation, see the individual class and function
/// documentation.
library;

export 'package:liquify/src/fs.dart';
export 'package:liquify/src/util.dart';
export 'package:liquify/src/template.dart';
export 'package:liquify/src/drop.dart';
export 'package:liquify/src/tag_registry.dart';
export 'package:liquify/src/filter_registry.dart';
export 'package:liquify/src/filters/module.dart';
