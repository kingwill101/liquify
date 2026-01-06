import 'package:liquify/src/analyzer/resolver.dart';
import 'package:liquify/src/analyzer/template_analyzer.dart';
import 'package:test/test.dart';
import '../../shared_test_root.dart';
import 'ast_matcher.dart';
import 'package:liquify/src/util.dart';

void main() {
  group('Deeply Nested Super Merge', () {
    late TestRoot root;
    late TemplateAnalyzer analyzer;

    setUp(() {
      // Configure logging - enable only resolver logs
      Logger.disableAllContexts();
      // Logger.enableContext('Resolver');
      root = TestRoot();
      analyzer = TemplateAnalyzer(root);

      // Grandparent template: defines header with nested navigation.
      root.addFile('grandparent.liquid', '''
      <!DOCTYPE html>
      <html>
        <head>
          {% block title %}Grandparent Title{% endblock %}
        </head>
        <body>
          <header>
            {% block header %}
              <div>Grandparent Header</div>
              {% block navigation %}
                <nav><ul><li>Grandparent Nav</li></ul></nav>
              {% endblock %}
            {% endblock %}
          </header>
          <main>
            {% block content %}Grandparent Content{% endblock %}
          </main>
          <footer>
            {% block footer %}Grandparent Footer{% endblock %}
          </footer>
        </body>
      </html>
      ''');

      // Parent template: extends grandparent and overrides navigation.
      root.addFile('parent.liquid', '''
      {% layout 'grandparent.liquid' %}
      {% block navigation %}
        <nav><ul><li>Parent Nav</li></ul></nav>
      {% endblock %}
      ''');

      // Child template: extends parent and overrides navigation, calling super().
      root.addFile('child.liquid', '''
      {% layout 'parent.liquid' %}
      {% block navigation %}
        <nav>
          <ul>
            <li>Child Nav Before</li>
            {{ super() }}
            <li>Child Nav After</li>
          </ul>
        </nav>
      {% endblock %}
      ''');
    });

    test('merged AST reflects deep nesting with super call override', () async {
      final analysis = analyzer.analyzeTemplate('child.liquid').last;
      final structure = analysis.structures['child.liquid']!;
      final mergedAst = buildCompleteMergedAst(structure);

      ASTMatcher.validateAST(mergedAst, [
        ASTMatcher.text('<!DOCTYPE html>'),
        ASTMatcher.text('Grandparent Title'),
        ASTMatcher.text('Grandparent Header'),
        ASTMatcher.text('Child Nav Before'),
        // In our resolution of super(), we expect the parent's override (from parent.liquid)
        // to be injected. Parent's navigation content is supposed to be "<nav><ul><li>Parent Nav</li></ul></nav>".
        // So we expect "Parent Nav" to appear.
        ASTMatcher.text('Parent Nav'),
        ASTMatcher.text('Child Nav After'),
        ASTMatcher.text('Grandparent Content'),
        ASTMatcher.text('</html>'),
      ]);
    });
  });
}
