/// Liquify: Core components for Liquid template parsing and rendering in Dart
///
/// This library provides a comprehensive implementation of the Liquid template language
/// for Dart applications, supporting both synchronous and asynchronous rendering,
/// custom tags, filters, and file system integration.
///
/// Key Components:
///
/// 1. [Template]: The main entry point for template processing. Supports both string
///    and file-based templates with sync/async rendering, plus environment-scoped
///    filters and tags for security and isolation:
///    ```dart
///    // Basic template usage
///    final template = Template.parse('Hello {{ name }}!', data: {'name': 'World'});
///    print(await template.renderAsync()); // Output: Hello World!
///
///    // File-based template with custom root
///    final root = MapRoot({'header.liquid': 'Welcome {{ user }}!'});
///    final fileTemplate = Template.fromFile('header.liquid', root);+

///    // Template with environment setup callback
///    final customTemplate = Template.parse(
///      'Hello {{ name | emphasize }}! {% custom_tag %}',
///      data: {'name': 'World'},
///      environmentSetup: (env) {
///        // Register custom filters and tags for this template only
///        env.registerLocalFilter('emphasize', (value, args, namedArgs) =>
///          '***${value.toString().toUpperCase()}***');
///        env.registerLocalTag('custom_tag', (content, filters) =>
///          MyCustomTag(content, filters));
///      },
///    );
///
///    // Secure template with strict mode (blocks global registry access)
///    final secureEnv = Environment.withStrictMode();
///    secureEnv.registerLocalFilter('safe', (value, args, namedArgs) =>
///      sanitize(value.toString()));
///    final secureTemplate = Template.parse(
///      'Safe: {{ userInput | safe }}',
///      data: {'userInput': '<script>alert("xss")</script>'},
///      environment: secureEnv,
///    );
///    ```
///
/// 2. [Layout]: Template inheritance system for creating reusable base templates:
///    ```dart
///    // Define a base layout (base.liquid)
///    final root = MapRoot({
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
/// 4. [FilterRegistry]: Global registry for custom filters. Also supports environment-scoped
///    filters for isolation and security:
///    ```dart
///    // Register a global filter
///    FilterRegistry.register('uppercase', (input) => input.toString().toUpperCase());
///
///    // Register environment-scoped filters (preferred for security)
///    final env = Environment();
///    env.registerLocalFilter('sanitize', (value, args, namedArgs) =>
///      sanitizeHtml(value.toString()));
///    env.registerLocalFilter('truncate', (value, args, namedArgs) {
///      final maxLen = args.isNotEmpty ? args[0] as int : 50;
///      return value.toString().length > maxLen
///        ? '${value.toString().substring(0, maxLen)}...'
///        : value.toString();
///    });
///    ```
///
/// 5. [Environment]: Execution context with support for scoped filters and tags:
///    ```dart
///    // Create environment with local filters/tags
///    final env = Environment();
///    env.registerLocalFilter('custom', (value, args, namedArgs) => 'CUSTOM:$value');
///    env.registerLocalTag('mytag', (content, filters) => MyTag(content, filters));
///
///    // Strict mode environment (security sandboxing)
///    final secureEnv = Environment.withStrictMode();
///    secureEnv.registerLocalFilter('safe', (value, args, namedArgs) => escape(value));
///    // secureEnv.getFilter('dangerous_global_filter') returns null
///
///    // Environment cloning and inheritance
///    final childEnv = env.clone();
///    childEnv.registerLocalFilter('child_only', (value, args, namedArgs) => value);
///    ```
///
/// 6. [Root]: File system abstraction for template resolution:
///    ```dart
///    // Create an in-memory file system
///    final root = MapRoot({
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
///   final root = MapRoot({
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
/// - **Environment-scoped filters and tags** for isolation and security
/// - **Strict mode** for security sandboxing (blocks global registry access)
/// - **Template-level customization** via environment setup callbacks
/// - Context management with nested scopes
/// - Full Liquid syntax support including control flow and iteration
/// - Drop interface for custom object behavior
/// - Environment cloning for inheritance patterns
///
/// For detailed API documentation, see the individual class and function
/// documentation.
library;

export 'package:liquify/src/fs.dart';
export 'package:liquify/src/util.dart';
export 'package:liquify/src/template.dart';
export 'package:liquify/src/context.dart';
export 'package:liquify/src/drop.dart';
export 'package:liquify/src/tag_registry.dart';
export 'package:liquify/src/filter_registry.dart';
export 'package:liquify/src/filters/module.dart';
