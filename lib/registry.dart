import 'package:liquid_grammar/ast.dart';
import 'package:liquid_grammar/tags/break.dart';
import 'package:liquid_grammar/tags/continue.dart';
import 'package:liquid_grammar/tags/if.dart';

import 'tag.dart';
import 'tags/echo.dart';
import 'tags/for.dart';
import 'tags/repeat.dart';

class TagRegistry {
  static final Map<String, Function(List<ASTNode>, List<Filter>)> _tags = {};

  static void register(
      String name, Function(List<ASTNode>, List<Filter>) creator) {
    _tags[name] = creator;
  }

  static BaseTag? createTag(
      String name, List<ASTNode> content, List<Filter> filters) {
    final creator = _tags[name];
    if (creator != null) {
      return creator(content, filters);
    }
    return null;
  }

  static bool hasEndTag(String name) {
    final tag = _tags[name]?.call([], []);
    return tag?.hasEndTag ?? false;
  }

  static get tags => _tags.keys.toList();
}

// Register tags
void registerBuiltIns() {
  TagRegistry.register('echo', (content, filters) => EchoTag(content, filters));
  TagRegistry.register(
      'repeat', (content, filters) => RepeatTag(content, filters));
  TagRegistry.register('for', (content, filters) => ForTag(content, filters));
  TagRegistry.register('if', (content, filters) => IfTag(content, filters));
  TagRegistry.register('continue', (content, filters) => ContinueTag(content, filters));
  TagRegistry.register('break', (content, filters) => BreakTag(content, filters));
}
