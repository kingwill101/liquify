import 'package:liquify/src/grammar/shared.dart';
import 'package:liquify/src/tag_registry.dart';

extension TagExtension on LiquidGrammar {
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
        ref0(element).plusLazy(endCaseTag()),
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

  Parser whenBlock() => seq2(
        ref0(whenTag),
        ref0(element)
            .starLazy(ref0(endCaseTag).or(ref0(elseTag).or(whenTag()))),
      ).map((values) {
        final eTag = values.$1;
        eTag.body = values.$2.cast<ASTNode>();
        return eTag as ASTNode;
      });
}

class LiquidGrammar extends GrammarDefinition {
  @override
  Parser start() => ref0(document).end();

  Parser<Document> document() => ref0(element).plus().map((elements) {
        var collapsedElements = collapseTextNodes(elements.cast<ASTNode>());
        return Document(collapsedElements);
      });

  Parser element() => [
        ref0(ifBlock),
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
}
