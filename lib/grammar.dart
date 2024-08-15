import 'package:petitparser/petitparser.dart';
import 'ast.dart';

class LiquidGrammar extends GrammarDefinition {
  @override
  Parser start() => ref0(document).end();

  Parser document() => ref0(element)
      .plus()
      .map((contents) => Document(contents.cast<ASTNode>()));

  Parser element() => ref0(variable) | ref0(tag) | ref0(text);

  Parser tagStart() => string('{%-') | string('{%');
  Parser tagEnd() => string('-%}') | string('%}');
  Parser tagContent() =>
      (ref0(identifier) | ref0(variable) | ref0(textWithoutTagEnd))
          .star()
          .map((list) => list.cast<ASTNode>());

  Parser textWithoutTagEnd() => pattern('^{%').plus().flatten();

  Parser tag() => (tagStart() &
              ref0(identifier).trim() &
              ref0(tagContent).trim() &
              tagEnd())
          .map((values) {
        return Tag((values[1] as Identifier).name, values[2] as List<ASTNode>);
      });

  Parser varStart() => string('{{-') | string('{{');
  Parser varEnd() => string('-}}') | string('}}');

  Parser variable() =>
      (varStart().trim() & ref0(expression).trim() & varEnd()).map((values) {
        Expression expr = values[1] as Expression;
        String name = '';
        if (expr is Identifier) {
          name = expr.name;
        } else if (expr is MemberAccess) {
          name = (expr.object as Identifier).name;
        }
        return Variable(name, expr);
      });

  Parser expression() => ref0(memberAccess) | ref0(identifier) | ref0(literal);

  Parser identifier() =>
      (letter() & word().star()).flatten().map((name) => Identifier(name));

  Parser literal() =>
      (char('"') & any().starLazy(char('"')).flatten() & char('"'))
          .map((values) => Literal(values[1] as String));

  Parser memberAccess() =>
      (ref0(identifier) & (char('.') & ref0(identifier)).plus()).map((values) {
        var object = values[0] as Identifier;
        var members =
            (values[1] as List).map((m) => (m[1] as Identifier).name).toList();
        return MemberAccess(object, members);
      });

  Parser text() =>
      any().starLazy(string('{')).flatten().map((text) => TextNode(text));
}

Result parse(String input) {
  final parser = LiquidGrammar().build();
  return parser.parse(input);
}
