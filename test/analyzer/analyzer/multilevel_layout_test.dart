// File: test/analyzer/multilevel_layout_test.dart
import 'package:liquify/src/analyzer/template_analyzer.dart';
import 'package:liquify/src/util.dart';
import 'package:test/test.dart';

import '../../shared_test_root.dart';

void main() {
  group('Multi-Level Inheritance', () {
    late TestRoot root;
    late TemplateAnalyzer analyzer;

    setUp(() {
      // Configure logging - enable only analyzer logs
      Logger.disableAllContexts();
      // Logger.enableContext('Analyzer');
      root = TestRoot();
      analyzer = TemplateAnalyzer(root);

      // Grandparent template with base blocks.
      root.addFile('grandparent.liquid', '''
        {% block header %}
          <h1>Grandparent Header</h1>
        {% endblock %}
        {% block content %}
          <p>Grandparent Content</p>
        {% endblock %}
      ''');

      // Parent template that extends grandparent.
      root.addFile('parent.liquid', '''
         {% layout 'grandparent.liquid' %}
         {% block header %}
           <h1>Parent Header</h1>
         {% endblock %}
         {% block content %}
           <p>Parent Content</p>
         {% endblock %}
      ''');

      // Child template that extends parent.
      root.addFile('child.liquid', '''
         {% layout 'parent.liquid' %}
         {% block header %}
           <h1>Child Header</h1>
         {% endblock %}
         {% block footer %}
           <footer>Child Footer</footer>
         {% endblock %}
      ''');
    });

    test('analyzes multi-level inheritance', () async {
      final analysis = analyzer.analyzeTemplate('child.liquid').last;
      expect(analysis.structures.containsKey('child.liquid'), isTrue);

      final childStructure = analysis.structures['child.liquid']!;
      final resolvedBlocks = childStructure.resolvedBlocks;

      // Child header should override parent's (and inherit parent's parent).
      expect(resolvedBlocks['header'], isNotNull);
      expect(resolvedBlocks['header']!.source, equals('child.liquid'));
      expect(resolvedBlocks['header']!.isOverride, isTrue);

      // Parent content should be inherited because the child didn't override it.
      expect(resolvedBlocks['content'], isNotNull);
      // Depending on design, if the parent's block remains and is not overridden,
      // its source may still be 'parent.liquid'. In our current design, however,
      // a redefinition in the parent is marked as override in the child structure.
      // Adjust the expectation based on your intended behavior.
      expect(resolvedBlocks['content']!.source, equals('parent.liquid'));
      expect(resolvedBlocks['content']!.isOverride, isTrue);

      // The footer is defined only in the child.
      expect(resolvedBlocks['footer'], isNotNull);
      expect(resolvedBlocks['footer']!.source, equals('child.liquid'));
      expect(resolvedBlocks['footer']!.isOverride, isTrue);
    });
  });
}
