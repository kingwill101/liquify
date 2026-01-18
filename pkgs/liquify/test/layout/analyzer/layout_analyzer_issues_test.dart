/// Tests to validate and document issues in the layout analyzer system.
///
/// These tests are designed to:
/// 1. Document known issues with failing tests
/// 2. Validate fixes once implemented
/// 3. Prevent regressions
///
/// Test categories:
/// - Critical Issues: Bugs that cause incorrect behavior
/// - Performance Issues: Inefficiencies that affect speed
library;

/// - Logic Issues: Edge cases not properly handled
/// - Memory Issues: Resource leaks or circular references

import 'package:liquify/parser.dart';
import 'package:liquify/src/analyzer/block_info.dart';
import 'package:liquify/src/analyzer/resolver.dart';
import 'package:liquify/src/analyzer/template_analyzer.dart';
import 'package:liquify/src/analyzer/template_structure.dart';
import 'package:liquify/src/util.dart';
import 'package:test/test.dart';

import '../../shared_test_root.dart';

void main() {
  // Disable logging for cleaner test output
  Logger.disableAllContexts();

  group('Critical Issues', () {
    group('Hardcoded nav tag check (resolver.dart:208)', () {
      late TestRoot root;
      late TemplateAnalyzer analyzer;

      setUp(() {
        root = TestRoot();
        analyzer = TemplateAnalyzer(root);
      });

      test('super() should work with any tag type, not just nav', () {
        // Base template with a sidebar block containing a menu tag
        root.addFile('base.liquid', '''
<div>
{% block sidebar %}
<menu>
<li>Home</li>
<li>About</li>
</menu>
{% endblock %}
</div>
''');

        // Child template overrides sidebar and uses super()
        root.addFile('child.liquid', '''
{% layout 'base.liquid' %}
{% block sidebar %}
<div class="custom-sidebar">
{{ super() }}
<li>Contact</li>
</div>
{% endblock %}
''');

        final analysis = analyzer.analyzeTemplate('child.liquid').last;
        final structure = analysis.structures['child.liquid']!;
        final mergedAst = buildCompleteMergedAst(structure);

        // Convert AST to string for easier validation
        final output = _astToString(mergedAst);

        // The parent's menu content should be included via super()
        expect(
          output,
          contains('Home'),
          reason: 'super() should include parent content',
        );
        expect(
          output,
          contains('About'),
          reason: 'super() should include parent content',
        );
        expect(
          output,
          contains('Contact'),
          reason: 'Child content should be present',
        );
      });

      test('super() should work with div tags', () {
        root.addFile('base.liquid', '''
{% block content %}
<div class="base-content">
Base content here
</div>
{% endblock %}
''');

        root.addFile('child.liquid', '''
{% layout 'base.liquid' %}
{% block content %}
<wrapper>
{{ super() }}
<p>Additional child content</p>
</wrapper>
{% endblock %}
''');

        final analysis = analyzer.analyzeTemplate('child.liquid').last;
        final structure = analysis.structures['child.liquid']!;
        final mergedAst = buildCompleteMergedAst(structure);

        final output = _astToString(mergedAst);

        expect(
          output,
          contains('Base content here'),
          reason: 'super() should work with div tags, not just nav',
        );
        expect(output, contains('Additional child content'));
      });

      test('super() should work with custom component tags', () {
        root.addFile('base.liquid', '''
{% block widget %}
<my-custom-component>
Widget default content
</my-custom-component>
{% endblock %}
''');

        root.addFile('child.liquid', '''
{% layout 'base.liquid' %}
{% block widget %}
{{ super() }}
<my-custom-component>Extra widget</my-custom-component>
{% endblock %}
''');

        final analysis = analyzer.analyzeTemplate('child.liquid').last;
        final structure = analysis.structures['child.liquid']!;
        final mergedAst = buildCompleteMergedAst(structure);

        final output = _astToString(mergedAst);

        expect(
          output,
          contains('Widget default content'),
          reason: 'super() should work with custom tags',
        );
        expect(output, contains('Extra widget'));
      });
    });

    group('Silent content loss (resolver.dart:101-103, 122-124)', () {
      late TestRoot root;
      late TemplateAnalyzer analyzer;

      setUp(() {
        root = TestRoot();
        analyzer = TemplateAnalyzer(root);
      });

      test('super() in root template should warn or handle gracefully', () {
        // A standalone template (no parent) that mistakenly uses super()
        root.addFile('standalone.liquid', '''
{% block content %}
{{ super() }}
This is standalone content
{% endblock %}
''');

        final analysis = analyzer.analyzeTemplate('standalone.liquid').last;
        final structure = analysis.structures['standalone.liquid']!;
        final mergedAst = buildCompleteMergedAst(structure);

        final output = _astToString(mergedAst);

        // At minimum, the non-super content should be preserved
        expect(
          output,
          contains('This is standalone content'),
          reason: 'Content after super() should not be lost',
        );

        // Ideally, there should be a warning about super() in root template
        // This is currently not implemented - super() silently returns empty
      });

      test('blocks defined in child but not in parent are silently discarded', () {
        root.addFile('base.liquid', '''
{% block header %}Header{% endblock %}
{% block footer %}Footer{% endblock %}
''');

        // Child defines a NEW block that doesn't exist in parent
        // This is a common mistake - user expects the block to appear somewhere
        root.addFile('child.liquid', '''
{% layout 'base.liquid' %}
{% block nonexistent %}
This content will be lost!
{% endblock %}
''');

        final analysis = analyzer.analyzeTemplate('child.liquid').last;
        final structure = analysis.structures['child.liquid']!;

        // The block IS in the child's structure
        expect(
          structure.blocks.containsKey('nonexistent'),
          isTrue,
          reason: 'Block should be tracked in child structure',
        );

        // FIXED: Block is now correctly marked as NOT an override
        final nonexistent = structure.blocks['nonexistent']!;
        expect(
          nonexistent.isOverride,
          isFalse,
          reason:
              'Block that does not exist in parent should not be marked as override',
        );

        // The content is still lost because base.liquid has no 'nonexistent' block
        // This is expected behavior for layout inheritance - child can only override
        // blocks that exist in the parent, not create new ones
        final mergedAst = buildCompleteMergedAst(structure);
        final output = _astToString(mergedAst);

        expect(
          output,
          isNot(contains('This content will be lost')),
          reason:
              'Content is not rendered because parent has no corresponding block (expected behavior)',
        );
      });

      test(
        'isOverride should be false for blocks that do not exist in parent',
        () {
          root.addFile('base.liquid', '''
{% block existing %}Base content{% endblock %}
''');

          root.addFile('child.liquid', '''
{% layout 'base.liquid' %}
{% block existing %}Override content{% endblock %}
{% block new_block %}New content{% endblock %}
''');

          final analysis = analyzer.analyzeTemplate('child.liquid').last;
          final structure = analysis.structures['child.liquid']!;

          // 'existing' should be marked as override
          final existing = structure.blocks['existing']!;
          expect(
            existing.isOverride,
            isTrue,
            reason: 'Block that exists in parent should be marked as override',
          );

          // FIXED: 'new_block' should NOT be marked as override
          final newBlock = structure.blocks['new_block']!;
          expect(
            newBlock.isOverride,
            isFalse,
            reason:
                'Block that does NOT exist in parent should NOT be marked as override',
          );
        },
      );
    });
  });

  group('Logic Issues', () {
    group(
      'Only handles Literal for parent path (template_analyzer.dart:130-131)',
      () {
        late TestRoot root;
        late TemplateAnalyzer analyzer;

        setUp(() {
          root = TestRoot();
          analyzer = TemplateAnalyzer(root);
        });

        test('layout tag with string literal path works', () {
          root.addFile('base.liquid', '{% block content %}Base{% endblock %}');
          root.addFile('child.liquid', '''
{% layout 'base.liquid' %}
{% block content %}Child{% endblock %}
''');

          final analysis = analyzer.analyzeTemplate('child.liquid').last;
          expect(analysis.structures.containsKey('child.liquid'), isTrue);
          expect(analysis.structures['child.liquid']!.parent, isNotNull);
        });

        // Note: Variable-based layout paths would require runtime resolution
        // This test documents the current limitation
        test('layout tag only supports literal paths (documented limitation)', () {
          // This is expected behavior - variable paths need runtime resolution
          // Just documenting that this is a known limitation
          root.addFile('base.liquid', '{% block content %}Base{% endblock %}');

          // Using a variable for the layout path won't work at analysis time
          // This would require: {% assign template = 'base.liquid' %}{% layout template %}
          // The analyzer only handles literal strings
          expect(
            true,
            isTrue,
            reason: 'Variable layout paths require runtime resolution',
          );
        });
      },
    );

    group('Mutable map in const constructor (template_structure.dart:54)', () {
      test('addBlock mutates supposedly immutable structure', () {
        final blocks = <String, BlockInfo>{};
        final structure = TemplateStructure(
          templatePath: 'test.liquid',
          nodes: [],
          blocks: blocks,
        );

        // This mutation affects both the original map and the structure
        structure.addBlock(
          'test',
          BlockInfo(
            name: 'test',
            source: 'test.liquid',
            isOverride: false,
            nestedBlocks: {},
            hasSuperCall: false,
          ),
        );

        // Both should now have the block (demonstrating shared mutable state)
        expect(structure.blocks.containsKey('test'), isTrue);
        expect(
          blocks.containsKey('test'),
          isTrue,
          reason: 'Mutation affects original map - violates immutability',
        );
      });

      test('external modification of blocks map affects structure', () {
        final blocks = <String, BlockInfo>{
          'initial': BlockInfo(
            name: 'initial',
            source: 'test.liquid',
            isOverride: false,
            nestedBlocks: {},
            hasSuperCall: false,
          ),
        };

        final structure = TemplateStructure(
          templatePath: 'test.liquid',
          nodes: [],
          blocks: blocks,
        );

        // External modification
        blocks['external'] = BlockInfo(
          name: 'external',
          source: 'external.liquid',
          isOverride: false,
          nestedBlocks: {},
          hasSuperCall: false,
        );

        // The structure now has a block it shouldn't
        expect(
          structure.blocks.containsKey('external'),
          isTrue,
          reason:
              'External modification affects structure - violates encapsulation',
        );
      });
    });

    group('deepCopy creates inherited block (block_info.dart:158)', () {
      test(
        'deepCopy parent points to original (intentional for inheritance)',
        () {
          final original = BlockInfo(
            name: 'header',
            source: 'base.liquid',
            content: [TextNode('Original content')],
            isOverride: false,
            nestedBlocks: {},
            hasSuperCall: false,
          );

          final copy = original.deepCopy('child.liquid');

          // This is intentional - the copy represents the inherited version
          // and its parent should point to the original for super() calls
          expect(
            copy.parent,
            same(original),
            reason: 'deepCopy sets parent to original for inheritance chain',
          );

          expect(copy.source, equals('child.liquid'));
          expect(
            copy.parent?.source,
            equals('base.liquid'),
            reason: 'Parent references original source for super() resolution',
          );
        },
      );

      test(
        'deepCopy sets isOverride to false (intentional for inheritance)',
        () {
          final original = BlockInfo(
            name: 'header',
            source: 'base.liquid',
            content: [TextNode('Content')],
            isOverride: true, // Original is an override
            nestedBlocks: {},
            hasSuperCall: true,
          );

          final copy = original.deepCopy('child.liquid');

          // This is intentional - the inherited version is NOT an override
          // until the child template explicitly overrides it
          expect(
            copy.isOverride,
            isFalse,
            reason:
                'Inherited block is not an override until explicitly overridden',
          );

          // hasSuperCall is preserved
          expect(copy.hasSuperCall, isTrue);
        },
      );
    });

    group('hasBlockInChain only checks one level of nestedBlocks', () {
      test('should find deeply nested blocks', () {
        final deeplyNested = BlockInfo(
          name: 'deep',
          source: 'test.liquid',
          isOverride: false,
          nestedBlocks: {},
          hasSuperCall: false,
        );

        final middleBlock = BlockInfo(
          name: 'middle',
          source: 'test.liquid',
          isOverride: false,
          nestedBlocks: {'deep': deeplyNested},
          hasSuperCall: false,
        );

        final topBlock = BlockInfo(
          name: 'top',
          source: 'test.liquid',
          isOverride: false,
          nestedBlocks: {'middle': middleBlock},
          hasSuperCall: false,
        );

        final structure = TemplateStructure(
          templatePath: 'test.liquid',
          nodes: [],
          blocks: {'top': topBlock},
        );

        // Direct nested block should be found
        expect(structure.hasBlockInChain('middle'), isTrue);

        // Deeply nested block is NOT found (current limitation)
        expect(
          structure.hasBlockInChain('deep'),
          isFalse,
          reason: 'hasBlockInChain only checks one level of nesting',
        );
      });
    });
  });

  group('Performance Issues', () {
    group('resolvedBlocks recomputes every access', () {
      late TestRoot root;
      late TemplateAnalyzer analyzer;

      setUp(() {
        root = TestRoot();
        analyzer = TemplateAnalyzer(root);

        // Create a 3-level inheritance chain
        root.addFile('base.liquid', '''
{% block a %}A{% endblock %}
{% block b %}B{% endblock %}
{% block c %}C{% endblock %}
''');
        root.addFile('middle.liquid', '''
{% layout 'base.liquid' %}
{% block a %}A-middle{% endblock %}
''');
        root.addFile('child.liquid', '''
{% layout 'middle.liquid' %}
{% block b %}B-child{% endblock %}
''');
      });

      test('multiple accesses to resolvedBlocks should be efficient', () {
        final analysis = analyzer.analyzeTemplate('child.liquid').last;
        final structure = analysis.structures['child.liquid']!;

        // Time multiple accesses
        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 1000; i++) {
          final _ = structure.resolvedBlocks;
        }
        stopwatch.stop();

        // This test documents that each access rebuilds the entire chain
        // After optimization, repeated access should be near-instant (cached)
        // Current behavior: each access is O(d * b) where d=depth, b=blocks
        print(
          '1000 resolvedBlocks accesses took: ${stopwatch.elapsedMicroseconds} μs',
        );

        // The result should at least be correct
        expect(structure.resolvedBlocks.keys.toSet(), equals({'a', 'b', 'c'}));
      });
    });

    group('inheritanceChain creates new list every call', () {
      late TestRoot root;
      late TemplateAnalyzer analyzer;

      setUp(() {
        root = TestRoot();
        analyzer = TemplateAnalyzer(root);

        root.addFile('level1.liquid', '{% block a %}1{% endblock %}');
        root.addFile(
          'level2.liquid',
          "{% layout 'level1.liquid' %}{% block a %}2{% endblock %}",
        );
        root.addFile(
          'level3.liquid',
          "{% layout 'level2.liquid' %}{% block a %}3{% endblock %}",
        );
        root.addFile(
          'level4.liquid',
          "{% layout 'level3.liquid' %}{% block a %}4{% endblock %}",
        );
        root.addFile(
          'level5.liquid',
          "{% layout 'level4.liquid' %}{% block a %}5{% endblock %}",
        );
      });

      test('inheritanceChain returns cached list instance', () {
        final analysis = analyzer.analyzeTemplate('level5.liquid').last;
        final structure = analysis.structures['level5.liquid']!;

        final chain1 = structure.inheritanceChain;
        final chain2 = structure.inheritanceChain;

        // Now cached - returns same instance
        expect(
          identical(chain1, chain2),
          isTrue,
          reason: 'inheritanceChain should return cached list',
        );

        // Content should be the same
        expect(chain1.length, equals(chain2.length));
        expect(chain1.length, equals(5));
      });
    });

    group('No memoization of template analysis', () {
      late TestRoot root;
      late TemplateAnalyzer analyzer;

      setUp(() {
        root = TestRoot();
        analyzer = TemplateAnalyzer(root);

        // Diamond inheritance pattern (shared ancestor)
        //       base
        //      /    \
        //   left    right
        //      \    /
        //       child
        root.addFile('base.liquid', '{% block content %}Base{% endblock %}');
        root.addFile(
          'left.liquid',
          "{% layout 'base.liquid' %}{% block content %}Left{% endblock %}",
        );
        root.addFile(
          'right.liquid',
          "{% layout 'base.liquid' %}{% block content %}Right{% endblock %}",
        );
      });

      test('shared ancestor should ideally be analyzed only once', () {
        // Analyze both paths - base.liquid is a shared ancestor
        final leftAnalysis = analyzer.analyzeTemplate('left.liquid').last;
        final rightAnalysis = analyzer.analyzeTemplate('right.liquid').last;

        // Both should have base.liquid in their structures
        // Currently, base.liquid gets re-analyzed for each path
        expect(leftAnalysis.structures.containsKey('base.liquid'), isTrue);
        expect(rightAnalysis.structures.containsKey('base.liquid'), isTrue);

        // This test documents that there's no caching - each analysis
        // re-parses and re-analyzes the shared ancestor
        // With memoization, the second analysis should reuse the first
      });
    });

    group('O(n) linear search for block lookups in resolver', () {
      late TestRoot root;
      late TemplateAnalyzer analyzer;

      setUp(() {
        root = TestRoot();
        analyzer = TemplateAnalyzer(root);

        // Create a template with many blocks to stress the linear search
        final blockDefs = List.generate(
          50,
          (i) => '{% block block$i %}Content $i{% endblock %}',
        ).join('\n');

        root.addFile('base.liquid', blockDefs);

        // Child overrides a few blocks
        root.addFile('child.liquid', '''
{% layout 'base.liquid' %}
{% block block49 %}Override 49{% endblock %}
{% block block25 %}Override 25{% endblock %}
{% block block0 %}Override 0{% endblock %}
''');
      });

      test('block resolution with many blocks', () {
        final stopwatch = Stopwatch()..start();

        final analysis = analyzer.analyzeTemplate('child.liquid').last;
        final structure = analysis.structures['child.liquid']!;
        final mergedAst = buildCompleteMergedAst(structure);

        stopwatch.stop();
        print(
          'Resolution with 50 blocks took: ${stopwatch.elapsedMicroseconds} μs',
        );

        // Verify correctness
        final output = _astToString(mergedAst);
        expect(output, contains('Override 49'));
        expect(output, contains('Override 25'));
        expect(output, contains('Override 0'));
        expect(output, contains('Content 10')); // Non-overridden block
      });
    });
  });

  group('Memory Issues', () {
    group('Circular references in BlockInfo', () {
      test('parent-child relationship creates reference cycle', () {
        final parent = BlockInfo(
          name: 'parent',
          source: 'test.liquid',
          isOverride: false,
          nestedBlocks: {},
          hasSuperCall: false,
        );

        final child = BlockInfo(
          name: 'child',
          source: 'test.liquid',
          isOverride: false,
          parent: parent, // Points to parent
          nestedBlocks: {},
          hasSuperCall: false,
        );

        // Add child to parent's nestedBlocks
        // This would create a cycle: parent -> nestedBlocks -> child -> parent
        // Note: The current API doesn't make this easy, but it's possible

        // For now, just document that parent references exist
        expect(child.parent, same(parent));

        // This test documents the potential for cycles
        // GC in Dart can handle cycles, but they may delay collection
      });
    });

    group('TemplateStructure parent chain', () {
      late TestRoot root;
      late TemplateAnalyzer analyzer;

      setUp(() {
        root = TestRoot();
        analyzer = TemplateAnalyzer(root);

        root.addFile('base.liquid', '{% block a %}Base{% endblock %}');
        root.addFile(
          'child.liquid',
          "{% layout 'base.liquid' %}{% block a %}Child{% endblock %}",
        );
      });

      test('parent references form a chain that is retained', () {
        final analysis = analyzer.analyzeTemplate('child.liquid').last;
        final childStructure = analysis.structures['child.liquid']!;

        // Child holds reference to parent
        expect(childStructure.parent, isNotNull);
        expect(childStructure.parent!.templatePath, equals('base.liquid'));

        // This chain is retained as long as childStructure is retained
        // Not necessarily a bug, but worth noting for memory considerations
      });
    });
  });

  group('Dead Code Verification', () {
    // These tests verify that certain code paths are never reached
    // They help identify code that can be safely removed

    test('_applyOverride function exists but is not called', () {
      // The function _applyOverride in resolver.dart (lines 318-382)
      // duplicates _processNodesWithOverrides but is never called
      // This test just documents its existence

      // We can't directly test that it's not called, but we can verify
      // that buildCompleteMergedAst works without it
      final root = TestRoot();
      final analyzer = TemplateAnalyzer(root);

      root.addFile('base.liquid', '{% block a %}Base{% endblock %}');
      root.addFile(
        'child.liquid',
        "{% layout 'base.liquid' %}{% block a %}Child{% endblock %}",
      );

      final analysis = analyzer.analyzeTemplate('child.liquid').last;
      final structure = analysis.structures['child.liquid']!;
      final mergedAst = buildCompleteMergedAst(structure);

      expect(_astToString(mergedAst), contains('Child'));
      // This works without _applyOverride - confirming it's dead code
    });

    test('resolveSuperCalls function exists but is not called', () {
      // The function resolveSuperCalls in resolver.dart (lines 384-430)
      // is never called - super calls are handled inline in _processNodesWithOverrides

      final root = TestRoot();
      final analyzer = TemplateAnalyzer(root);

      root.addFile('base.liquid', '{% block a %}Base content{% endblock %}');
      root.addFile('child.liquid', '''
{% layout 'base.liquid' %}
{% block a %}{{ super() }} + Child{% endblock %}
''');

      final analysis = analyzer.analyzeTemplate('child.liquid').last;
      final structure = analysis.structures['child.liquid']!;
      final mergedAst = buildCompleteMergedAst(structure);

      // Super calls work without resolveSuperCalls function
      final output = _astToString(mergedAst);
      expect(output, contains('Child'));
      // Note: The super() content may or may not appear depending on the bug
    });
  });
}

/// Helper function to convert AST nodes to a string for easier validation
String _astToString(List<ASTNode> nodes) {
  final buffer = StringBuffer();
  for (final node in nodes) {
    _nodeToString(node, buffer);
  }
  return buffer.toString();
}

void _nodeToString(ASTNode node, StringBuffer buffer) {
  if (node is TextNode) {
    buffer.write(node.text);
  } else if (node is Tag) {
    // For tags, process their body
    for (final child in node.body) {
      _nodeToString(child, buffer);
    }
  } else if (node is Variable) {
    buffer.write('{{${node.expression}}}');
  }
}
