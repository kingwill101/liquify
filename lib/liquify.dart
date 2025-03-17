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
/// 2. [Layout]: Template inheritance system for creating reusable base templates:
///    ```dart
///    // Define a base layout (base.liquid)
///    final root = Root.memory({
///      'layouts/base.liquid': '''
///        <!DOCTYPE html>
///        <html>
///          <head>
///            <title>{% block title %}Default Title{% endblock %}</title>
///          </head>
///          <body>
///            {% block content %}{% endblock %}
///          </body>
///        </html>
///      ''',
///      'page.liquid': '''
///        {% layout "layouts/base.liquid" %}
///        {% block title %}My Page{% endblock %}
///        {% block content %}
///          <h1>Welcome!</h1>
///        {% endblock %}
///      '''
///    });
///
///    final template = Template.fromFile('page.liquid', root);
///    ```
///
/// 3. [TagRegistry]: Registry for custom Liquid tags. Supports both sync and async tags:
///    ```dart
///    // Register a custom tag
///    TagRegistry.register('mytag', (content, filters) {
///      return MyCustomTag(content, filters);
///    });
///    ```
///
/// 4. [FilterRegistry]: Registry for custom filters. Supports both sync and async filters:
///    ```dart
///    // Register a sync filter
///    FilterRegistry.register('uppercase', (input) => input.toString().toUpperCase());
///
///    // Register an async filter
///    FilterRegistry.register('fetchData', (input) async =>
///      await someAsyncOperation(input));
///    ```
///
/// 5. [Root]: File system abstraction for template resolution:
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
/// Advanced Usage Example with Layouts:
/// ```dart
/// Future<void> main() async {
///   // Setup template environment with layouts
///   final root = Root.memory({
///     'layouts/base.liquid': '''
///       <!DOCTYPE html>
///       <html>
///         <head>
///           <title>{% block title %}{% endblock %}</title>
///           {% block meta %}{% endblock %}
///         </head>
///         <body>
///           {% block content %}{% endblock %}
///         </body>
///       </html>
///     ''',
///     'layouts/post.liquid': '''
///       {% layout "layouts/base.liquid" %}
///       {% block content %}
///         <article>
///           <h1>{{ post.title }}</h1>
///           {% block post_content %}{% endblock %}
///         </article>
///       {% endblock %}
///     ''',
///     'blog-post.liquid': '''
///       {% layout "layouts/post.liquid", post: post %}
///       {% block title %}{{ post.title }} - Blog{% endblock %}
///       {% block post_content %}
///         {{ post.body }}
///       {% endblock %}
///     '''
///   });
///
///   // Create and configure template
///   final template = Template.fromFile('blog-post.liquid', root)
///     ..updateContext({
///       'post': {
///         'title': 'Hello World',
///         'body': 'Welcome to my blog!'
///       }
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
/// - Template inheritance through layouts
/// - Named block support with default content
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
