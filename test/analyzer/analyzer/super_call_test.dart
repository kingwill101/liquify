import 'package:liquify/parser.dart';
import 'package:liquify/src/analyzer/template_analyzer.dart';
import 'package:liquify/src/util.dart';
import 'package:test/test.dart';

import '../../shared_test_root.dart';

void main() {
  group('Super Call Analysis', () {
    late TestRoot root;
    late TemplateAnalyzer analyzer;

    setUp(() {
      // Configure logging - enable only analyzer logs
      Logger.disableAllContexts();
      // Logger.enableContext('Analyzer');
      root = TestRoot();
      analyzer = TemplateAnalyzer(root);

      // Base template defines a block with some content.
      root.addFile('base.liquid', '''
        {% block content %}
          <p>Base Content</p>
        {% endblock %}
      ''');

      // Child template overrides it and calls super().
      root.addFile('child.liquid', '''
        {% layout 'base.liquid' %}
        {% block content %}
          <div>Child Content Before</div>
          {{ super() }}
          <div>Child Content After</div>
        {% endblock %}
      ''');
    });

    test('merges parent block content with super()', () async {
      final analysis = analyzer.analyzeTemplate('child.liquid').last;
      final childStructure = analysis.structures['child.liquid']!;
      final resolvedBlocks = childStructure.resolvedBlocks;

      // For example, we expect the child template's "content" block
      // (possibly flattened as just "content" if no nesting is required)
      // to merge the child's and parent's content.
      final contentBlock = resolvedBlocks['content'];
      expect(contentBlock, isNotNull);
      expect(contentBlock!.source, equals('child.liquid'));

      // Verify that the block was detected as an override and contains a super() call.
      expect(contentBlock.hasSuperCall, isTrue);
      expect(contentBlock.isOverride, isTrue);
      expect(contentBlock.parent, isNotNull);
      expect(contentBlock.parent!.source, equals('base.liquid'));

      // Additionally, check that at least one node in the block's content is a Tag named "super".
      bool foundSuper = (contentBlock.content ?? [])
          .any((n) => n is Tag && n.name == 'super');
      expect(foundSuper, isTrue,
          reason: 'The block content should include a super() call tag.');

      // This test will eventually verify that the rendered output is:
      // "<div>Child Content Before</div><p>Base Content</p><div>Child Content After</div>"
      // Once your evaluator supports super().
    });
  });
}
