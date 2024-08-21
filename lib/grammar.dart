import 'package:liquid_grammar/ast.dart';
import 'package:liquid_grammar/registry.dart';
import 'package:petitparser/petitparser.dart';

extension TagExtension on LiquidGrammar {
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

  Parser elseBlock() => seq2(
        ref0(elseTag),
        ref0(element)
            .starLazy(ref0(endCaseTag).or(ref0(endIfTag)).or(ref0(endForTag))),
      ).map((values) {
        final eTag = values.$1;
        eTag.body = values.$2.cast<ASTNode>();
        return eTag as ASTNode;
      });
}

extension IFBlockExtension on LiquidGrammar {
  Parser ifBlock() => seq3(
        ref0(ifTag),
        ref0(element).starLazy(endIfTag()),
        ref0(endIfTag),
      ).map((values) {
        final ifTag = values.$1 as Tag;
        ifTag.body = values.$2.cast<ASTNode>();
        return ifTag as ASTNode;
      });

  Parser ifTag() => someTag("if");

  Parser elseifOrElse() => ref0(elseifTag) | ref0(elseTag);

  Parser elseifTag() => (tagStart() &
              string('elseif').trim() &
              ref0(tagContent).optional().trim() &
              ref0(filter).star().trim() &
              tagEnd() &
              ref0(element).starLazy(ref0(elseifOrElse).or(ref0(endIfTag))))
          .map((values) {
        final content = values[2] as List<ASTNode>? ?? [];
        final filters = (values[3] as List).cast<Filter>();
        final body = values[5].cast<ASTNode>();
        return Tag('elseif', content, filters: filters)..body = body;
      });

  Parser endIfTag() =>
      (tagStart() & string('endif').trim() & tagEnd()).map((values) {
        return Tag('endif', []);
      });
}

extension FromBlockExtension on LiquidGrammar {
  Parser forBlock() => seq3(
        ref0(forTag),
        ref0(element).starLazy(endForTag()),
        ref0(endForTag),
      ).map((values) {
        final forTag = values.$1;
        forTag.body = values.$2.cast<ASTNode>();
        return forTag as ASTNode;
      });

  Parser<Tag> forTag() => someTag('for');

  Parser endForTag() =>
      (tagStart() & string('endfor').trim() & tagEnd()).map((values) {
        return Tag('endfor', []);
      });
}

extension CaseWhenTagExtension on LiquidGrammar {
  Parser caseBlock() => seq3(
        ref0(caseTag),
        ref0(element).starLazy(endCaseTag()),
        ref0(endCaseTag),
      ).map((values) {
        final caseTag = values.$1;
        caseTag.body = values.$2.cast<ASTNode>();
        return caseTag as ASTNode;
      });

  Parser<Tag> whenTag() => someTag('when');

  Parser<Tag> caseTag() => someTag('case');

  Parser endCaseTag() =>
      (tagStart() & string('endcase').trim() & tagEnd()).map((values) {
        return Tag('endcase', []);
      });
}

class LiquidGrammar extends GrammarDefinition {
  @override
  Parser start() => ref0(document).end();

  Parser document() => ref0(element)
      .star()
      .map((elements) => Document(elements.cast<ASTNode>()));

  Parser element() =>
      ref0(liquidTag) |
      ref0(rawTag) |
      ref0(ifBlock) |
      ref0(elseBlock) |
      ref0(forBlock) |
      ref0(caseBlock) |
      ref0(breakTag) |
      ref0(continueTag) |
      ref0(tag) |
      ref0(variable) |
      ref0(text);

  Parser caseBlock() => seq3(
        ref0(caseTag),
        ref0(element).starLazy(ref0(endCaseTag)),
        ref0(endCaseTag),
      ).map((values) {
        final ifTag = values.$1;
        ifTag.body = values.$2.cast<ASTNode>();
        return ifTag as ASTNode;
      });

  Parser elseTag() => (tagStart() &
              string('else').trim() &
              tagEnd() &
              ref0(element).starLazy(ref0(endIfTag).or(ref0(endCaseTag))))
          .map((values) {
        final body = values[3].cast<ASTNode>();
        return Tag('else', [])..body = body;
      });

  Parser tagStart() => string('{%-') | string('{%');

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

  Parser variable() => (varStart().trim() &
              ref0(expression).trim() &
              filter().star().trim() &
              varEnd())
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
    return (ref0(identifier) & char(':').trim() & ref0(expression))
        .map((values) {
      return NamedArgument(values[0] as Identifier, values[2] as ASTNode);
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

  Parser block() {
    return ref0(element).star();
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

  Parser unaryOperation() =>
      (ref0(unaryOperator) & ref0(comparisonOrExpression))
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
            // Match the opening parenthesis and trim any surrounding whitespace.
            (ref0(arithmeticExpression) |
                    ref0(memberAccess) |
                    ref0(unaryOperation) |
                    ref0(literal) |
                    ref0(comparison) |
                    ref0(logicalExpression) |
                    ref0(expression))
                .trim(),
            // Parse the expression inside the parentheses, trimming any surrounding whitespace.
            char(')')
                .trim() // Match the closing parenthesis and trim any surrounding whitespace.
            )
        .map((values) => GroupedExpression(values.$2));
  }

  Parser rawTag() {
    return (tagStart() &
            string('raw').trim() &
            tagEnd() &
            any()
                .starLazy((tagStart() & string('endraw').trim() & tagEnd()))
                .flatten() &
            tagStart() &
            string('endraw').trim() &
            tagEnd())
        .map((values) {
      return Tag("raw", [TextNode(values[3])]);
    });
  }

  Parser liquidTag() => (tagStart() &
              string('liquid').trim() &
              any().starLazy(tagEnd()).flatten() &
              tagEnd())
          .map((values) {
        //TODO better mechanism for registering tags
        return Tag("liquid", liquidTagContents(values[2], TagRegistry.tags));
      });
}

List<ASTNode> liquidTagContents(String content, List<String> tagRegistry) {
  final lines = content.split('\n').map((line) => line.trim()).toList();
  StringBuffer buffer = StringBuffer();
  for (var line in lines) {
    final firstWord = line.split(' ').first;

    if (tagRegistry.contains(firstWord)) {
      buffer.writeln("{% $line %}");
    } else {
      buffer.writeln(line);
    }
  }

  final result = LiquidGrammar().build().parse(buffer.toString());
  if (result is Success) {
    return (result.value as Document).children;
  }

  return [TextNode(content)]; // Return a list or a specific node type
}
