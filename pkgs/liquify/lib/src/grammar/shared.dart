import 'package:liquify/parser.dart';
import 'package:liquify/src/grammar/grammar.dart';
import 'package:liquify/src/registry.dart';
import 'package:petitparser/debug.dart';
import 'package:petitparser/reflection.dart';

export 'package:liquify/src/ast.dart';
export 'package:liquify/src/config.dart';
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

// ---------------------------------------------------------------------------
// Configurable delimiter factory functions
// ---------------------------------------------------------------------------
// These functions create parsers with custom delimiters. Use them when building
// custom tags that need to work with non-standard delimiters.
//
// ## Usage
//
// For most custom tags, use [someTag] with the `config` parameter:
//
// ```dart
// final config = LiquidConfig(tagStart: '[%', tagEnd: '%]');
// final myTag = someTag('mytag', config: config);
// ```
//
// For low-level parser building, use the factory functions directly:
//
// ```dart
// final start = createTagStart(config);
// final end = createTagEnd(config);
// final varStart = createVarStart(config);
// final varEnd = createVarEnd(config);
// ```

/// Creates a tag start delimiter parser with optional custom config.
///
/// Returns a parser that matches the tag start delimiter (e.g., `{%` or `{%-`).
/// The whitespace-stripping variant (e.g., `{%-`) strips preceding whitespace.
///
/// If [config] is null, uses standard Liquid delimiters.
///
/// ## Example
///
/// ```dart
/// // Standard delimiters
/// final tagStart = createTagStart();
/// // Matches: {% or {%-
///
/// // Custom delimiters
/// final config = LiquidConfig(tagStart: '[%', tagEnd: '%]');
/// final myTagStart = createTagStart(config);
/// // Matches: [% or [%-
/// ```
///
/// See also:
/// - [someTag] for creating complete tag parsers (recommended)
/// - [createTagEnd] for the corresponding end delimiter
Parser createTagStart([LiquidConfig? config]) {
  final cfg = config ?? LiquidConfig.standard;
  return (string(cfg.tagStartStrip).trim() | string(cfg.tagStart)).labeled(
    'tagStart',
  );
}

/// Creates a tag end delimiter parser with optional custom config.
///
/// Returns a parser that matches the tag end delimiter (e.g., `%}` or `-%}`).
/// The whitespace-stripping variant (e.g., `-%}`) strips following whitespace.
///
/// If [config] is null, uses standard Liquid delimiters.
///
/// ## Example
///
/// ```dart
/// final config = LiquidConfig(tagStart: '[%', tagEnd: '%]');
/// final myTagEnd = createTagEnd(config);
/// // Matches: %] or -%]
/// ```
Parser createTagEnd([LiquidConfig? config]) {
  final cfg = config ?? LiquidConfig.standard;
  return (string(cfg.tagEndStrip).trim() | string(cfg.tagEnd)).labeled(
    'tagEnd',
  );
}

/// Creates a variable start delimiter parser with optional custom config.
///
/// Returns a parser that matches the variable start delimiter (e.g., `{{` or `{{-`).
/// The whitespace-stripping variant (e.g., `{{-`) strips preceding whitespace.
///
/// If [config] is null, uses standard Liquid delimiters.
///
/// ## Example
///
/// ```dart
/// final config = LiquidConfig(varStart: '[[', varEnd: ']]');
/// final myVarStart = createVarStart(config);
/// // Matches: [[ or [[-
/// ```
Parser createVarStart([LiquidConfig? config]) {
  final cfg = config ?? LiquidConfig.standard;
  return (string(cfg.varStartStrip).trim() | string(cfg.varStart)).labeled(
    'varStart',
  );
}

/// Creates a variable end delimiter parser with optional custom config.
///
/// Returns a parser that matches the variable end delimiter (e.g., `}}` or `-}}`).
/// The whitespace-stripping variant (e.g., `-}}`) strips following whitespace.
///
/// If [config] is null, uses standard Liquid delimiters.
///
/// ## Example
///
/// ```dart
/// final config = LiquidConfig(varStart: '[[', varEnd: ']]');
/// final myVarEnd = createVarEnd(config);
/// // Matches: ]] or -]]
/// ```
Parser createVarEnd([LiquidConfig? config]) {
  final cfg = config ?? LiquidConfig.standard;
  return (string(cfg.varEndStrip).trim() | string(cfg.varEnd)).labeled(
    'varEnd',
  );
}

