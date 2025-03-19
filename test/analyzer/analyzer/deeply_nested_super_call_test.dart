// File: test/analyzer/deeply_nested_super_call_test.dart
import 'package:liquify/parser.dart';
import 'package:liquify/src/analyzer/template_analyzer.dart';
import 'package:liquify/src/util.dart';
import 'package:test/test.dart';

import '../../shared_test_root.dart';

void main() {
  group('Deeply Nested Super Call', () {
    late TestRoot root;
    late TemplateAnalyzer analyzer;

    setUp(() {
      // Configure logging - enable only analyzer logs
      Logger.disableAllContexts();
      // Logger.enableContext('Analyzer');
      root = TestRoot();
      analyzer = TemplateAnalyzer(root);

      // Grandparent template: defines "header" with a nested "navigation" block.
      root.addFile('grandparent.liquid', '''
        {% block header %}
          <div class="header">
            {% block navigation %}
              <ul>
                <li>Grandparent Nav</li>
              </ul>
            {% endblock %}
          </div>
        {% endblock %}
      ''');

      // Parent template: extends grandparent and overrides the nested "navigation" block.
      root.addFile('parent.liquid', '''
        {% layout 'grandparent.liquid' %}
        {% block navigation %}
          <ul>
            <li>Parent Nav</li>
          </ul>
        {% endblock %}
      ''');

      // Child template: extends parent and overrides the nested "navigation" block calling super().
      root.addFile('child.liquid', '''
        {% layout 'parent.liquid' %}
        {% block navigation %}
          <ul>
            <li>Child Nav Before</li>
            {{ super() }}
            <li>Child Nav After</li>
          </ul>
        {% endblock %}
      ''');
    });

    test('merges deeply nested super calls', () async {
      final analysis = analyzer.analyzeTemplate('child.liquid').last;
      final childStructure = analysis.structures['child.liquid']!;
      final resolvedBlocks = childStructure.resolvedBlocks;

      // Since "navigation" is originally nested in "header", the final key for the overridden block is "header.navigation".
      final navBlock = resolvedBlocks['header.navigation'];
      expect(navBlock, isNotNull,
          reason: 'header.navigation block should be present.');
      expect(navBlock!.source, equals('child.liquid'),
          reason: 'Child override should be used for the nested block.');
      expect(navBlock.isOverride, isTrue,
          reason: 'The nested block override must be marked as an override.');
      expect(navBlock.hasSuperCall, isTrue,
          reason: 'The nested block should detect a super() call.');

      // Verify that the nested block's parent is set and comes from parent.liquid.
      expect(navBlock.parent, isNotNull,
          reason: 'The deeply nested override should have a parent block.');
      expect(navBlock.parent!.source, equals('parent.liquid'),
          reason:
              'The parent block for the nested override should be from parent.liquid.');

      // Additionally, check that at least one node in the block's content is a Tag named "super".
      bool foundSuper =
          (navBlock.content ?? []).any((n) => n is Tag && n.name == 'super');
      expect(foundSuper, isTrue,
          reason:
              'The deeply nested block content should include a super() call tag.');
    });
  });
}
