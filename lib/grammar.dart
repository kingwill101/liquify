import 'package:petitparser/petitparser.dart';
import 'ast.dart';

class LiquidGrammar extends GrammarDefinition {
  @override
  Parser start() => ref0(document).end();

  Parser document() => ref0(element)
      .star()
      .map((elements) => Document(elements.cast<ASTNode>()));

  Parser element() => ref0(tag) | ref0(variable) | ref0(text);

  Parser tagStart() => string('{%-') | string('{%');
  Parser tagEnd() => string('-%}') | string('%}');

  Parser tag() => (tagStart() &
              ref0(identifier).trim() &
              ref0(tagContent).trim() &
              ref0(filter).star().trim() &
              tagEnd())
          .map((values) {
        return Tag((values[1] as Identifier).name,
            (values[2] as List<ASTNode>).cast<ASTNode>(),
            filters: (values[3] as List).cast<Filter>());
      });

  Parser filter() {
    return (char('|').trim() &
            ref0(identifier).trim() &
            (char(':').trim() &
                    (ref0(namedArgument) | ref0(literal) | ref0(identifier))
                        .plusSeparated(char(',').trim()))
                .optional())
        .map((values) {
      final filterName = values[1] as Identifier;
      final args = values[2] != null
          ? (values[2] as List)[1].elements.cast<ASTNode>()
          : <ASTNode>[];
      return Filter(filterName, args);
    });
  }

  Parser tagContent() {
    return (ref0(assignment) | ref0(argument)).star().map((values) {
      var result = [];
      for (final i in values) {
        if (i is List) {
          result.addAll(i);
        } else {
          result.add(i);
        }
      }
      return result.cast<ASTNode>();
    });
  }

  Parser assignment() {
    return (ref0(identifier).trim() &
            char('=').trim() &
            (ref0(literal) | ref0(expression)))
        .map((values) {
      return Assignment(
          (values[0] as Identifier).name, values[2] as Expression);
    });
  }

Parser argument() {
  return (ref0(literal) | ref0(identifier))
      .separatedBy(char(',').trim().or(whitespace().plus()))
      .map((result) {
    return result.whereType<ASTNode>().toList();
  });
}




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

  Parser namedArgument() {
    return (ref0(identifier) &
            char(':').trim() &
            (ref0(literal) | ref0(identifier)))
        .map((values) {
      return NamedArgument(values[0] as Identifier, values[2] as Expression);
    });
  }

  Parser identifier() {
    return (letter() & word().star()).flatten().map((name) => Identifier(name));
  }

  Parser literal() {
    return ref0(booleanLiteral) | ref0(numericLiteral) | ref0(stringLiteral);
  }

  Parser numericLiteral() {
    return digit().plus().flatten().map((value) {
      return Literal(value, LiteralType.number);
    });
  }

  Parser stringLiteral() {
    return (char('"') & pattern('^"').star().flatten() & char('"') |
            char("'") & pattern("^'").star().flatten() & char("'"))
        .map((values) {
      return Literal(values[1], LiteralType.string);
    });
  }

  Parser booleanLiteral() {
    return (string('true') | string('false')).map((value) {
      return Literal(value == 'true', LiteralType.boolean);
    });
  }

  Parser expression() => ref0(memberAccess) | ref0(identifier);

  Parser memberAccess() =>
      (ref0(identifier) & (char('.') & ref0(identifier)).plus()).map((values) {
        var object = values[0] as Identifier;
        var members =
            (values[1] as List).map((m) => (m[1] as Identifier).name).toList();
        return MemberAccess(object, members);
      });

  Parser text() => pattern('^{').plus().flatten().map((text) => TextNode(text));
}