// ---------------------------------------------------------------------------
// Default delimiter parsers (backward compatible)
// ---------------------------------------------------------------------------

/// Tag start delimiter.
/// The {%- variant strips preceding whitespace (via .trim()).
///
/// If [config] is provided, uses custom delimiters from the config.
Parser tagStart([LiquidConfig? config]) => createTagStart(config);

/// Tag end delimiter.
/// The -%} variant strips following whitespace (via .trim()).
///
/// If [config] is provided, uses custom delimiters from the config.
Parser tagEnd([LiquidConfig? config]) => createTagEnd(config);

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

/// @Deprecated: This parser is no longer used. Assignment is now handled
/// by the expression() parser through _assignmentExpr().
/// Kept for backwards compatibility.
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

/// Variable start delimiter. The whitespace-stripping variant {{- is handled
/// semantically at evaluation time, not by the parser consuming whitespace.
///
/// If [config] is provided, uses custom delimiters from the config.
Parser varStart([LiquidConfig? config]) => createVarStart(config);

/// Variable end delimiter. The whitespace-stripping variant -}} is handled
/// semantically at evaluation time, not by the parser consuming whitespace.
///
/// If [config] is provided, uses custom delimiters from the config.
Parser varEnd([LiquidConfig? config]) => createVarEnd(config);

/// Variable parser - parses `{{ expression | filter }}` syntax.
///
/// If [config] is provided, uses custom delimiters from the config.
Parser variable([LiquidConfig? config]) =>
    (varStart(config) &
            ref0(expression).trim() &
            filter().star().trim() &
            varEnd(config))
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

/// @Deprecated: These old parsers are no longer used by expression().
/// The new expression() uses a precedence-based approach via _logicalExpr,
/// _comparisonExpr, _arithmeticExpr, and primaryTerm.
/// Kept for backwards compatibility and testing.

