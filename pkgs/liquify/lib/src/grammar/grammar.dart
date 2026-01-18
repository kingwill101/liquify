import 'package:liquify/src/grammar/shared.dart';
import 'package:liquify/src/mixins/parser.dart';
import 'package:liquify/src/tag_registry.dart';

/// The main Liquid grammar that supports optional custom delimiters.
///
/// This grammar can be instantiated with a [LiquidConfig] to use custom
/// delimiters instead of the standard `{% %}` and `{{ }}`.
///
/// ## Standard Usage
///
/// ```dart
/// final grammar = LiquidGrammar();
/// final parser = grammar.build();
/// final result = parser.parse('Hello {{ name }}!');
/// ```
///
/// ## Custom Delimiters
///
/// ```dart
/// final config = LiquidConfig(
///   tagStart: '[%', tagEnd: '%]',
///   varStart: '[[', varEnd: ']]',
/// );
/// final grammar = LiquidGrammar(config);
/// final parser = grammar.build();
/// final result = parser.parse('Hello [[ name ]]!');
/// ```
class LiquidGrammar extends GrammarDefinition {
  /// The delimiter configuration for this grammar.
  ///
  /// If null, uses standard Liquid delimiters (`{% %}` and `{{ }}`).
  final LiquidConfig? config;

  /// Creates a new Liquid grammar with optional custom delimiters.
  ///
  /// If [config] is null, uses standard Liquid delimiters.
  LiquidGrammar([this.config]);

  @override
  Parser start() => ref0(document).end();

  // ---------------------------------------------------------------------------
  // Delimiter parsers - use config if provided
  // ---------------------------------------------------------------------------

  Parser configTagStart() => createTagStart(config);
  Parser configTagEnd() => createTagEnd(config);
  Parser configVarStart() => createVarStart(config);
  Parser configVarEnd() => createVarEnd(config);

  // ---------------------------------------------------------------------------
  // Core document structure
  // ---------------------------------------------------------------------------

  Parser document() => ref0(element)
      .plus()
      .map((elements) {
        var collapsedElements = collapseTextNodes(elements.cast<ASTNode>());
        return Document(collapsedElements);
      })
      .labeled('document');

  Parser element() {
    final cfg = config ?? LiquidConfig.standard;

    // Separate custom parsers by their delimiter type.
    final varCustomParsers = <Parser>[];
    final tagCustomParsers = <Parser>[];

    for (final customParser in TagRegistry.customParsers) {
      if (customParser.delimiterType == TagDelimiterType.variable) {
        varCustomParsers.add(customParser.parser(config));
      } else {
        tagCustomParsers.add(customParser.parser(config));
      }
    }

    // Variable-like elements (start with varStart or varStartStrip)
    final variableElements = [
      ...varCustomParsers,
      ref0(variable),
    ].toChoiceParser();

    // Tag/block parsers (start with tagStart or tagStartStrip)
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

    // Text parser
    final textElement = ref0(text);

    // Lookahead parsers for delimiters
    final tagLookahead =
        (string(cfg.tagStartStrip).trim() | string(cfg.tagStart)).and();
    final varLookahead =
        (string(cfg.varStartStrip).trim() | string(cfg.varStart)).and();

    return ((varLookahead & variableElements).pick(1) |
            (tagLookahead & tagElements).pick(1) |
            textElement)
        .labeled('element');
  }

  // ---------------------------------------------------------------------------
  // Variable parser
  // ---------------------------------------------------------------------------

  Parser variable() =>
      (ref0(configVarStart) &
              ref0(expression).trim() &
              filter().star().trim() &
              ref0(configVarEnd))
          .map((values) {
            ASTNode expr = values[1];
            var filters = values[2] as List;

            String name = '';
            if (expr is Identifier) {
              name = expr.name;
            } else if (expr is MemberAccess) {
              name = (expr.object as Identifier).name;
            }

            if (filters.isNotEmpty) {
              return FilteredExpression(
                Variable(name, expr),
                filters.cast<Filter>(),
              );
            }

            return Variable(name, expr);
          })
          .labeled('variable');

  // ---------------------------------------------------------------------------
  // Text parser - config-aware for custom delimiters
  // ---------------------------------------------------------------------------

