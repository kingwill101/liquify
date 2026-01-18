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
          (char(':').trim() & ref0(expression).plusSeparated(char(',').trim()))
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
              Assignment((values[0] as Identifier), values[2] as ASTNode),
              (values[3] as List).cast<Filter>(),
            ),
          );
        }
        return Assignment((values[0] as Identifier), values[2] as ASTNode);
      })
      .labeled('assignment');
}

Parser argument() {
  return (ref0(expression).trim())
      .plusSeparated(char(',').optional().trim())
      .map((result) {
        return result.elements;
      })
      .labeled('argument');
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
              Variable(name, expr),
              (values[2] as List).cast<Filter>(),
            );
          }

          return Variable(name, expr);
        })
        .labeled('variable');

Parser namedArgument() {
  return (ref0(identifier) & char(':').trim() & ref0(expression))
      .map((values) {
        return NamedArgument(values[0] as Identifier, values[2] as ASTNode);
      })
      .labeled('namedArgument');
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
      })
      .labeled('numericLiteral');
}

Parser<Literal> stringLiteral() {
  Parser<String> quotedString(String quote) {
    final backslash = String.fromCharCode(92);
    final bodyCharPattern = '^$quote$backslash';

    final escapeSequence = (char('\\') & any())
        .map((values) {
          final String character = values[1] as String;
          switch (character) {
            case 'n':
              return '\n';
            case 'r':
              return '\r';
            case 't':
              return '\t';
            case '"':
              return '"';
            case "'":
              return "'";
            case '\\':
              return '\\';
            default:
              // Unknown escape sequences keep the backslash and the character.
              return '\\$character';
          }
        })
        .labeled("quotedString");

    final bodyCharacter = pattern(bodyCharPattern);

    final content = (escapeSequence | bodyCharacter).star().map(
      (values) => values.join(),
    );

    return (char(quote) & content & char(quote)).map(
      (values) => values[1] as String,
    );
  }

  return (quotedString('"') | quotedString("'"))
      .map((value) => Literal(value, LiteralType.string))
      .labeled('stringLiteral');
}

Parser<Literal> booleanLiteral() {
  return (string('true') | string('false'))
      .map((value) {
        return Literal(value == 'true', LiteralType.boolean);
      })
      .labeled('booleanLiteral');
}

Parser<Literal> nilLiteral() {
  return (string('nil'))
      .map((value) {
        return Literal(null, LiteralType.nil);
      })
      .labeled('nilLiteral');
}

Parser emptyLiteral() {
  return (string('empty'))
      .map((value) {
        return Literal('empty', LiteralType.empty);
      })
      .labeled('emptyLiteral');
}

/// Expression parser with optimized ordering.
///
/// Parsers are ordered to ensure more specific patterns are tried before
/// general ones. For example, `arithmeticExpression` (which starts with a
/// literal/identifier but continues with an operator) must come before
/// standalone `literal` or `identifier`.
Parser expression() {
  return (
      // Complex expressions that START with simpler tokens must come first
      // Logical expressions (a and b, a or b) - contains comparisons
      ref0(logicalExpression) |
          // Comparisons (a == b, etc.) - starts with identifier/literal
          ref0(comparison) |
          // Arithmetic (1 + 2, "a" + "b") - starts with literal/identifier
          ref0(arithmeticExpression) |
          // Assignments (x = 5) - starts with identifier
          ref0(assignment) |
          // Member access (user.name) - starts with identifier
          ref0(memberAccess) |
          // Array access (items[0]) - starts with identifier
          ref0(arrayAccess) |
          // Unary operations (not x, !x)
          ref0(unaryOperation) |
          // Grouped expressions ((a + b))
          ref0(groupedExpression) |
          // Ranges ((1..5))
          ref0(range) |
          // Named arguments (key: value) - starts with identifier
          ref0(namedArgument) |
          // Simple terminals - must come last as they match parts of complex expressions
          ref0(literal) |
          ref0(identifier))
      .labeled('expression');
}

Parser memberAccess() =>
    (ref0(identifier) &
            (char('.') & (ref0(arrayAccess) | ref0(identifier))).plus())
        .map((values) {
          var object = values[0] as Identifier;

          var members = (values[1] as List)
              .map((m) => m[1] as ASTNode)
              .toList();

          return MemberAccess(object, members);
        })
        .labeled('memberAccess');

