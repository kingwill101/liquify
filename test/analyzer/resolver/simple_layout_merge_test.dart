import 'package:liquify/src/analyzer/template_analyzer.dart';
import 'package:liquify/src/analyzer/resolver.dart';
import 'package:liquify/src/util.dart';
import 'package:test/test.dart';

import '../../shared_test_root.dart';
import 'ast_matcher.dart';

void main() {
  group('Simple Layout Merge', () {
    late TestRoot root;
    late TemplateAnalyzer analyzer;

    setUp(() {
      // Configure logging - enable only resolver logs
      Logger.disableAllContexts();
      // Logger.enableContext('Resolver');
      root = TestRoot();
      analyzer = TemplateAnalyzer(root);

      // Parent template defines a basic layout with two blocks.
      root.addFile('parent.liquid', '''
      <!DOCTYPE html>
      <html>
        <head>
          {% block title %}Default Title{% endblock %}
        </head>
        <body>
          {% block content %}Default Content{% endblock %}
        </body>
      </html>
      ''');

      // Child template extends parent.liquid and overrides both blocks.
      root.addFile('child.liquid', '''
      {% layout 'parent.liquid' %}
      {% block title %}Overridden Title{% endblock %}
      {% block content %}Overridden Content{% endblock %}
      ''');
    });

    test('merges single-level inheritance correctly', () async {
      final analysis = analyzer.analyzeTemplate('child.liquid').last;
      final structure = analysis.structures['child.liquid']!;
      final mergedAst = buildCompleteMergedAst(structure);

      ASTMatcher.validateAST(mergedAst, [
        ASTMatcher.text('<!DOCTYPE html>'),
        ASTMatcher.text('Overridden Title'),
        ASTMatcher.text('Overridden Content')
      ]);
    });
  });
}
