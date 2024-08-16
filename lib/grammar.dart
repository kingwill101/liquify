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


Parser tag() =>
  (tagStart() & ref0(identifier).trim() & ref0(tagContent).trim() & ref0(filter).star() & tagEnd())
    .map((values) {
      return Tag(
        (values[1] as Identifier).name,
        values[2] as List<ASTNode>,
        filters: (values[3] as List).cast<Filter>()
      );
    });

Parser tagContent() =>
  (ref0(expression) | ref0(assignment) | ref0(literal) | ref0(identifier)).star()
    .map((result) => result.cast<ASTNode>());


  Parser tagArguments() => (ref0(commaSeparatedArguments) |
      ref0(spaceSeparatedArguments) |
      ref0(filteredArgument));

  Parser tagArgument() =>
      (ref0(expression) & ref0(filter).star()).map((values) {
        var expr = values[0] as Expression;
        var filters = (values[1] as List).cast<Filter>();
        return FilteredExpression(expr, filters);
      });

  Parser filteredArgument() =>
      (ref0(expression) & ref0(filter).star().optional()).map((values) {
        var expr = values[0] as Expression;
        var filters = (values[1] as List?)?.cast<Filter>() ?? [];
        return FilteredExpression(expr, filters);
      });

  Parser assignment() =>
      (ref0(identifier).trim() & char('=').trim() & ref0(literal).trim()).map(
          (values) =>
              Assignment((values[0] as Identifier).name, values[2] as Literal));

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

  Parser variableExpression() => ref0(filteredExpression) | ref0(expression);

  Parser filteredExpression() => (ref0(expression) & ref0(filter).plus()).map(
      (values) => FilteredExpression(
          values[0] as Expression, (values[1] as List).cast<Filter>()));

  Parser filter() => (char('|').trim() &
          ref0(identifier).trim() &
          ref0(filterArguments).optional())
      .map((values) =>
          Filter(values[1] as Identifier;
      final args = values[2] != null
          ? (values[2] as List)[1].elements.cast<ASTNode>()
          : <ASTNode>[];
      return Filter(filterName, args);
    });
  }

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

  Parser argument() => ref0(expression) | ref0(literal);

  Parser expression() => ref0(memberAccess) | ref0(identifier);

  Parser memberAccess() =>
      (ref0(identifier) & (char('.') & ref0(identifier)).plus()).map((values) {
        var object = values[0] as Identifier;
        var members =
            (values[1] as List).map((m) => (m[1] as Identifier).name).toList();
        return MemberAccess(object, members);
      });

  Parser identifier() =>
      (letter() & word().star()).flatten().map((name) => Identifier(name));

  Parser literal() => (char('"') & pattern('^"').star().flatten() & char('"'))
      .map((values) => Literal(values[1]));

  Parser text() => pattern('^{').plus().flatten().map((text) => TextNode(text));

  Parser commaSeparatedArguments() =>
      ref0(argument).plusSeparated(char(',').trim()).map((result) {
        return result.elements.cast<Identifier>();
      });

  Parser spaceSeparatedArguments() => ref0(argument).trim().plus();
}
