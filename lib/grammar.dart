import 'package:petitparser/petitparser.dart';
import 'ast.dart';

class LiquidGrammar extends GrammarDefinition {
  @override
  Parser start() => ref0(document).end();

Parser document() => ref0(element).star().map((elements) => Document(elements.cast<ASTNode>()));

  Parser element() => ref0(tag) | ref0(variable) | ref0(text);

  Parser tagStart() => string('{%-') | string('{%');
  Parser tagEnd() => string('-%}') | string('%}');

Parser tag() =>
    (tagStart() & ref0(identifier).trim() & ref0(tagArguments).optional().trim() & tagEnd())
        .map((values) {
      return Tag((values[1] as Identifier).name, (values[2] as List<ASTNode>?) ?? []);
    });


  Parser tagArguments() =>
      (ref0(commaSeparatedArguments) | ref0(spaceSeparatedArguments))
      .map((result) => result.cast<ASTNode>());

  Parser commaSeparatedArguments() =>
      ref0(argument).plusSeparated(char(',').trim())
      .map((result) => result.elements);

  Parser spaceSeparatedArguments() =>
      ref0(argument).trim().plus();

  Parser argument() =>
      ref0(assignment) | ref0(identifier) | ref0(literal) | ref0(variable);

  Parser assignment() =>
      (ref0(identifier).trim() & char('=').trim() & ref0(literal).trim())
      .map((values) => Assignment((values[0] as Identifier).name, values[2] as Literal));

  Parser varStart() => string('{{-') | string('{{');
  Parser varEnd() => string('-}}') | string('}}');

  Parser variable() =>
      (varStart().trim() & ref0(expression).trim() & varEnd())
          .map((values) {
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

  Parser memberAccess() => 
      (ref0(identifier) & (char('.') & ref0(identifier)).plus())
      .map((values) {
        var object = values[0] as Identifier;
        var members = (values[1] as List).map((m) => (m[1] as Identifier).name).toList();
        return MemberAccess(object, members);
      });

  Parser identifier() => 
      (letter() & word().star())
      .flatten()
      .map((name) => Identifier(name));

  Parser literal() =>
      (char('"') & pattern('^"').star().flatten() & char('"'))
      .map((values) => Literal(values[1]));

  Parser text() => pattern('^{').plus().flatten().map((text) => TextNode(text));
}