Parser arrayAccess() =>
    seq4(ref0(identifier), char('['), ref0(literal), char(']'))
        .map((array) {
          return ArrayAccess(array.$1, array.$3);
        })
        .labeled('arrayAccess');

Parser text() {
  return ((varStart() | tagStart()).neg() | any()).labeled('text block').map((
    text,
  ) {
    return TextNode(text);
  });
}

Parser comparisonOperator() =>
    (string('==').trim() |
            string('!=').trim() |
            string('<=').trim() |
            string('>=').trim() |
            char('<').trim() |
            char('>').trim() |
            (string('contains') & word().not()).pick(0).trim() |
            (string('in') & word().not()).pick(0).trim())
        .labeled('comparisonOperator');

Parser logicalOperator() =>
    ((string('and') & word().not()).pick(0).trim() |
            (string('or') & word().not()).pick(0).trim())
        .labeled('logicalOperator');

Parser comparison() {
  return (ref0(memberAccess) |
          ref0(literal) |
          ref0(identifier) |
          ref0(groupedExpression) |
          ref0(range))
      .seq(ref0(comparisonOperator))
      .seq(
        ref0(memberAccess) |
            ref0(literal) |
            ref0(identifier) |
            ref0(groupedExpression) |
            ref0(range),
      )
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
      })
      .labeled('logicalExpression');
}

Parser comparisonOrExpression() =>
    (ref0(groupedExpression) |
            ref0(comparison) |
            ref0(arithmeticExpression) |
            ref0(unaryOperation) |
            ref0(memberAccess) |
            ref0(literal) |
            ref0(identifier))
        .labeled('comparisonOrExpression');

Parser unaryOperator() =>
    ((string('not') & word().not()).pick(0).trim() | char('!').trim()).labeled(
      'unaryOperator',
    );

Parser unaryOperation() => (ref0(unaryOperator) & ref0(comparisonOrExpression))
    .map((values) => UnaryOperation(values[0], values[1]))
    .labeled('unaryOperation');

Parser range() {
  return (char('(').trim() &
          (ref0(memberAccess) | ref0(literal) | ref0(identifier)) &
          string('..') &
          (ref0(memberAccess) | ref0(literal) | ref0(identifier)) &
          char(')').trim())
      .map((values) {
        final start = values[1];
        final end = values[3];
        return BinaryOperation(start, '..', end);
      })
      .labeled('range');
}

Parser arithmeticExpression() {
  return (ref0(groupedExpression) |
          ref0(literal) |
          ref0(identifier) |
          ref0(range))
      .trim()
      .seq(
        char('+').trim() |
            char('-').trim() |
            char('*').trim() |
            char('/').trim(),
      )
      .seq(
        ref0(groupedExpression) |
            ref0(literal) |
            ref0(identifier) |
            ref0(range),
      )
      .trim()
      .map((values) {
        return BinaryOperation(values[0], values[1], values[2]);
      })
      .labeled('arithmeticExpression');
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
    char(')').trim(),
  ).map((values) => GroupedExpression(values.$2)).labeled('groupedExpression');
}

Parser<Tag> someTag(
  String name, {
  Parser<dynamic>? start,
  Parser<dynamic>? end,
  Parser<dynamic>? content,
  Parser<dynamic>? filters,
  bool hasContent = true,
}) {
  var parser = ((start ?? tagStart()) & string(name).trim());

  if (hasContent) {
    parser =
        parser &
        (content ?? ref0(tagContent).optional()).trim() &
        (filters ?? ref0(filter).star()).trim();
  }

  parser = parser & (end ?? tagEnd());

  return parser
      .map((values) {
        if (!hasContent) {
          return Tag(name, []);
        }
        final tagContent = values[2] is List<ASTNode>
            ? values[2] as List<ASTNode>
            : [];
        final tagFilters = values[3] is List
            ? (values[3] as List).cast<Filter>()
            : <Filter>[];
        return Tag(name, tagContent.cast(), filters: tagFilters);
      })
      .labeled('someTag');
}

Parser hashBlockComment() =>
    (tagStart() &
            pattern(' \t\n\r').star() &
            char('#') &
            any().starLazy(tagEnd()).flatten() &
            tagEnd())
        .map((values) {
          return TextNode('');
        })
        .labeled('hashBlockComment');

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
      })
      .labeled('tagContent');
}

