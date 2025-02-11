import 'package:liquify/parser.dart';
import 'package:test/test.dart';

/// A utility class for building matchers to validate AST structures
class ASTMatcher {
  /// Matches a Tag node with the given name and optional content/body matchers
  static Matcher tag(
    String name, {
    List<Matcher>? content,
    List<Matcher>? body,
  }) {
    return isA<Tag>()
        .having((t) => t.name, 'name', equals(name))
        .having(
          (t) => t.content,
          'content',
          content == null ? anything : containsAll(content),
        )
        .having(
          (t) => t.body,
          'body',
          body == null ? anything : containsAll(body),
        );
  }

  /// Matches a TextNode with the given text
  static Matcher text(String text) {
    return isA<TextNode>().having((t) => t.text, 'text', contains(text));
  }

  /// Matches literal content
  static Matcher literal(dynamic value) {
    return isA<Literal>().having((l) => l.value, 'value', contains(value));
  }

  /// Matches an identifier with the given name
  static Matcher identifier(String name) {
    return isA<Identifier>().having((i) => i.name, 'name', contains(name));
  }

  /// Validates that the AST contains nodes matching all the given matchers
  static void validateAST(List<ASTNode> ast, List<Matcher> matchers) {
    for (var matcher in matchers) {
      expect(
        ast,
        contains(matcher),
        reason: 'AST should contain node matching: $matcher',
      );
    }
  }

  /// Helper to find a specific block in the AST by name
  static Tag? findBlock(List<ASTNode> ast, String blockName) {
    for (var node in ast) {
      if (node is Tag && node.name == 'block') {
        // Check if this block's content contains the target name
        for (var content in node.content) {
          if (content is Identifier && content.name == blockName ||
              content is Literal && content.value.toString() == blockName) {
            return node;
          }
        }
      }
    }
    return null;
  }
}
