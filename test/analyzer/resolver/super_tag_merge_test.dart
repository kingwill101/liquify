import 'package:liquify/src/analyzer/template_analyzer.dart';
import 'package:liquify/src/analyzer/resolver.dart';
import 'package:liquify/src/util.dart';
import 'package:test/test.dart';
import '../../shared_test_root.dart';
import 'ast_matcher.dart';

void main() {
  group('Super Tag Merge', () {
    late TestRoot root;
    late TemplateAnalyzer analyzer;

    setUp(() {
      // Configure logging - enable only resolver logs
      Logger.disableAllContexts();
      // // Logger.enableContext('Resolver');
      root = TestRoot();
      analyzer = TemplateAnalyzer(root);

      // Parent template: defines a content block.
      root.addFile('parent.liquid', '''
      <!DOCTYPE html>
      <html>
        <body>
          {% block content %}
            <p>Parent Content</p>
          {% endblock %}
        </body>
      </html>
      ''');

      // Child template: overrides content block and calls super().
      root.addFile('child.liquid', '''
      {% layout 'parent.liquid' %}
      {% block content %}
         <div>Child Before</div>
         {{ super() }}
         <div>Child After</div>
      {% endblock %}
      ''');
    });

    test('merged AST reflects super() call override', () async {
      final analysis = analyzer.analyzeTemplate('child.liquid').last;
      final structure = analysis.structures['child.liquid']!;
      final mergedAst = buildCompleteMergedAst(structure);

      ASTMatcher.validateAST(mergedAst, [
        ASTMatcher.text('Child Before'),
        // In this scenario, parent's content is "<p>Parent Content</p>"
        ASTMatcher.text('Parent Content'),
        ASTMatcher.text('Child After'),
        // The merged AST should not include a literal "super" but have replaced it.
      ]);
    });
  });
}
