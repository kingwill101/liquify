import 'package:liquify/src/analyzer/template_analyzer.dart';
import 'package:liquify/src/util.dart';
import 'package:test/test.dart';

import '../../shared_test_root.dart';

void main() {
  group('Nested Blocks Analysis', () {
    late TestRoot root;
    late TemplateAnalyzer analyzer;

    setUp(() {
      // Configure logging - enable only analyzer logs
      Logger.disableAllContexts();
      // Logger.enableContext('Analyzer');
      root = TestRoot();
      analyzer = TemplateAnalyzer(root);

      // Base template with a nested block.
      root.addFile('base.liquid', '''
        {% block header %}
          <div class="header">
            {% block navigation %}
              <ul><li>Base Navigation</li></ul>
            {% endblock %}
          </div>
        {% endblock %}
      ''');

      // Child template extends the base and overrides the nested "navigation" block.
      root.addFile('child.liquid', '''
        {% layout 'base.liquid' %}
        
        {% block navigation %}
          <ul><li>Child Navigation</li></ul>
        {% endblock %}
      ''');
    });

    test('analyzes nested blocks', () async {
      final analysis = analyzer.analyzeTemplate('child.liquid').last;
      expect(analysis.structures.containsKey('child.liquid'), isTrue);

      final childStructure = analysis.structures['child.liquid']!;
      final resolvedBlocks = childStructure.resolvedBlocks;

      // Expect the childStructure to contain the "header" block and a nested block "header.navigation".
      expect(resolvedBlocks.keys, containsAll(['header', 'header.navigation']));

      // The header block should originate from the base template.
      final headerBlock = resolvedBlocks['header'];
      expect(headerBlock, isNotNull);
      expect(headerBlock!.source, equals('base.liquid'));
      expect(headerBlock.nestedBlocks, isNotEmpty);
      expect(headerBlock.nestedBlocks, contains('navigation'));

      // The nested "navigation" block (as "header.navigation") should be overridden by the child.
      final navigationBlock = resolvedBlocks['header.navigation'];
      expect(navigationBlock, isNotNull);
      expect(navigationBlock!.source, equals('child.liquid'));
      expect(navigationBlock.isOverride, isTrue);
    });
  });
}
