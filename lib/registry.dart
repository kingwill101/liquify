import 'package:liquid_grammar/ast.dart';

class TagRegistry {
  static final List<String> _tags = [
    'assign',
    'capture',
    'comment',
    'cycle',
    'for',
    'if',
    'case',
    'when',
    'liquid',
    'raw',
  ];
  static final Map<String, Function(List<ASTNode>, List<Filter>)> _tags = {};

  static void register(
      String name, Function(List<ASTNode>, List<Filter>) creator) {
    _tags[name] = creator;
  }

  static void register(String name) {
    _tags.add(name);
  static BaseTag? createTag(
      String name, List<ASTNode> content, List<Filter> filters) {
    final creator = _tags[name];
    if (creator != null) {
      return creator(content, filters);
    }
    return null;
  }

  static List<String> get tags => _tags;
  static bool hasEndTag(String name) {
    final tag = _tags[name]?.call([], []);
    return tag?.hasEndTag ?? false;
  }

  static get tags => _tags.keys.toList();
}

}