Parser tag() =>
    (tagStart() &
            ref0(identifier).trim() &
            ref0(tagContent).optional().trim() &
            ref0(filter).star().trim() &
            tagEnd())
        .map((values) {
          final name = (values[1] as Identifier).name;
          final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
          final filters = (values[3] as List).cast<Filter>();
          final nonFilterContent = content
              .where((node) => node is! Filter)
              .toList();
          return Tag(name, nonFilterContent, filters: filters);
        })
        .labeled('tag');

Parser<Tag> breakTag() =>
    someTag('break', hasContent: false).labeled('breakTag');

Parser<Tag> continueTag() =>
    someTag('continue', hasContent: false).labeled('continueTag');

Parser<Tag> elseTag() => someTag('else', hasContent: false).labeled('elseTag');

Parser ifTag() => someTag("if").labeled('ifTag');

Parser elsifTag() => someTag("elsif").labeled('elsifTag');

Parser endIfTag() => (tagStart() & string('endif').trim() & tagEnd())
    .map((values) {
      return Tag('endif', []);
    })
    .labeled('endIfTag');

Parser forTag() => someTag('for').labeled('forTag');

Parser endForTag() => (tagStart() & string('endfor').trim() & tagEnd())
    .map((values) {
      return Tag('endfor', []);
    })
    .labeled('endForTag');

Parser forElseBranchContent() =>
    ref0(element).starLazy(ref0(endForTag)).labeled('forElseBranchContent');

Parser elseBlockForFor() => seq2(ref0(elseTag), ref0(forElseBranchContent))
    .map((values) {
      return (values.$1).copyWith(body: (values.$2 as List).cast<ASTNode>());
    })
    .labeled('elseBlockForFor');

Parser forBlock() =>
    seq4(
          ref0(forTag),
          ref0(element).starLazy(ref0(elseTag).or(ref0(endForTag))),
          ref0(elseBlockForFor).optional(),
          ref0(endForTag),
        )
        .map((values) {
          final forTag = values.$1 as Tag;
          final forBody = (values.$2).cast<ASTNode>();
          final elseBlockForFor = values.$3 as Tag?;

          final List<ASTNode> allBodyNodes = [...forBody];
          if (elseBlockForFor != null) {
            allBodyNodes.add(elseBlockForFor);
          }

          return forTag.copyWith(body: allBodyNodes);
        })
        .labeled('forBlock');

Parser<Tag> whenTag() => someTag('when').labeled('whenTag');

Parser<Tag> caseTag() => someTag('case').labeled('caseTag');

Parser endCaseTag() => (tagStart() & string('endcase').trim() & tagEnd())
    .map((values) {
      return Tag('endcase', []);
    })
    .labeled('endCaseTag');

Parser whenBlock() =>
    seq2(
          ref0(whenTag),
          ref0(
            element,
          ).starLazy(ref0(whenTag).or(ref0(elseTag)).or(ref0(endCaseTag))),
        )
        .map((values) {
          return (values.$1).copyWith(body: (values.$2).cast<ASTNode>());
        })
        .labeled('whenBlock');

Parser elseBlockForCase() =>
    seq2(ref0(elseTag), ref0(element).starLazy(ref0(endCaseTag)))
        .map((values) {
          return (values.$1).copyWith(body: (values.$2).cast<ASTNode>());
        })
        .labeled('elseBlockForCase');

Parser caseBlock() =>
    seq3(ref0(caseTag), ref0(element).starLazy(endCaseTag()), ref0(endCaseTag))
        .map((values) {
          return (values.$1).copyWith(body: (values.$2).cast<ASTNode>());
        })
        .labeled('caseBlock');

Parser ifBranchContent() => ref0(element)
    .starLazy(ref0(elsifTag).or(ref0(elseTag)).or(ref0(endIfTag)))
    .labeled('ifBranchContent');

Parser elsifBranchContent() => ref0(element)
    .starLazy(ref0(elsifTag).or(ref0(elseTag)).or(ref0(endIfTag)))
    .labeled('elsifBranchContent');

Parser elseBranchContent() =>
    ref0(element).starLazy(ref0(endIfTag)).labeled('elseBranchContent');

Parser ifBlock() =>
    seq5(
          ref0(ifTag),
          ref0(ifBranchContent),
          ref0(elseIfBlock).star(),
          ref0(elseBlock).optional(),
          ref0(endIfTag),
        )
        .map((values) {
          final ifTag = values.$1 as Tag;
          final ifBody = (values.$2 as List).cast<ASTNode>();
          final elsifBlocks = (values.$3).cast<Tag>();
          final elseBlock = values.$4 as Tag?;

          final List<ASTNode> allBodyNodes = [...ifBody];
          for (var block in elsifBlocks) {
            allBodyNodes.add(block);
          }
          if (elseBlock != null) {
            allBodyNodes.add(elseBlock);
          }

          return ifTag.copyWith(body: allBodyNodes);
        })
        .labeled('ifBlock');

