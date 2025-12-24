import 'package:liquify/src/analyzer/template_analyzer.dart';
import 'package:liquify/src/analyzer/resolver.dart';
import 'package:liquify/src/util.dart';
import 'package:test/test.dart';

import '../../shared_test_root.dart';
import 'ast_matcher.dart';

void main() {
  group('Multi-Level Inheritance Merge', () {
    late TestRoot root;
    late TemplateAnalyzer analyzer;

    setUp(() {
      // Disable analyzer logging and enable only resolver logging
      Logger.disableAllContexts();
      // Logger.enableContext('Resolver');
      root = TestRoot();
      analyzer = TemplateAnalyzer(root);

      // Grandparent template: complete layout with blocks 'title' and 'content'.
      root.addFile('grandparent.liquid', '''
      <!DOCTYPE html>
      <html>
        <head>
          {% block title %}Grandparent Title{% endblock %}
        </head>
        <body>
          {% block content %}Grandparent Content{% endblock %}
        </body>
      </html>
      ''');

      // Parent template: extends grandparent and overrides the title.
      root.addFile('parent.liquid', '''
      {% layout 'grandparent.liquid' %}
      {% block title %}Parent Title{% endblock %}
      ''');

      // Child template: extends parent and overrides the content.
      root.addFile('child.liquid', '''
      {% layout 'parent.liquid' %}
      {% block content %}Child Content{% endblock %}
      ''');
    });

    test('merged AST combines multi-level inheritance correctly', () async {
      final analysis = analyzer.analyzeTemplate('child.liquid').last;
      final structure = analysis.structures['child.liquid']!;
      final mergedAst = buildCompleteMergedAst(structure);

      ASTMatcher.validateAST(mergedAst, [
        ASTMatcher.text('<!DOCTYPE html>'),
        // In a multi-level scenario, grandparent defines title as "Grandparent Title",
        // parent overrides title with "Parent Title", and child overrides content.
        ASTMatcher.text('Parent Title'),
        ASTMatcher.text('Child Content'),
        ASTMatcher.text('</html>'),
      ]);
    });
  });
}
