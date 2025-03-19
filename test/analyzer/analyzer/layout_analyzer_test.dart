import 'package:liquify/src/analyzer/template_analyzer.dart';
import 'package:liquify/src/util.dart';
import 'package:test/test.dart';

import '../../shared_test_root.dart';

void main() {
  group('Layout Analyzer', () {
    late TestRoot root;
    late TemplateAnalyzer analyzer;

    setUp(() {
      // Configure logging - enable only analyzer logs
      Logger.disableAllContexts();
      // Logger.enableContext('Analyzer');
      root = TestRoot();
      analyzer = TemplateAnalyzer(root);

      // Base template with simple blocks.
      root.addFile('base.liquid', '''
        <!DOCTYPE html>
        <html>
          <head>
            {% block head %}
              <title>Base Title</title>
            {% endblock %}
          </head>
          <body>
            {% block content %}{% endblock %}
          </body>
        </html>
      ''');

      // Child template that extends the base.
      root.addFile('child.liquid', '''
        {% layout 'base.liquid' %}
        
        {% block head %}
          <title>Child Title</title>
        {% endblock %}
        
        {% block content %}
          <p>Child content</p>
        {% endblock %}
      ''');
    });

    test('analyzes layout inheritance', () async {
      final analysis = analyzer.analyzeTemplate('child.liquid').last;
      expect(analysis.structures.containsKey('child.liquid'), isTrue);

      final childStructure = analysis.structures['child.liquid']!;
      final resolvedBlocks = childStructure.resolvedBlocks;

      // Check for expected block keys.
      expect(resolvedBlocks.keys, containsAll(['head', 'content']));

      // The child overrides the head block from the base.
      final headBlock = resolvedBlocks['head'];
      expect(headBlock, isNotNull);
      expect(headBlock!.isOverride, isTrue);

      // The content block is defined only in the child.
      final contentBlock = resolvedBlocks['content'];
      expect(contentBlock, isNotNull);
      expect(contentBlock!.isOverride, isTrue);
    });
  });
}
