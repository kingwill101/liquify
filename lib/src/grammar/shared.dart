import 'package:liquify/parser.dart';
import 'package:liquify/src/grammar/grammar.dart';
import 'package:liquify/src/registry.dart';
import 'package:petitparser/debug.dart';
import 'package:petitparser/reflection.dart';

export 'package:liquify/src/ast.dart';
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

Parser tagStart() => (string('{%-').trim() | string('{%')).labeled('tagStart');

Parser tagEnd() => (string('-%}').trim() | string('%}')).labeled('tagEnd');

Parser filter() {
  return (char('|').trim() &
          ref0(identifier).trim() &
          (char(':').trim() &
                  (ref0(namedArgument) | ref0(literal) | ref0(identifier))
                      .plusSeparated(char(',').trim()))
              .optional())
      .labeled('filter')
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
    .map((values) => values.elements)
    .labeled('filterArguments');

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
  }).labeled('assignment');
}

Parser argument() {
  return (ref0(expression).trim())
      .plusSeparated(char(',').optional().trim())
      .map((result) {
    return result.elements;
  }).labeled('argument');
}

Parser varStart() => (string('{{-').trim() | string('{{')).labeled('varStart');

Parser varEnd() => (string('-}}').trim() | string('}}')).labeled('varEnd');

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
    }).labeled('variable');

Parser namedArgument() {
  return (ref0(identifier) & char(':').trim() & ref0(expression)).map((values) {
    return NamedArgument(values[0] as Identifier, values[2] as ASTNode);
  }).labeled('namedArgument');
}

Parser identifier() {
  return (letter() & (word() | char('-')).star())
      .flatten()
      .where((name) => !['and', 'or', 'not', 'contains'].contains(name))
      .map((name) => Identifier(name))
      .labeled('identifier');
}

Parser literal() {
  return (ref0(nilLiteral) |
          ref0(booleanLiteral) |
          ref0(numericLiteral) |
          ref0(emptyLiteral) |
          ref0(stringLiteral))
      .labeled('literal');
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
  }).labeled('numericLiteral');
}

Parser<Literal> stringLiteral() {
  return (char('"') & pattern('^"').starString() & char('"') |
          char("'") & pattern("^'").starString() & char("'"))
      .map((values) {
    return Literal(values[1], LiteralType.string);
  }).labeled('stringLiteral');
}

Parser<Literal> booleanLiteral() {
  return (string('true') | string('false')).map((value) {
    return Literal(value == 'true', LiteralType.boolean);
  }).labeled('booleanLiteral');
}

Parser<Literal> nilLiteral() {
  return (string('nil')).map((value) {
    return Literal(null, LiteralType.nil);
  }).labeled('nilLiteral');
}

Parser emptyLiteral() {
  return (string('empty')).map((value) {
    return Literal('empty', LiteralType.empty);
  }).labeled('emptyLiteral');
}

Parser expression() {
  return (ref0(logicalExpression)
          .or(ref0(comparison))
          .or(ref0(groupedExpression))
          .or(ref0(arithmeticExpression))
          .or(ref0(unaryOperation))
          .or(ref0(arrayAccess))
          .or(ref0(memberAccess))
          .or(ref0(assignment))
          .or(ref0(namedArgument))
          .or(ref0(literal))
          .or(ref0(identifier))
          .or(ref0(range)))
      .labeled('expression');
}

Parser memberAccess() => (ref0(identifier) &
            (char('.') & (ref0(arrayAccess) | ref0(identifier))).plus())
        .map((values) {
      var object = values[0] as Identifier;

      var members = (values[1] as List).map((m) => m[1] as ASTNode).toList();

      return MemberAccess(object, members);
    }).labeled('memberAccess');

Parser arrayAccess() =>
    seq4(ref0(identifier), char('['), ref0(literal), char(']')).map((array) {
      return ArrayAccess(array.$1, array.$3);
    });

Parser text() {
  return ((varStart() | tagStart()).neg() | any())
      .labeled('text block')
      .map((text) {
    return TextNode(text);
  });
}

Parser comparisonOperator() => (string('==').trim() |
        string('!=').trim() |
        string('<=').trim() |
        string('>=').trim() |
        char('<').trim() |
        char('>').trim() |
        string('contains').trim() |
        string('in').trim())
    .labeled('comparisonOperator');

Parser logicalOperator() =>
    (string('and').trim() | string('or').trim()).labeled('logicalOperator');

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
      .map((values) => BinaryOperation(values[0], values[1], values[2]))
      .labeled('comparison');
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
  }).labeled('logicalExpression');
}

Parser comparisonOrExpression() => (ref0(groupedExpression) |
        ref0(comparison) |
        ref0(arithmeticExpression) |
        ref0(unaryOperation) |
        ref0(memberAccess) |
        ref0(literal) |
        ref0(identifier))
    .labeled('comparisonOrExpression');

Parser unaryOperator() =>
    (string('not').trim() | char('!').trim()).labeled('unaryOperator');

Parser unaryOperation() => (ref0(unaryOperator) & ref0(comparisonOrExpression))
    .map((values) => UnaryOperation(values[0], values[1]))
    .labeled('unaryOperation');

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
  }).labeled('range');
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
  }).labeled('arithmeticExpression');
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
      .map((values) => GroupedExpression(values.$2))
      .labeled('groupedExpression');
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
  }).labeled('someTag');
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
  }).labeled('tagContent');
}

