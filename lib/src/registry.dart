import 'package:liquify/src/ast.dart';
import 'package:liquify/src/mixins/parser.dart';
import 'package:liquify/src/tags/tags.dart';

import 'tags/tag.dart';

/// TagRegistry is responsible for managing and creating Liquid template tags.
class TagRegistry {
  /// Map of tag names to their creator functions.
  static final Map<String, Function(List<ASTNode>, List<Filter>)> _tags = {};

  /// Map of tag names to their custom parser instances.
  static final Map<String, CustomTagParser> _customTagParsers = {};

  /// Returns a list of all registered custom tag parsers.
  static List<CustomTagParser> get customParsers =>
      _customTagParsers.entries.map((p) => p.value).toList();

  /// Registers a new tag with the given name and creator function.
  ///
  /// If the created tag implements CustomTagParser, it's also added to _customTagParsers.
  static void register(
      String name, Function(List<ASTNode>, List<Filter>) creator) {
    _tags[name] = creator;

    final creatorInstance = creator([].cast<ASTNode>(), [].cast<Filter>());
    if (creatorInstance is CustomTagParser) {
      _customTagParsers[name] = creatorInstance;
    }
  }

  /// Creates a tag instance with the given name, content, and filters.
  ///
  /// Returns null if the tag is not registered.
  static AbstractTag? createTag(
      String name, List<ASTNode> content, List<Filter> filters) {
    final creator = _tags[name];
    if (creator != null) {
      return creator(content, filters);
    }
    return null;
  }

  /// Checks if a tag with the given name has an end tag.
  static bool hasEndTag(String name) {
    final tag = _tags[name]?.call([], []);
    return tag?.hasEndTag ?? false;
  }

  /// Returns a list of all registered tag names.
  static get tags => _tags.keys.toList();
}

/// Registers all built-in Liquid tags.
void registerBuiltIns() {
  TagRegistry.register('echo', (content, filters) => EchoTag(content, filters));
  TagRegistry.register(
      'assign', (content, filters) => AssignTag(content, filters));
  TagRegistry.register(
      'increment', (content, filters) => IncrementTag(content, filters));
  TagRegistry.register(
      'decrement', (content, filters) => DecrementTag(content, filters));
  TagRegistry.register(
      'repeat', (content, filters) => RepeatTag(content, filters));
  TagRegistry.register('for', (content, filters) => ForTag(content, filters));
  TagRegistry.register('if', (content, filters) => IfTag(content, filters));
  TagRegistry.register('elseif', (content, filters) => IfTag(content, filters));
  TagRegistry.register(
      'continue', (content, filters) => ContinueTag(content, filters));
  TagRegistry.register(
      'break', (content, filters) => BreakTag(content, filters));
  TagRegistry.register(
      'cycle', (content, filters) => CycleTag(content, filters));
  TagRegistry.register(
      'tablerow', (content, filters) => TableRowTag(content, filters));
  TagRegistry.register(
      'unless', (content, filters) => UnlessTag(content, filters));
  TagRegistry.register(
      'capture', (content, filters) => CaptureTag(content, filters));
  TagRegistry.register(
      'liquid', (content, filters) => LiquidTag(content, filters));
  TagRegistry.register('case', (content, filters) => CaseTag(content, filters));
  TagRegistry.register('raw', (content, filters) => RawTag(content, filters));
}