/// Identifier parser - matches variable names, function names, etc.
///
/// Identifiers must start with a letter and can contain letters, digits,
/// underscores, and hyphens. Reserved words (and, or, not, contains) are excluded.
///
/// Optimized to use pattern() instead of word() | char('-') for better performance.
/// Pattern matching is more efficient than choice parsers for character classes.
Parser identifier() {
  // Use pattern for efficient character class matching
  // First char: letter only
  // Rest: letters, digits, underscore, or hyphen
  return (pattern('a-zA-Z') & pattern('a-zA-Z0-9_-').star())
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

/// Arithmetic operator parser.
/// Note: .trim() removed from individual operators since primaryTerm().trim()
/// handles surrounding whitespace in arithmeticExpr().
Parser arithmeticOperator() => (char('+') | char('-') | char('*') | char('/'))
    .labeled('arithmeticOperator');

/// Primary term parser - parses the basic building blocks of expressions.
///
/// This includes:
/// - Grouped expressions: (a + b)
/// - Ranges: (1..5)
/// - Unary operations: not x, !x
/// - Member access: user.name
/// - Array access: items[0]
/// - Literals: 1, "hello", true
/// - Identifiers: user
///
/// Optimized with first-character routing to skip impossible alternatives:
/// - Letter-starting inputs skip paren checks, route to identifier-like parsers
/// - Quote-starting inputs skip to string literal directly
/// - Digit/minus inputs skip to numeric literal directly
/// - Paren/bang inputs route to their specific parsers
///
/// This provides ~15% reduction in parser activations for typical inputs.
Parser primaryTerm() {
  // Letter-starting inputs: identifiers, keywords, 'not' operator
  // Skip paren checks since letters can't start grouped expressions
  final letterCases =
      pattern('a-zA-Z').and() &
      (ref0(unaryOperation) | // 'not x'
          ref0(memberAccess) | // x, x.y (has fast path for simple identifiers)
          ref0(arrayAccess) | // x[0]
          ref0(literal) | // true, false, nil, empty
          ref0(identifier)); // fallback

  // '!' -> unary not operation
  final bangCase = char('!').and() & ref0(unaryOperation);

  // Quote-starting -> string literal (skip 5 alternatives)
  final stringCase = (char('"') | char("'")).and() & ref0(stringLiteral);

  // Digit or minus -> numeric literal (skip 5 alternatives)
  final numericCase = (digit() | char('-')).and() & ref0(numericLiteral);

  // Paren -> grouped expression or range
  final parenCase = char('(').and() & (ref0(groupedExpression) | ref0(range));

  return (letterCases.pick(1) | // Most common: identifiers
          bangCase.pick(1) | // Unary bang
          stringCase.pick(1) | // String literals
          numericCase.pick(1) | // Numeric literals
          parenCase.pick(1)) // Grouped/range (less common)
      .labeled('primaryTerm');
}

/// Optimized expression parser with proper precedence handling.
///
/// Precedence (lowest to highest):
/// 1. Named argument / Assignment (handled specially)
/// 2. Logical operators (and, or)
/// 3. Comparison operators (==, !=, <, >, <=, >=, contains, in)
/// 4. Arithmetic operators (+, -, *, /)
/// 5. Primary terms (identifiers, literals, etc.)
///
/// This avoids the repeated prefix parsing problem by parsing each
/// precedence level once and reusing results.
Parser expression() {
  return ref0(expressionWithAssignment).labeled('expression');
}

/// Top-level expression handling assignment and named arguments.
/// These are special because they require an identifier on the left.
///
/// Optimized with cheap pattern-based lookahead:
/// - Uses pattern matching instead of full identifier parsing in lookahead
/// - Only parses identifier once when actually needed
/// - Pattern: [a-zA-Z][a-zA-Z0-9_-]* followed by whitespace* and = or :
Parser expressionWithAssignment() {
  // Cheap pattern-based lookahead using character patterns instead of full identifier parsing
  // This avoids parsing the identifier 3 times (once per lookahead + once for actual parse)
  final identPattern = pattern('a-zA-Z') & pattern('a-zA-Z0-9_-').star();

  // Check for = after identifier pattern (doesn't consume, just peeks)
  final assignmentLookahead = (identPattern & whitespace().star() & char('='))
      .and();

  // Check for : after identifier pattern (doesn't consume, just peeks)
  final namedArgLookahead = (identPattern & whitespace().star() & char(':'))
      .and();

  return (
      // Only try assignment if lookahead matches
      (assignmentLookahead & ref0(assignmentExpr)).pick(1) |
          // Only try named arg if lookahead matches
          (namedArgLookahead & ref0(namedArgExpr)).pick(1) |
          // Otherwise, parse as logical expression
          ref0(logicalExpr))
      .labeled('expressionWithAssignment');
}

/// Assignment expression: identifier = expression
Parser assignmentExpr() {
  return (ref0(identifier) &
          char('=').trim() &
          ref0(logicalExpr).trim() &
          filter().star().trim())
      .map((values) {
        final ident = values[0] as Identifier;
        final rightExpr = values[2] as ASTNode;
        final filters = values[3] as List;
        if (filters.isNotEmpty) {
          return Assignment(
            ident,
            FilteredExpression(
              Assignment(ident, rightExpr),
              filters.cast<Filter>(),
            ),
          );
        }
        return Assignment(ident, rightExpr);
      })
      .labeled('assignmentExpr');
}

/// Named argument expression: identifier: expression
Parser namedArgExpr() {
  return (ref0(identifier) & char(':').trim() & ref0(logicalExpr))
      .map((values) {
        return NamedArgument(values[0] as Identifier, values[2] as ASTNode);
      })
      .labeled('namedArgExpr');
}

/// Logical expression: comparison (and|or comparison)*
/// Lowest precedence binary operator.
Parser logicalExpr() {
  return (ref0(comparisonExpr) &
          (ref0(logicalOperator) & ref0(comparisonExpr)).star())
      .map((values) {
        var left = values[0];
        final pairs = values[1] as List;
        for (final pair in pairs) {
          final op = pair[0];
          final right = pair[1];
          left = BinaryOperation(left, op, right);
        }
        return left;
      })
      .labeled('logicalExpr');
}

/// Comparison expression: arithmetic (comparisonOp arithmetic)?
/// Note: Single comparison only (no chaining like a == b == c)
Parser comparisonExpr() {
  return (ref0(arithmeticExpr) &
          (ref0(comparisonOperator) & ref0(arithmeticExpr)).optional())
      .map((values) {
        final left = values[0];
        final opAndRight = values[1];
        if (opAndRight == null) {
          return left;
        }
        final op = opAndRight[0];
        final right = opAndRight[1];
        return BinaryOperation(left, op, right);
      })
      .labeled('comparisonExpr');
}

/// Arithmetic expression: term (arithmeticOp term)?
/// Note: Single operation only for now (no chaining like a + b + c)
Parser arithmeticExpr() {
  return (ref0(primaryTerm).trim() &
          (ref0(arithmeticOperator) & ref0(primaryTerm).trim()).optional())
      .map((values) {
        final left = values[0];
        final opAndRight = values[1];
        if (opAndRight == null) {
          return left;
        }
        final op = opAndRight[0];
        final right = opAndRight[1];
        return BinaryOperation(left, op, right);
      })
      .labeled('arithmeticExpr');
}

/// Member access parser - handles dot notation like `product.name.first`.
///
/// Optimized with a two-tier approach:
/// 1. Fast path: Pattern-based parsing for simple identifier chains (no array access)
///    Uses a single pattern match + string split instead of parsing each identifier
/// 2. Slow path: Original recursive parsing for complex cases with array access
///
/// The fast path provides ~50% reduction in parser activations for simple cases.
Parser memberAccess() {
  // Fast path: Simple identifier chain without array access
  // Pattern matches: identifier(.identifier)+ where no segment is followed by '['
  final identChar = pattern('a-zA-Z0-9_-');
  final dot = char('.');

  // First segment: identifier pattern
  final firstIdent = pattern('a-zA-Z') & identChar.star();

  // Additional segments: .identifier (NOT followed by '[')
  final additionalSegment = dot & pattern('a-zA-Z') & identChar.star();

  // Fast path parser - matches simple chains and ensures not followed by '['
  // The negative lookahead char('[').not() ensures we don't match when array access follows
  final simpleMemberAccess =
      ((firstIdent & additionalSegment.plus()).flatten() & char('[').not())
          .pick(0) // Get just the flattened string, not the lookahead result
          .cast<String>()
          .where((value) {
            // Exclude reserved words in any segment
            final parts = value.split('.');
            return !parts.any(
              (p) => ['and', 'or', 'not', 'contains'].contains(p),
            );
          })
          .map((value) {
            final parts = value.split('.');
            final object = Identifier(parts.first);
            final members = parts
                .skip(1)
                .map((name) => Identifier(name))
                .toList();
            return MemberAccess(object, members.cast<ASTNode>());
          });

  // Slow path: Original recursive parsing for complex cases (with array access)
  final complexMemberAccess =
      (ref0(identifier) &
              (char('.') & (ref0(arrayAccess) | ref0(identifier))).plus())
          .map((values) {
            var object = values[0] as Identifier;
            var members = (values[1] as List)
                .map((m) => m[1] as ASTNode)
                .toList();
            return MemberAccess(object, members);
          });

  // Try fast path first, fall back to slow path
  return (simpleMemberAccess | complexMemberAccess).labeled('memberAccess');
}

Parser arrayAccess() =>
    seq4(ref0(identifier), char('['), ref0(literal), char(']'))
        .map((array) {
          return ArrayAccess(array.$1, array.$3);
        })
        .labeled('arrayAccess');

/// Text parser - parses plain text content until a delimiter is encountered.
///
/// If [config] is provided, uses custom delimiters to determine text boundaries.
///
/// Optimized to parse multiple characters at once using a pattern-based approach:
/// - Characters that are not delimiter start chars or whitespace are always safe text
/// - A delimiter start char is safe only if not followed by the rest of the delimiter
/// - Whitespace is safe only if not followed by strip delimiters
///
/// The whitespace check is critical for Liquid's whitespace control feature:
/// `{{-` and `{%-` strip preceding whitespace, so we must stop parsing text
/// before whitespace that precedes these delimiters.
///
/// This is much more efficient than the naive approach of checking
/// (varStart() | tagStart()).neg() for each character, which requires
/// 11 parser activations per character vs 2-3 for this pattern-based approach.
Parser text([LiquidConfig? config]) {
  final cfg = config ?? LiquidConfig.standard;

  // Build character class for delimiter start characters
  final delimiterChars = cfg.delimiterStartChars;

  // Any character except delimiter start chars and whitespace is definitely safe
  final safeCharPattern = '^$delimiterChars \t\r\n';
  final safeChar = pattern(safeCharPattern);

  // A delimiter start char is safe if not followed by the rest of the delimiter
  final safeBrace = _safeDelimiterChar(cfg);

  // Whitespace is safe if not followed by strip delimiters
  final safeWhitespace =
      pattern(' \t\r\n') &
      (string(cfg.varStartStrip) | string(cfg.tagStartStrip)).not();

  // A text character is either:
  // - A safe char (not delimiter start or whitespace)
  // - A safe brace (delimiter start not followed by rest of delimiter)
  // - Safe whitespace (whitespace not followed by strip delimiters)
  final textChar =
      safeChar | safeBrace | safeWhitespace.map((values) => values[0]);

  // Parse one or more text characters and combine into a single TextNode
  return textChar
      .plus()
      .flatten()
      .map((text) => TextNode(text))
      .labeled('text block');
}

/// Creates a parser for delimiter start characters that are safe (not starting a real delimiter).
Parser _safeDelimiterChar(LiquidConfig cfg) {
  final firstChars = <String>{};
  if (cfg.tagStart.isNotEmpty) firstChars.add(cfg.tagStart[0]);
  if (cfg.varStart.isNotEmpty) firstChars.add(cfg.varStart[0]);

  if (firstChars.isEmpty) {
    return any();
  }

  final parsers = <Parser>[];
  for (final ch in firstChars) {
    final followups = <String>[];
    if (cfg.tagStart.isNotEmpty && cfg.tagStart[0] == ch) {
      followups.add(cfg.tagStart.substring(1));
    }
    if (cfg.varStart.isNotEmpty && cfg.varStart[0] == ch) {
      followups.add(cfg.varStart.substring(1));
    }

    if (followups.isEmpty) {
      parsers.add(char(ch));
    } else {
      final followupParser = followups
          .map((f) => string(f))
          .toList()
          .toChoiceParser();
      parsers.add((char(ch) & followupParser.not()).map((values) => values[0]));
    }
  }

  return parsers.toChoiceParser();
}

Parser comparisonOperator() =>
    (string('==') |
            string('!=') |
            string('<=') |
            string('>=') |
            char('<') |
            char('>') |
            (string('contains') & word().not()).pick(0) |
            (string('in') & word().not()).pick(0))
        .labeled('comparisonOperator');

Parser logicalOperator() =>
    ((string('and') & word().not()).pick(0) |
            (string('or') & word().not()).pick(0))
        .labeled('logicalOperator');

// ---------------------------------------------------------------------------
// DEPRECATED PARSERS
// ---------------------------------------------------------------------------
// The following parsers (comparison, logicalExpression, comparisonOrExpression,
// arithmeticExpression) are no longer used by the main expression() parser.
// They are kept for backwards compatibility and for the profiling test suite.
// The new expression() uses a precedence-based approach via _logicalExpr,
// _comparisonExpr, _arithmeticExpr, and primaryTerm which is more efficient.
// ---------------------------------------------------------------------------

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

Parser unaryOperation() => (ref0(unaryOperator) & ref0(unaryOperand))
    .map((values) => UnaryOperation(values[0], values[1]))
    .labeled('unaryOperation');

/// Operand for unary operations - can be a full expression (minus unary itself to avoid left-recursion).
Parser unaryOperand() {
  return (ref0(groupedExpression) |
          ref0(range) |
          ref0(memberAccess) |
          ref0(arrayAccess) |
          ref0(literal) |
          ref0(identifier))
      .labeled('unaryOperand');
}

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
    ref0(expression).trim(),
    char(')').trim(),
  ).map((values) => GroupedExpression(values.$2)).labeled('groupedExpression');
}

