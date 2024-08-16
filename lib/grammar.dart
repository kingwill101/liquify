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
              ref0(tagContent).optional().trim() &
              ref0(filter).star().trim() &
              tagEnd())
          .map((values) {
        final name = (values[1] as Identifier).name;
        final content = values[2] as List<ASTNode>? ?? [];
        final filters = (values[3] as List).cast<Filter>();
        final nonFilterContent =
            content.where((node) => node is! Filter).toList();
        return Tag(name, nonFilterContent, filters: filters);
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

  Parser filterArguments() => ref0(expression)
      .plusSeparated(char(',').trim())
      .map((values) => values.elements);

  Parser tagContent() {
    return (ref0(assignment) | ref0(argument) | ref0(expression))
        .star()
        .map((values) {
      var res = [];
      for (final entry in values) {
        if (entry is List) {
          res.addAll(entry);
        } else {
          res.add(entry);
        }
      }
      return res.cast<ASTNode>();
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
    return (ref0(expression).trim())
        .plusSeparated(char(',').optional().trim())
        .map((result) {
      return result.elements;
    });
  }

  Parser varStart() => string('{{-') | string('{{');
  Parser varEnd() => string('-}}') | string('}}');

  Parser variable() => (varStart().trim() &
              ref0(expression).trim() &
              filter().star().trim() &
              varEnd())
          .map((values) {
        Expression expr = values[1];
        String name = '';
        if (expr is Identifier) {
          name = expr.name;
        } else if (expr is MemberAccess) {
          name = (expr.object as Identifier).name;
        }

        if ((values[2] as List).isNotEmpty) {
          return FilteredExpression(
              Variable(name, expr), (values[2] as List).cast<Filter>());
        }

        return Variable(name, expr);
      });

  Parser namedArgument() {
    return (ref0(identifier) & char(':').trim() & ref0(expression))
        .map((values) {
      return NamedArgument(values[0] as Identifier, values[2] as Expression);
    });
  }

  Parser identifier() {
    return (letter() & word().star())
        .flatten()
        .where((name) => !['and', 'or', 'not', 'contains'].contains(name))
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

  Parser expression() {
    return ref0(logicalExpression)
        .or(ref0(comparison))
        .or(ref0(unaryOperation))
        .or(ref0(memberAccess))
        .or(ref0(assignment))
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
      char('>').trim() |
      string('contains').trim();

  Parser logicalOperator() => string('and').trim() | string('or').trim();

  Parser comparison() {
    return (ref0(memberAccess) | ref0(identifier) | ref0(literal))
        .seq(ref0(comparisonOperator))
        .seq(ref0(memberAccess) | ref0(identifier) | ref0(literal))
        .map((values) => BinaryOperation(values[0], values[1], values[2]));
  }

  Parser logicalExpression() {
    return ref0(comparisonOrExpression)
        .seq(ref0(logicalOperator).seq(ref0(comparisonOrExpression)).star())
        .map((values) {
      var expr = values[0];
      for (var pair in values[1]) {
        final op = pair[0];
        final right = pair[1];
        expr = BinaryOperation(expr, op, right);
      }
      return expr;
    });
  }

  Parser comparisonOrExpression() =>
      ref0(comparison) |
      ref0(unaryOperation) |
      ref0(memberAccess) |
      ref0(literal) |
      ref0(identifier);

  Parser unaryOperator() => (string('not').trim() | char('!').trim());

  Parser unaryOperation() =>
      (ref0(unaryOperator) & ref0(comparisonOrExpression))
          .map((values) => UnaryOperation(values[0], values[1]));
}
