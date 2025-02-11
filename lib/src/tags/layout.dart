import 'dart:math' show Random;

import 'package:liquify/parser.dart';
import 'package:liquify/src/analyzer/block_info.dart';
import 'package:liquify/src/analyzer/resolver.dart';
import 'package:liquify/src/util.dart';

import '../analyzer/template_analyzer.dart';

class LayoutTag extends AbstractTag with CustomTagParser, AsyncTag {
  final Logger _logger = Logger('LayoutTag');
  late String layoutName;

  LayoutTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    _logger.info('Starting layout evaluation');
    if (content.isEmpty) {
      throw Exception('LayoutTag requires a name as first argument');
    }
    if (content.first is Literal) {
      layoutName = (content.first as Literal).value as String;
    } else if (content.first is Identifier) {
      layoutName = (content.first as Identifier).name;
    }

    layoutName = (evaluator.evaluate(content.first));
    layoutName = evaluator.tmpResult(parseInput(layoutName));

    return buildLayout(evaluator, layoutName.trim());
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
      Evaluator evaluator, Buffer buffer) async {
    _logger.info('Starting layout evaluation');
    if (content.first is Literal) {
      layoutName = (content.first as Literal).value as String;
    } else if (content.first is Identifier) {
      layoutName = (content.first as Identifier).name;
    }

    layoutName = await evaluator.tmpResultAsync(parseInput(layoutName));
    return buildLayout(evaluator, layoutName.trim());
  }

  @override
  Parser parser() {
    return ((tagStart() &
                string('layout').trim() &
                ref0(identifier).or(ref0(stringLiteral)).trim() &
                ref0(namedArgument)
                    .star()
                    .starSeparated(char(',') | whitespace())
                    .trim() &
                tagEnd()) &
            ref0(element).star())
        .map((values) {
      final arguments = [values[2] as ASTNode];
      final elements = values[3].elements as List;
      for (var i = 0; i < elements.length; i++) {
        if (elements[i] is List) {
          final list = elements[i] as List;
          for (var j = 0; j < list.length; j++) {
            final arg = list[j] as NamedArgument;
            arguments.add(arg);
          }
          continue;
        }
      }

      final tag = Tag('layout', arguments, body: values[5].cast<ASTNode>());
      return tag;
    });
  }

  buildLayout(Evaluator evaluator, String layoutName) {
    final layoutEvaluator =
        evaluator.createInnerEvaluatorWithBuffer(evaluator.buffer);
    layoutEvaluator.context.setRoot(evaluator.context.getRoot());
    layoutEvaluator.context.merge(evaluator.context.all());

    // Process variables from layout tag arguments
    for (final arg in content.whereType<NamedArgument>()) {
      final value = evaluator.evaluate(arg.value);
      _logger.info('Setting variable ${arg.identifier.name} = $value');
      layoutEvaluator.context.setVariable(arg.identifier.name, value);
    }
    // Create a template analyzer with the root from the context
    final analyzer = TemplateAnalyzer(evaluator.context.getRoot());

    // First analyze the layout template
    final analysis = analyzer.analyzeTemplate(layoutName).last;
    final layoutStructure = analysis.structures[layoutName];

    if (layoutStructure == null) {
      throw Exception('Failed to analyze layout template: $layoutName');
    }

    final blocks =
        body.whereType<Tag>().where((tag) => tag.name == 'block').map((tag) {
      String source = "templ${Random().nextInt(1000)}.liquid";
      String name = '';
      if (tag.content.isNotEmpty && tag.content.first is Identifier) {
        name = (tag.content.first as Identifier).name;
      } else if (tag.content.isNotEmpty && tag.content.first is Literal) {
        name = (tag.content.first as Literal).value as String;
      }
      return BlockInfo(
          name: name,
          source: source,
          content: tag.body,
          isOverride: true,
          nestedBlocks: {},
          hasSuperCall: false);
    }).fold<Map<String, BlockInfo>>({}, (map, block) {
      map[block.name] = block;
      return map;
    });

    final mergedAst =
        buildCompleteMergedAst(layoutStructure, overrides: blocks);

    // Evaluate the merged AST
    _logger.info('Evaluating merged AST');
    for (final node in mergedAst) {
      final result = layoutEvaluator.evaluate(node);
      if (result != null) {
        evaluator.buffer.write(result);
      }
    }

    _logger.info('Layout evaluation complete');
  }
}
