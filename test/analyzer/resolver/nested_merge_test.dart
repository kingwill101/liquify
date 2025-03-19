import 'package:liquify/liquify.dart';
import 'package:liquify/src/analyzer/resolver.dart';
import 'package:liquify/src/analyzer/template_analyzer.dart';
import 'package:test/test.dart';
import '../../shared_test_root.dart';
import 'ast_matcher.dart';
import 'package:liquify/src/util.dart';

void main() {
  group('Nested Merge', () {
    late TestRoot root;
    late TemplateAnalyzer analyzer;

    setUp(() {
      // Configure logging - enable only resolver logs
      Logger.disableAllContexts();
      // Logger.enableContext('Resolver');
      root = TestRoot();
      analyzer = TemplateAnalyzer(root);

      // Parent template: defines layout with a header block that contains a nested 'navigation' block.
      root.addFile('parent.liquid', '''
      <!DOCTYPE html>
      <html>
        <head>
          {% block title %}Default Title{% endblock %}
        </head>
        <body>
          <header>
            {% block header %}
              <div>Default Header</div>
              {% block navigation %}Default Navigation{% endblock %}
            {% endblock %}
          </header>
          <main>
            {% block content %}Default Content{% endblock %}
          </main>
        </body>
      </html>
      ''');

      // Child template: overrides the 'navigation' block.
      root.addFile('child.liquid', '''
      {% layout 'parent.liquid' %}
      {% block navigation %}Overridden Navigation{% endblock %}
      ''');
    });

    test('merged AST injects nested block override', () async {
      final analysis = analyzer.analyzeTemplate('child.liquid').last;
      final structure = analysis.structures['child.liquid']!;
      final mergedAst = buildCompleteMergedAst(structure);

      ASTMatcher.validateAST(mergedAst, [
        ASTMatcher.text('<!DOCTYPE html>'),
        ASTMatcher.text('<html>'),
        ASTMatcher.text('<head>'),
        ASTMatcher.text('<body>'),
        ASTMatcher.text('<header>'),
        ASTMatcher.text('</header>'),
        ASTMatcher.text('Default Title'),
        ASTMatcher.text('Default Header'),
        ASTMatcher.text('Overridden Navigation'),
        ASTMatcher.text('Default Content'),
        ASTMatcher.text('</main>'),
        ASTMatcher.text('</body>'),
        ASTMatcher.text('</html>'),
      ]);
    });
  });
}
