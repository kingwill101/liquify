import 'package:liquify/src/ast.dart' show ASTNode, Filter;
import 'package:liquify/src/mixins/parser.dart' show CustomTagParser;
import 'package:liquify/src/tags/tags.dart' as tags;

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

  /// Returns a list of all registered tag names.
  static get tags => _tags.keys.toList();
}

/// Registers all built-in Liquid tags.
void registerBuiltInTags() {
  TagRegistry.register(
      'layout', (content, filters) => tags.LayoutTag(content, filters));
  TagRegistry.register(
      'super', (content, filters) => tags.SuperTag(content, filters));
  TagRegistry.register(
      'block', (content, filters) => tags.BlockTag(content, filters));
  TagRegistry.register(
      'echo', (content, filters) => tags.EchoTag(content, filters));
  TagRegistry.register(
      'assign', (content, filters) => tags.AssignTag(content, filters));
  TagRegistry.register(
      'increment', (content, filters) => tags.IncrementTag(content, filters));
  TagRegistry.register(
      'decrement', (content, filters) => tags.DecrementTag(content, filters));
  TagRegistry.register(
      'repeat', (content, filters) => tags.RepeatTag(content, filters));
  TagRegistry.register(
      'for', (content, filters) => tags.ForTag(content, filters));
  TagRegistry.register(
      'if', (content, filters) => tags.IfTag(content, filters));
  TagRegistry.register(
      'elseif', (content, filters) => tags.IfTag(content, filters));
  TagRegistry.register(
      'continue', (content, filters) => tags.ContinueTag(content, filters));
  TagRegistry.register(
      'break', (content, filters) => tags.BreakTag(content, filters));
  TagRegistry.register(
      'cycle', (content, filters) => tags.CycleTag(content, filters));
  TagRegistry.register(
      'tablerow', (content, filters) => tags.TableRowTag(content, filters));
  TagRegistry.register(
      'unless', (content, filters) => tags.UnlessTag(content, filters));
  TagRegistry.register(
      'capture', (content, filters) => tags.CaptureTag(content, filters));
  TagRegistry.register(
      'liquid', (content, filters) => tags.LiquidTag(content, filters));
  TagRegistry.register(
      'case', (content, filters) => tags.CaseTag(content, filters));
  TagRegistry.register(
      'raw', (content, filters) => tags.RawTag(content, filters));

  TagRegistry.register(
      'render', (content, filters) => tags.RenderTag(content, filters));
}