Parser elseIfBlock() => seq2(ref0(elsifTag), ref0(elsifBranchContent))
    .map((values) {
      final elsifTag = values.$1 as Tag;
      final elsifBody = (values.$2 as List).cast<ASTNode>();
      return elsifTag.copyWith(body: elsifBody);
    })
    .labeled('elseIfBlock');

Parser elseBlock() => seq2(ref0(elseTag), ref0(elseBranchContent))
    .map((values) {
      final elseTag = values.$1;
      final elseBody = (values.$2 as List).cast<ASTNode>();
      return elseTag.copyWith(body: elseBody);
    })
    .labeled('elseBlock');

/// Optimized element parser using lookahead to avoid unnecessary backtracking.
///
/// Instead of trying all parsers in order, we first check the delimiter:
/// - `{{` -> variable-like parsers (including custom tags like super())
/// - `{%` -> tag/block parsers
/// - otherwise -> text
///
/// The lookahead includes whitespace-trimming variants ({%-, -%}, {{-, -}})
/// to properly handle Liquid's whitespace control syntax.
Parser element() {
  // Separate custom parsers by their delimiter type.
  // Custom parsers that use {{ }} syntax (like SuperTag) need to be in the
  // variable branch, while those using {% %} syntax go in the tag branch.
  final varCustomParsers = <Parser>[];
  final tagCustomParsers = <Parser>[];

  for (final customParser in TagRegistry.customParsers) {
    if (customParser.delimiterType == TagDelimiterType.variable) {
      varCustomParsers.add(customParser.parser());
    } else {
      tagCustomParsers.add(customParser.parser());
    }
  }

  // Variable-like elements (start with {{ or {{-)
  // Try custom parsers first (like {{ super() }}) then standard variable
  final variableElements = [
    ...varCustomParsers,
    ref0(variable),
  ].toChoiceParser();

  // Tag/block parsers (start with {% or {%-)
  final tagElements = [
    ref0(ifBlock),
    ref0(forBlock),
    ref0(caseBlock),
    ref0(whenBlock),
    ref0(elseBlockForCase),
    ref0(elseBlockForFor),
    ref0(hashBlockComment),
    ...tagCustomParsers,
    ref0(tag),
  ].toChoiceParser();

  // Text parser (anything not starting with {{ or {%)
  final textElement = ref0(text);

  // Lookahead parsers that account for whitespace-trimming syntax.
  // The trim variants ({%-, {{-) consume leading whitespace via .trim()
  final tagLookahead = (string('{%-').trim() | string('{%')).and();
  final varLookahead = (string('{{-').trim() | string('{{')).and();

  // Use lookahead to determine which parser to use
  // This avoids trying all block parsers when we're looking at plain text
  return (
      // If we see '{{' or '{{-', parse as variable-like element
      (varLookahead & variableElements).pick(1) |
          // If we see '{%' or '{%-', parse as tag/block
          (tagLookahead & tagElements).pick(1) |
          // Otherwise, parse as text
          textElement)
      .labeled('element');
}

Parser<Document> document() => ref0(element)
    .plus()
    .map((elements) {
      var collapsedElements = collapseTextNodes(elements.cast<ASTNode>());
      return Document(collapsedElements);
    })
    .labeled('document');

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
    this.message,
    this.source,
    this.line,
    this.column,
    this.offset,
  );

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
List<ASTNode> parseInput(
  String input, {
  bool enableTrace = false,
  bool shouldLint = false,
}) {
  //parser fails to handle empty input
  if (input.isEmpty) {
    return [];
  }

  final parser = _getCachedParser();

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
    result.message,
    input,
    lineCol[0],
    lineCol[0],
    result.position,
  );
}

Parser _getCachedParser() {
  registerBuiltIns();
  final signature = _parserSignature();
  if (_cachedParser == null || _cachedParserSignature != signature) {
    _cachedParser = LiquidGrammar().build();
    _cachedParserSignature = signature;
  }
  return _cachedParser!;
}

int _parserSignature() {
  final parsers = TagRegistry.customParsers;
  return Object.hashAll(parsers.map((parser) => parser.runtimeType));
}

Parser? _cachedParser;
int? _cachedParserSignature;