  Parser text() {
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

    final textChar =
        safeChar | safeBrace | safeWhitespace.map((values) => values[0]);

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
        parsers.add(
          (char(ch) & followupParser.not()).map((values) => values[0]),
        );
      }
    }

    return parsers.toChoiceParser();
  }

  // ---------------------------------------------------------------------------
  // Tag parser
  // ---------------------------------------------------------------------------

  Parser tag() {
    return (ref0(configTagStart) &
            ref0(identifier).trim() &
            ref0(configTagContent).optional().trim() &
            ref0(filter).star().trim() &
            ref0(configTagEnd))
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
  }

  Parser configTagContent() {
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

  // ---------------------------------------------------------------------------
  // Hash block comment
  // ---------------------------------------------------------------------------

  Parser hashBlockComment() =>
      (ref0(configTagStart) &
              pattern(' \t\n\r').star() &
              char('#') &
              any().starLazy(ref0(configTagEnd)).flatten() &
              ref0(configTagEnd))
          .map((values) => TextNode(''))
          .labeled('hashBlockComment');

  // ---------------------------------------------------------------------------
  // If block
  // ---------------------------------------------------------------------------

  Parser<Tag> ifTag() => someTag("if", config: config).labeled('ifTag');
  Parser<Tag> elsifTag() =>
      someTag("elsif", config: config).labeled('elsifTag');
  Parser<Tag> elseTag() =>
      someTag('else', config: config, hasContent: false).labeled('elseTag');

  Parser endIfTag() =>
      (ref0(configTagStart) & string('endif').trim() & ref0(configTagEnd))
          .map((values) => Tag('endif', []))
          .labeled('endIfTag');

  Parser ifBranchContent() => ref0(element)
      .starLazy(ref0(elsifTag).or(ref0(elseTag)).or(ref0(endIfTag)))
      .labeled('ifBranchContent');

  Parser elsifBranchContent() => ref0(element)
      .starLazy(ref0(elsifTag).or(ref0(elseTag)).or(ref0(endIfTag)))
      .labeled('elsifBranchContent');

  Parser elseBranchContent() =>
      ref0(element).starLazy(ref0(endIfTag)).labeled('elseBranchContent');

  Parser elseIfBlock() => seq2(ref0(elsifTag), ref0(elsifBranchContent))
      .map((values) {
        final elsifTag = values.$1;
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

  Parser ifBlock() =>
      seq5(
            ref0(ifTag),
            ref0(ifBranchContent),
            ref0(elseIfBlock).star(),
            ref0(elseBlock).optional(),
            ref0(endIfTag),
          )
          .map((values) {
            final ifTag = values.$1;
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

  // ---------------------------------------------------------------------------
  // For block
  // ---------------------------------------------------------------------------

  Parser<Tag> forTag() => someTag('for', config: config).labeled('forTag');

  Parser endForTag() =>
      (ref0(configTagStart) & string('endfor').trim() & ref0(configTagEnd))
          .map((values) => Tag('endfor', []))
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
            final forTag = values.$1;
            final forBody = (values.$2).cast<ASTNode>();
            final elseBlockForFor = values.$3 as Tag?;

            final List<ASTNode> allBodyNodes = [...forBody];
            if (elseBlockForFor != null) {
              allBodyNodes.add(elseBlockForFor);
            }

            return forTag.copyWith(body: allBodyNodes);
          })
          .labeled('forBlock');

  // ---------------------------------------------------------------------------
  // Case block
  // ---------------------------------------------------------------------------

  Parser<Tag> whenTag() => someTag('when', config: config).labeled('whenTag');
  Parser<Tag> caseTag() => someTag('case', config: config).labeled('caseTag');

  Parser endCaseTag() =>
      (ref0(configTagStart) & string('endcase').trim() & ref0(configTagEnd))
          .map((values) => Tag('endcase', []))
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
      seq3(
            ref0(caseTag),
            ref0(element).starLazy(ref0(endCaseTag)),
            ref0(endCaseTag),
          )
          .map((values) {
            return (values.$1).copyWith(body: (values.$2).cast<ASTNode>());
          })
          .labeled('caseBlock');
}