/// Creates a tag parser for a named tag with optional custom delimiters.
///
/// This is the primary way to create custom tags. Use the [config] parameter
/// to specify custom delimiters, or leave it null for standard Liquid delimiters.
///
/// ## Parameters
///
/// - [name]: The tag name to match (e.g., 'mytag' matches `{% mytag %}`)
/// - [config]: Optional delimiter configuration. If null, uses standard delimiters.
/// - [start]: Optional custom start delimiter parser (overrides config)
/// - [end]: Optional custom end delimiter parser (overrides config)
/// - [content]: Optional custom content parser
/// - [filters]: Optional custom filters parser
/// - [hasContent]: Whether the tag has content between delimiters (default: true)
///
/// ## Example with Custom Delimiters
///
/// ```dart
/// final config = LiquidConfig(tagStart: '[%', tagEnd: '%]');
///
/// // Register a custom tag with custom delimiters
/// TagRegistry.register('greeting', (content, filters) {
///   return GreetingTag(content, filters);
/// }, parser: () => someTag('greeting', config: config));
///
/// // Now parses: [% greeting "Hello" %]
/// ```
///
/// ## Example with Standard Delimiters
///
/// ```dart
/// // Register a custom tag with standard delimiters
/// TagRegistry.register('mytag', (content, filters) {
///   return MyTag(content, filters);
/// }, parser: () => someTag('mytag'));
///
/// // Now parses: {% mytag %}
/// ```
///
/// ## Example: Tag Without Content
///
/// ```dart
/// final breakTag = someTag('break', hasContent: false);
/// // Matches: {% break %}
/// ```
///
/// See also:
/// - [LiquidConfig] for delimiter configuration
/// - [TagRegistry] for registering custom tags
/// - [createTagStart], [createTagEnd] for low-level delimiter parsers
Parser<Tag> someTag(
  String name, {
  LiquidConfig? config,
  Parser<dynamic>? start,
  Parser<dynamic>? end,
  Parser<dynamic>? content,
  Parser<dynamic>? filters,
  bool hasContent = true,
}) {
  // Use provided parsers, or create from config, or use defaults
  final startParser = start ?? createTagStart(config);
  final endParser = end ?? createTagEnd(config);

  var parser = (startParser & string(name).trim());

  if (hasContent) {
    parser =
        parser &
        (content ?? ref0(tagContent).optional()).trim() &
        (filters ?? ref0(filter).star()).trim();
  }

  parser = parser & endParser;

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

/// Hash block comment parser - parses `{# comment #}` syntax.
///
/// If [config] is provided, uses custom delimiters from the config.
Parser hashBlockComment([LiquidConfig? config]) =>
    (tagStart(config) &
            pattern(' \t\n\r').star() &
            char('#') &
            any().starLazy(tagEnd(config)).flatten() &
            tagEnd(config))
        .map((values) {
          return TextNode('');
        })
        .labeled('hashBlockComment');

Parser tagContent() {
  // Expression now handles assignment internally via _assignmentExpr
  return (ref0(argument) | ref0(expression))
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

/// Generic tag parser - parses `{% tagname content %}` syntax.
///
/// If [config] is provided, uses custom delimiters from the config.
Parser tag([LiquidConfig? config]) =>
    (tagStart(config) &
            ref0(identifier).trim() &
            ref0(tagContent).optional().trim() &
            ref0(filter).star().trim() &
            tagEnd(config))
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

/// Break tag parser - parses `{% break %}`.
/// If [config] is provided, uses custom delimiters.
Parser<Tag> breakTag([LiquidConfig? config]) =>
    someTag('break', config: config, hasContent: false).labeled('breakTag');

/// Continue tag parser - parses `{% continue %}`.
/// If [config] is provided, uses custom delimiters.
Parser<Tag> continueTag([LiquidConfig? config]) => someTag(
  'continue',
  config: config,
  hasContent: false,
).labeled('continueTag');

/// Else tag parser - parses `{% else %}`.
/// If [config] is provided, uses custom delimiters.
Parser<Tag> elseTag([LiquidConfig? config]) =>
    someTag('else', config: config, hasContent: false).labeled('elseTag');

/// If tag parser - parses `{% if condition %}`.
/// If [config] is provided, uses custom delimiters.
Parser ifTag([LiquidConfig? config]) =>
    someTag("if", config: config).labeled('ifTag');

/// Elsif tag parser - parses `{% elsif condition %}`.
/// If [config] is provided, uses custom delimiters.
Parser elsifTag([LiquidConfig? config]) =>
    someTag("elsif", config: config).labeled('elsifTag');

/// End if tag parser - parses `{% endif %}`.
/// If [config] is provided, uses custom delimiters.
Parser endIfTag([LiquidConfig? config]) =>
    (tagStart(config) & string('endif').trim() & tagEnd(config))
        .map((values) {
          return Tag('endif', []);
        })
        .labeled('endIfTag');

/// For tag parser - parses `{% for item in collection %}`.
/// If [config] is provided, uses custom delimiters.
Parser forTag([LiquidConfig? config]) =>
    someTag('for', config: config).labeled('forTag');

/// End for tag parser - parses `{% endfor %}`.
/// If [config] is provided, uses custom delimiters.
Parser endForTag([LiquidConfig? config]) =>
    (tagStart(config) & string('endfor').trim() & tagEnd(config))
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

/// When tag parser - parses `{% when value %}`.
/// If [config] is provided, uses custom delimiters.
Parser<Tag> whenTag([LiquidConfig? config]) =>
    someTag('when', config: config).labeled('whenTag');

/// Case tag parser - parses `{% case variable %}`.
/// If [config] is provided, uses custom delimiters.
Parser<Tag> caseTag([LiquidConfig? config]) =>
    someTag('case', config: config).labeled('caseTag');

/// End case tag parser - parses `{% endcase %}`.
/// If [config] is provided, uses custom delimiters.
Parser endCaseTag([LiquidConfig? config]) =>
    (tagStart(config) & string('endcase').trim() & tagEnd(config))
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
  // Custom parsers that use {{ }} syntax (like SuperTag) go in variable branch,
  // those using {% %} syntax (default) go in tag branch.
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

  // Lookahead parsers for delimiters.
  // The whitespace-stripping variants ({%-, {{-) need .trim() to consume leading
  // whitespace - this implements Liquid's whitespace control at parse time.
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
/// ## Parameters
///
/// - [input]: The Liquid template string to parse.
/// - [config]: Optional delimiter configuration. If null, uses standard delimiters.
/// - [enableTrace]: If true, outputs trace information during parsing.
/// - [shouldLint]: If true, outputs lint information for the parsed grammar.
///
/// ## Example
///
/// ```dart
/// // Standard delimiters
/// final nodes = parseInput('Hello {{ name }}!');
///
/// // Custom delimiters
/// final config = LiquidConfig(tagStart: '[%', tagEnd: '%]', varStart: '[[', varEnd: ']]');
/// final nodes = parseInput('Hello [[ name ]]!', config: config);
/// ```
///
/// If the parsing is successful, the method returns the list of [ASTNode] objects representing the document.
/// If the parsing fails, throws a [ParsingException] with details about the error.
List<ASTNode> parseInput(
  String input, {
  LiquidConfig? config,
  bool enableTrace = false,
  bool shouldLint = false,
}) {
  //parser fails to handle empty input
  if (input.isEmpty) {
    return [];
  }

  final parser = _getCachedParser(config);

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

/// Cache for parsers keyed by config signature.
final Map<int, Parser> _parserCache = {};

Parser _getCachedParser(LiquidConfig? config) {
  registerBuiltIns();
  final signature = _parserSignature(config);

  var parser = _parserCache[signature];
  if (parser == null) {
    parser = LiquidGrammar(config).build();
    _parserCache[signature] = parser;
  }
  return parser;
}

int _parserSignature(LiquidConfig? config) {
  final parsers = TagRegistry.customParsers;
  final parserHash = Object.hashAll(
    parsers.map((parser) => parser.runtimeType),
  );
  final configHash = config?.hashCode ?? 0;
  return Object.hash(parserHash, configHash);
}