Parser tag() => (tagStart() &
            ref0(identifier).trim() &
            ref0(tagContent).optional().trim() &
            ref0(filter).star().trim() &
            tagEnd())
        .map((values) {
      final name = (values[1] as Identifier).name;
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(name, nonFilterContent, filters: filters);
    }).labeled('tag');

Parser<Tag> breakTag() =>
    someTag('break', hasContent: false).labeled('breakTag');

Parser<Tag> continueTag() =>
    someTag('continue', hasContent: false).labeled('continueTag');

Parser<Tag> elseTag() => someTag('else', hasContent: false).labeled('elseTag');

Parser elseBlock() => seq2(
      ref0(elseTag),
      ref0(element)
          .starLazy(ref0(endCaseTag).or(ref0(endIfTag)).or(ref0(endForTag))),
    ).map((values) {
      return values.$1.copyWith(body: values.$2.cast<ASTNode>());
    });
Parser ifTag() => someTag("if");
Parser ifBlock() => seq3(
      ref0(ifTag),
      ref0(element).starLazy(endIfTag()),
      ref0(endIfTag),
    ).map((values) {
      return values.$1.copyWith(body: values.$2.cast<ASTNode>());
    });

Parser elseIfBlock() =>
    seq2(ref0(elseifTag), ref0(element).starLazy((elseTag()).or(elseifTag())))
        .map((values) {
      return values.$1.copyWith(body: values.$2.cast<ASTNode>());
    });

Parser elseifTag() => someTag("elseif");

Parser endIfTag() =>
    (tagStart() & string('endif').trim() & tagEnd()).map((values) {
      return Tag('endif', []);
    });

Parser forBlock() => seq3(
      ref0(forTag),
      ref0(element).starLazy(endForTag()),
      ref0(endForTag),
    ).labeled('for block').map((values) {
      return values.$1.copyWith(body: values.$2.cast<ASTNode>());
    });

Parser<Tag> forTag() => someTag('for');

Parser endForTag() =>
    (tagStart() & string('endfor').trim() & tagEnd()).map((values) {
      return Tag('endfor', []);
    });

Parser caseBlock() => seq3(
      ref0(caseTag),
      ref0(element).plusLazy(endCaseTag()),
      ref0(endCaseTag),
    ).map((values) {
      return values.$1.copyWith(body: values.$2.cast<ASTNode>());
    });

Parser<Tag> whenTag() => someTag('when');

Parser<Tag> caseTag() => someTag('case');

Parser endCaseTag() =>
    (tagStart() & string('endcase').trim() & tagEnd()).map((values) {
      return Tag('endcase', []);
    });

Parser whenBlock() => seq2(
      ref0(whenTag),
      ref0(element).starLazy(ref0(endCaseTag).or(ref0(elseTag).or(whenTag()))),
    ).map((values) {
      return values.$1.copyWith(body: values.$2.cast<ASTNode>());
    });

Parser element() => [
      ref0(ifBlock),
      ref0(elseIfBlock),
      ref0(forBlock),
      ref0(caseBlock),
      ref0(elseBlock),
      ref0(whenBlock),
      ref0(breakTag),
      ref0(continueTag),
      ...TagRegistry.customParsers.map((p) => p.parser()),
      ref0(tag),
      ref0(variable),
      ref0(text)
    ].toChoiceParser();

Parser<Document> document() => ref0(element).plus().map((elements) {
      var collapsedElements = collapseTextNodes(elements.cast<ASTNode>());
      return Document(collapsedElements);
    });

/// Represents an exception that occurred during parsing.
///
/// This exception is thrown when the parser encounters an error while parsing the input.
/// It contains information about the error, including the error message, the source code,
/// the line and column where the error occurred, and the offset of the error in the source code.
class ParsingException implements Exception {
  final String message;
  final String source;
  final int line;
  final int column;
  final int offset;

  ParsingException(
      this.message, this.source, this.line, this.column, this.offset);

  @override
  String toString() {
    final lines = source.split('\n');
    final errorLine = lines[line - 1];
    final pointer = '${' ' * (column - 1)}^';
    return 'ParsingException: $message @ line $line:$column\nsource: \n$errorLine\n$pointer';
  }
}

/// Parses the given input string and returns a list of [ASTNode] objects representing the parsed document.
///
/// If [enableTrace] is true, the parser will output trace information during parsing.
/// If [shouldLint] is true, the parser will output lint information for the parsed grammar.
///
/// If the parsing is successful, the method returns the list of [ASTNode] objects representing the document.
/// If the parsing fails, the method prints the error message and the input source, and returns an empty list.
List<ASTNode> parseInput(String input,
    {bool enableTrace = false, bool shouldLint = false}) {
  //parser fails to handle empty input
  if (input.isEmpty) {
    return [];
  }

  registerBuiltIns();
  final parser = LiquidGrammar().build();

  if (shouldLint) {
    print(linter(parser).join('\n\n'));
  }
  Result result;

  if (enableTrace) {
    result = trace(parser).parse(input);
  } else {
    result = parser.parse(input);
  }

  if (result is Success) {
    return (result.value as Document).children;
  }
  final lineCol = Token.lineAndColumnOf(input, result.position);

  throw ParsingException(
      result.message, input, lineCol[0], lineCol[0], result.position);
}
