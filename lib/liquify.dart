/// Liquify: Core components for Liquid template parsing and rendering in Dart
///
/// This library exports the essential classes and functions needed for working
/// with Liquid templates in Dart applications. It provides access to the main
/// parsing and rendering functionality, as well as registries for tags and filters.
///
/// Key components:
///
/// 1. [Template]: Provides methods for parsing and rendering Liquid templates.
///    Use this class as the main entry point for template processing.
///
/// 2. [TagRegistry]: Manages the registration and creation of custom Liquid tags.
///    This allows you to extend the template engine with new tag functionality.
///
/// 3. [FilterRegistry]: Handles the registration and retrieval of custom filters.
///    Use this to add new filters or access existing ones for template rendering.
///
/// Usage:
/// To use the core Liquify functionality in your Dart project, import this library:
///
/// ```dart
/// import 'package:liquify/liquify.dart';
/// ```
///
/// Example:
/// ```dart
/// void main() {
///   // Parse and render a simple template
///   String result = Template.parse("Hello, {{ name }}!", data: {"name": "World"});
///   print(result); // Output: Hello, World!
///
///   // Register a custom tag (if needed)
///   TagRegistry.register('mytag', (content, filters) => MyCustomTag(content, filters));
///
///   // Register a custom filter (if needed)
///   FilterRegistry.register('myfilter', myFilterFunction);
/// }
/// ```
///
/// For more detailed information on specific components, refer to the
/// documentation of the individual exported classes and functions.
library;

export 'package:liquify/src/fs.dart';
export 'package:liquify/src/util.dart';
export 'package:liquify/src/template.dart';
export 'package:liquify/src/drop.dart';
export 'package:liquify/src/tag_registry.dart';
export 'package:liquify/src/filter_registry.dart';
export 'package:liquify/src/filters/module.dart';
