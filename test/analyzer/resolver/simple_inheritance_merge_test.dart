import 'package:liquify/src/analyzer/template_analyzer.dart';
import 'package:liquify/src/analyzer/resolver.dart';
import 'package:liquify/src/util.dart';
import 'package:test/test.dart';
import '../../shared_test_root.dart';

void main() {
  group('Simple Inheritance Merge', () {
    late TestRoot root;
    late TemplateAnalyzer analyzer;

    setUp(() {
      // Configure logging - enable only resolver logs
      Logger.disableAllContexts();
      // Logger.enableContext('Resolver');
      root = TestRoot();
      analyzer = TemplateAnalyzer(root);

      // Parent template: a basic layout with two blocks.
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

      // Child template: extends parent.liquid and overrides both blocks.
      root.addFile('child.liquid', '''
      {% layout 'parent.liquid' %}
      {% block title %}Overridden Title{% endblock %}
      {% block content %}Overridden Content{% endblock %}
      ''');
    });

    test('merged AST contains full layout with overridden blocks', () async {
      final analysis = analyzer.analyzeTemplate('child.liquid').last;
      final structure = analysis.structures['child.liquid']!;

      // Build the complete merged AST (i.e. parent's raw AST with child overrides applied)
      final mergedAst = buildCompleteMergedAst(structure);
      final mergedText = mergedAst.map((node) => node.toString()).join();

      expect(mergedText, contains('<!DOCTYPE html>'));
      expect(mergedText, contains('Overridden Title'));
      expect(mergedText, contains('Overridden Content'));
    });
  });
}
