import 'package:liquify/src/ast.dart';

class PartialArguments {
  final ASTNode? binding;
  final String? alias;
  final bool iterate;

  PartialArguments(List<ASTNode> content)
    : binding = _binding(content),
      alias = _alias(content),
      iterate = _keywordAt(content, 0, 'for');

  static bool _keywordAt(List<ASTNode> nodes, int index, String keyword) =>
      index < nodes.length &&
      nodes[index] is Identifier &&
      (nodes[index] as Identifier).name == keyword;

  static ASTNode? _binding(List<ASTNode> nodes) {
    if (_keywordAt(nodes, 0, 'for') || _keywordAt(nodes, 0, 'with')) {
      if (nodes.length < 2) throw ArgumentError('Expected a partial binding');
      return nodes[1];
    }
    return null;
  }

  static String? _alias(List<ASTNode> nodes) {
    if (!_keywordAt(nodes, 2, 'as')) return null;
    if (nodes.length < 4 || nodes[3] is! Identifier) {
      throw ArgumentError('Expected a partial binding alias');
    }
    return (nodes[3] as Identifier).name;
  }

  String bindingName(String template) => alias ?? template.split('/').last;
}
