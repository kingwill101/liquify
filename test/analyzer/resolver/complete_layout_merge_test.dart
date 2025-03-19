import 'package:liquify/src/analyzer/template_analyzer.dart';
import 'package:liquify/src/analyzer/resolver.dart';
import 'package:liquify/src/util.dart';
import 'package:test/test.dart';

import '../../shared_test_root.dart';

void main() {
  group('Complete Layout Merge', () {
    late TestRoot root;
    late TemplateAnalyzer analyzer;

    setUp(() {
      // Configure logging - enable only resolver logs
      Logger.disableAllContexts();
      // Logger.enableContext('Resolver');
      root = TestRoot();
      analyzer = TemplateAnalyzer(root);

      // Base template: defines a complete layout with several blocks.
      root.addFile('base.liquid', '''
      <!DOCTYPE html>
      <html>
        <head>
          {% block title %}Default Title{% endblock %}
          {% block styles %}<link rel="stylesheet" href="styles.css">{% endblock %}
        </head>
        <body>
          <header>
            {% block header %}Default Header{% endblock %}
          </header>
          <main>
            {% block content %}Default Content{% endblock %}
          </main>
          <footer>
            {% block footer %}Default Footer{% endblock %}
          </footer>
        </body>
      </html>
      ''');

      // Parent template: extends base.liquid and overrides the header.
      // It defines a nested 'navigation' block inside the header.
      root.addFile('parent.liquid', '''
      {% layout 'base.liquid' %}
      {% block header %}
        <div class="header-wrapper">
          {% block navigation %}
            <nav>Default Navigation</nav>
          {% endblock %}
          <h1>Parent Header</h1>
        </div>
      {% endblock %}
      ''');

      // Child template: extends parent.liquid and overrides title, content,
      // and the nested navigation block (calling super())
      root.addFile('child.liquid', '''
      {% layout 'parent.liquid' %}
      {% block title %}Child Title{% endblock %}
      {% block content %}
        <div class="content">
          <p>Child Customized Content</p>
        </div>
      {% endblock %}
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

    test('merges complete layout structure', () async {
      // Analyze the child template.
      final analysis = analyzer.analyzeTemplate('child.liquid').last;
      expect(analysis.structures.containsKey('child.liquid'), isTrue);

      final childStructure = analysis.structures['child.liquid']!;

      // Verify the template structure first
      expect(childStructure.templatePath, equals('child.liquid'));
      expect(childStructure.parent?.templatePath, equals('parent.liquid'));
      expect(
          childStructure.parent?.parent?.templatePath, equals('base.liquid'));

      // Verify block structure
      expect(childStructure.blocks.length, equals(3));
      expect(childStructure.blocks['title']?.source, equals('child.liquid'));
      expect(childStructure.blocks['title']?.isOverride, isTrue);
      expect(childStructure.blocks['content']?.source, equals('child.liquid'));
      expect(childStructure.blocks['content']?.isOverride, isTrue);
      expect(childStructure.blocks['header.navigation']?.source,
          equals('child.liquid'));
      expect(childStructure.blocks['header.navigation']?.isOverride, isTrue);
      expect(childStructure.blocks['header.navigation']?.hasSuperCall, isTrue);

      // Build and verify the merged AST
      final mergedAst = buildCompleteMergedAst(childStructure);

      // Convert to string for easier verification
      final mergedText = mergedAst.map((node) => node.toString()).join('');

      // Verify the merged content
      expect(mergedText, contains('Child Title')); // Child's title override
      expect(
          mergedText,
          contains(
              '<link rel="stylesheet" href="styles.css">')); // Base styles preserved
      expect(mergedText,
          contains('Child Nav Before')); // Child's navigation prefix
      expect(
          mergedText,
          contains(
              'Default Navigation')); // Parent's navigation (from super call)
      expect(
          mergedText, contains('Child Nav After')); // Child's navigation suffix
      expect(mergedText,
          contains('Child Customized Content')); // Child's content override
      expect(mergedText, contains('Default Footer')); // Base footer preserved

      // Verify the order of elements
      final lines = mergedText
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      expect(
          lines,
          containsAllInOrder([
            '<!DOCTYPE html>',
            '<html>',
            '<head>',
            'Child Title',
            '<link rel="stylesheet" href="styles.css">',
            '</head>',
            '<body>',
            '<header>',
            '<div class="header-wrapper">',
            '<nav>',
            '<ul>',
            '<li>Child Nav Before</li>',
            '<nav>Default Navigation</nav>',
            '<li>Child Nav After</li>',
            '</ul>',
            '</nav>',
            '<h1>Parent Header</h1>',
            '</div>',
            '</header>',
            '<main>',
            '<div class="content">',
            '<p>Child Customized Content</p>',
            '</div>',
            '</main>',
            '<footer>',
            'Default Footer',
            '</footer>',
            '</body>',
            '</html>'
          ]));

      // For debugging purposes, print the merged AST
      // print('Merged AST nodes:');
      // for (var node in mergedAst) {
      //   print('  ${node.runtimeType}: $node');
      // }
    });
  });
}
