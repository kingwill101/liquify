import 'package:liquify/src/ast.dart';
export 'package:liquify/src/ast.dart';
import 'package:liquify/src/grammar/grammar.dart';
import 'package:liquify/src/registry.dart';
import 'package:petitparser/petitparser.dart';
export 'package:petitparser/petitparser.dart';

List<ASTNode> collapseTextNodes(List<ASTNode> elements) {
  List<ASTNode> result = [];
  TextNode? currentTextNode;

  for (var node in elements) {
    if (node is TextNode) {
      if (currentTextNode == null) {
        currentTextNode = node;
      } else {
        currentTextNode = TextNode(currentTextNode.text + node.text);
      }
    } else {
      if (currentTextNode != null) {
        // Add the combined TextNode to the result
        result.add(currentTextNode);
        currentTextNode = null;
      }
      result.add(node);
    }
  }

  if (currentTextNode != null) {
    result.add(currentTextNode);
  }

  return result;
}

Parser tagEnd() => string('-%}') | string('%}');

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

Parser assignment() {
  return (ref0(identifier).trim() &
          char('=').trim() &
          ref0(expression).trim() &
          filter().star().trim())
      .map((values) {
    if ((values[3] as List).isNotEmpty) {
      return Assignment(
        (values[0] as Identifier),
        FilteredExpression(
            Assignment(
              (values[0] as Identifier),
              values[2] as ASTNode,
            ),
            (values[3] as List).cast<Filter>()),
      );
    }
    return Assignment(
      (values[0] as Identifier),
      values[2] as ASTNode,
    );
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

Parser variable() =>
    (varStart() & ref0(expression).trim() & filter().star().trim() & varEnd())
        .map((values) {
      ASTNode expr = values[1];
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
  return (ref0(identifier) & char(':').trim() & ref0(expression)).map((values) {
    return NamedArgument(values[0] as Identifier, values[2] as ASTNode);
  });
}

Parser identifier() {
  return (letter() & (word() | char('-')).star())
      .flatten()
      .where((name) => !['and', 'or', 'not', 'contains'].contains(name))
      .map((name) => Identifier(name));
}

Parser literal() {
  return ref0(nilLiteral) |
      ref0(booleanLiteral) |
      ref0(numericLiteral) |
      ref0(emptyLiteral) |
      ref0(stringLiteral);
}

Parser numericLiteral() {
  return (char('-').optional() &
          (digit().plus() & (char('.') & digit().plus()).optional()))
      .flatten()
      .map((value) {
    if (value.contains('.')) {
      return Literal(double.parse(value), LiteralType.number);
    } else {
      return Literal(int.parse(value), LiteralType.number);
    }
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

Parser nilLiteral() {
  return (string('nil')).map((value) {
    return Literal(null, LiteralType.nil);
  });
}

Parser emptyLiteral() {
  return (string('empty')).map((value) {
    return Literal('empty', LiteralType.empty);
  });
}

Parser expression() {
  return ref0(logicalExpression)
      .or(ref0(comparison))
      .or(ref0(groupedExpression))
      .or(ref0(arithmeticExpression))
      .or(ref0(unaryOperation))
      .or(ref0(memberAccess))
      .or(ref0(assignment))
      .or(ref0(namedArgument))
      .or(ref0(literal))
      .or(ref0(identifier))
      .or(ref0(range));
}

Parser memberAccess() =>
    (ref0(identifier) & (char('.') & ref0(identifier)).plus()).map((values) {
      var object = values[0] as Identifier;
      var members =
          (values[1] as List).map((m) => (m[1] as Identifier).name).toList();
      return MemberAccess(object, members);
    });

Parser text() {
  return ((varStart() | tagStart()).neg() | any())
      .labeled('text block')
      .map((text) {
    return TextNode(text);
  });
}

Parser comparisonOperator() =>
    string('==').trim() |
    string('!=').trim() |
    string('<=').trim() |
    string('>=').trim() |
    char('<').trim() |
    char('>').trim() |
    string('contains').trim() |
    string('in').trim();

Parser logicalOperator() => string('and').trim() | string('or').trim();

Parser comparison() {
  return (ref0(memberAccess) |
          ref0(identifier) |
          ref0(literal) |
          ref0(groupedExpression) |
          ref0(range))
      .seq(ref0(comparisonOperator))
      .seq(ref0(memberAccess) |
          ref0(identifier) |
          ref0(literal) |
          ref0(groupedExpression) |
          ref0(range))
      .map((values) => BinaryOperation(values[0], values[1], values[2]));
}

Parser logicalExpression() {
  return ref0(comparisonOrExpression)
      .seq(ref0(logicalOperator).seq(ref0(comparisonOrExpression)).plus())
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
    ref0(groupedExpression) |
    ref0(comparison) |
    ref0(arithmeticExpression) |
    ref0(unaryOperation) |
    ref0(memberAccess) |
    ref0(literal) |
    ref0(identifier);

Parser unaryOperator() => (string('not').trim() | char('!').trim());

Parser unaryOperation() => (ref0(unaryOperator) & ref0(comparisonOrExpression))
    .map((values) => UnaryOperation(values[0], values[1]));

Parser range() {
  return (char('(').trim() &
          (ref0(memberAccess) | ref0(identifier) | ref0(literal)) &
          string('..') &
          (ref0(memberAccess) | ref0(identifier) | ref0(literal)) &
          char(')').trim())
      .map((values) {
    final start = values[1];
    final end = values[3];
    return BinaryOperation(start, '..', end);
  });
}

Parser arithmeticExpression() {
  return (ref0(groupedExpression) |
          ref0(identifier) |
          ref0(literal) |
          ref0(range))
      .trim()
      .seq(char('+').trim() |
          char('-').trim() |
          char('*').trim() |
          char('/').trim())
      .seq(ref0(groupedExpression) |
          ref0(identifier) |
          ref0(literal) |
          ref0(range))
      .trim()
      .map((values) {
    return BinaryOperation(values[0], values[1], values[2]);
  });
}

Parser groupedExpression() {
  return seq3(
          char('(').trim(),
          (ref0(arithmeticExpression) |
                  ref0(memberAccess) |
                  ref0(unaryOperation) |
                  ref0(literal) |
                  ref0(comparison) |
                  ref0(logicalExpression) |
                  ref0(expression))
              .trim(),
          char(')').trim())
      .map((values) => GroupedExpression(values.$2));
}

Parser<Tag> someTag(String name,
    {Parser<dynamic>? start,
    Parser<dynamic>? end,
    Parser<dynamic>? content,
    Parser<dynamic>? filters,
    bool hasContent = true}) {
  var parser = ((start ?? tagStart()) & string(name).trim());

  if (hasContent) {
    parser = parser &
        (content ?? ref0(tagContent).optional()).trim() &
        (filters ?? ref0(filter).star()).trim();
  }

  parser = parser & (end ?? tagEnd());

  return parser.map((values) {
    if (!hasContent) {
      return Tag(name, []);
    }
    final tagContent =
        values[2] is List<ASTNode> ? values[2] as List<ASTNode> : [];
    final tagFilters =
        values[3] is List ? (values[3] as List).cast<Filter>() : <Filter>[];
    return Tag(name, tagContent.cast(), filters: tagFilters);
  });
}

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

Parser<Tag> breakTag() => someTag('break', hasContent: false);

Parser<Tag> continueTag() => someTag('continue', hasContent: false);

Parser<Tag> elseTag() => someTag('else', hasContent: false);

List<ASTNode> parseInput(String input) {
  registerBuiltIns();
  final result = LiquidGrammar().build().parse(input);

  if (result is Success) {
    return (result.value as Document).children;
  } else {
    print("parseInput: ${result.message} @ ${result.toPositionString()}");
    print("source: \n$input");
  }
  return [];
}
