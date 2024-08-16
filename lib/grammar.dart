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

  // Make tagContent optional to handle empty tags
  Parser tag() => (tagStart() &
              ref0(identifier).trim() &
              ref0(tagContent).optional().trim() &  // Optional content
              ref0(filter).star().trim() &
              tagEnd())
          .map((values) {
        return Tag((values[1] as Identifier).name,
            (values[2] as List<ASTNode>?) ?? [],
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

  // Make sure tagContent can be empty (optional expressions)
  Parser tagContent() {
    return ref0(expression).optional().map((values) {
      if (values == null) {
        return <ASTNode>[];
      }
      if (values is List) {
        return values.cast<ASTNode>();
      } else {
        return [values as ASTNode];
      }
    });
  }

  Parser assignment() {
    return (ref0(identifier).trim() &
            char('=').trim() &
            ref0(expression).trim())
        .map((values) {
      return Assignment(
          (values[0] as Identifier).name, values[2] as Expression);
    });
  }

  Parser argument() {
    return (ref0(literal) | ref0(identifier))
        .plusSeparated(char(',').trim())
        .or(ref0(expression).plusSeparated(whitespace().plus()))
        .map((result) => result.elements.cast<ASTNode>());
  }

  Parser varStart() => string('{{-') | string('{{');
  Parser varEnd() => string('-}}') | string('}}');

  Parser variable() =>
      (varStart().trim() & ref0(expression).trim() & varEnd()).map((values) {
        Expression expr = values[1] is List
            ? values[1][0] as Expression
            : values[1] as Expression;
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
    return (letter() & word().star())
        .flatten()
        .where((name) => name != 'and' && name != 'or' && name != 'not')
        .map((name) => Identifier(name));
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

  // The expression parser is the main parser for evaluating expressions
  Parser expression() {
    return ref0(logicalExpression)
        .or(ref0(comparison))
        .or(ref0(unaryOperation))
        .or(ref0(memberAccess))
        .or(ref0(assignment))
        // .or(ref0(argument).optional())
        .or(ref0(literal))
        .or(ref0(identifier));
  }

  Parser memberAccess() =>
      (ref0(identifier) & (char('.') & ref0(identifier)).plus()).map((values) {
        var object = values[0] as Identifier;
        var members =
            (values[1] as List).map((m) => (m[1] as Identifier).name).toList();
        return MemberAccess(object, members);
      });

  Parser text() => pattern('^{').plus().flatten().map((text) => TextNode(text));

  Parser comparisonOperator() =>
      string('==').trim() |
      string('!=').trim() |
      string('<=').trim() |
      string('>=').trim() |
      char('<').trim() |
      char('>').trim();

  Parser logicalOperator() => string('and').trim() | string('or').trim();

  Parser comparison() {
    return (ref0(memberAccess) | ref0(identifier) | ref0(literal))
        .seq(ref0(comparisonOperator))
        .seq(ref0(memberAccess) | ref0(identifier) | ref0(literal))
        .map((values) => BinaryOperation(values[0], values[1], values[2]));
  }

  Parser logicalExpression() {
    return ref0(comparison)
        .seq(ref0(logicalOperator).seq(ref0(comparison)).star())
        .map((values) {
      var expr = values[0]; // Start with the first expression

      for (var pair in values[1]) {
        final op = pair[0]; // Logical operator (e.g., 'and', 'or')
        final right = pair[1]; // Right-hand expression
        expr = BinaryOperation(expr, op, right);
      }

      return expr;
    });
  }

  Parser unaryOperator() => (string('not').trim() | char('!').trim());

  Parser unaryOperation() => (ref0(unaryOperator) & ref0(expression))
      .map((values) => UnaryOperation(values[0], values[1]));
}
