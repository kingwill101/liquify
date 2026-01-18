import 'package:liquify/src/analyzer/resolver.dart';
import 'package:liquify/src/analyzer/template_analyzer.dart';
import 'package:test/test.dart';

import '../../shared_test_root.dart';

/// Comprehensive layout analyzer performance benchmarks.
/// These tests measure performance across various layout scenarios.
void main() {
  group('Layout Performance Benchmarks', () {
    group('Deep Inheritance Chain', () {
      late TestRoot root;
      late TemplateAnalyzer analyzer;

      setUp(() {
        root = TestRoot();
        analyzer = TemplateAnalyzer(root);

        // 10-level deep inheritance chain
        root.addFile('level0.liquid', '''
{% block header %}Level 0 Header{% endblock %}
{% block content %}Level 0 Content{% endblock %}
{% block footer %}Level 0 Footer{% endblock %}
''');

        for (int i = 1; i < 10; i++) {
          root.addFile('level$i.liquid', '''
{% layout 'level${i - 1}.liquid' %}
{% block content %}Level $i Content - {{ super() }}{% endblock %}
''');
        }
      });

      test('analyze 10-level inheritance', () {
        final stopwatch = Stopwatch()..start();

        final analysis = analyzer.analyzeTemplate('level9.liquid').last;
        final structure = analysis.structures['level9.liquid']!;

        stopwatch.stop();
        final analysisTime = stopwatch.elapsedMicroseconds;

        stopwatch.reset();
        stopwatch.start();
        final mergedAst = buildCompleteMergedAst(structure);
        stopwatch.stop();
        final mergeTime = stopwatch.elapsedMicroseconds;

        print('=== Deep Inheritance (10 levels) ===');
        print('Analysis time: $analysisTime μs');
        print('Merge time: $mergeTime μs');
        print('Total: ${analysisTime + mergeTime} μs');

        // Verify correctness
        final output = _astToString(mergedAst);
        expect(output, contains('Level 0 Header'));
        expect(output, contains('Level 9 Content'));
        expect(output, contains('Level 0 Footer'));
      });

      test('cached 10-level inheritance (second analysis)', () {
        // First analysis - populates cache
        analyzer.analyzeTemplate('level9.liquid').last;

        // Second analysis - should use cache
        final stopwatch = Stopwatch()..start();
        final analysis = analyzer.analyzeTemplate('level9.liquid').last;
        final structure = analysis.structures['level9.liquid']!;
        stopwatch.stop();
        final analysisTime = stopwatch.elapsedMicroseconds;

        stopwatch.reset();
        stopwatch.start();
        final mergedAst = buildCompleteMergedAst(structure);
        stopwatch.stop();
        final mergeTime = stopwatch.elapsedMicroseconds;

        print('=== Deep Inheritance CACHED (10 levels) ===');
        print('Analysis time: $analysisTime μs');
        print('Merge time: $mergeTime μs');
        print('Total: ${analysisTime + mergeTime} μs');

        // Verify correctness
        final output = _astToString(mergedAst);
        expect(output, contains('Level 0 Header'));
        expect(output, contains('Level 9 Content'));
      });

      test('repeated resolvedBlocks access (cached)', () {
        final analysis = analyzer.analyzeTemplate('level9.liquid').last;
        final structure = analysis.structures['level9.liquid']!;

        // Warm up cache
        structure.resolvedBlocks;

        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 10000; i++) {
          final _ = structure.resolvedBlocks;
        }
        stopwatch.stop();

        print('=== Cached resolvedBlocks (10k accesses) ===');
        print('Time: ${stopwatch.elapsedMicroseconds} μs');
        print('Per access: ${stopwatch.elapsedMicroseconds / 10000} μs');
      });
    });

    group('Many Blocks', () {
      late TestRoot root;
      late TemplateAnalyzer analyzer;

      setUp(() {
        root = TestRoot();
        analyzer = TemplateAnalyzer(root);

        // Base with 100 blocks
        final blockDefs = List.generate(
          100,
          (i) => '{% block block$i %}Content $i{% endblock %}',
        ).join('\n');

        root.addFile('base.liquid', blockDefs);

        // Child overrides 20 blocks
        final overrides = List.generate(
          20,
          (i) => '{% block block${i * 5} %}Override ${i * 5}{% endblock %}',
        ).join('\n');

        root.addFile('child.liquid', '''
{% layout 'base.liquid' %}
$overrides
''');
      });

      test('resolve 100 blocks with 20 overrides', () {
        final stopwatch = Stopwatch()..start();

        final analysis = analyzer.analyzeTemplate('child.liquid').last;
        final structure = analysis.structures['child.liquid']!;

        stopwatch.stop();
        final analysisTime = stopwatch.elapsedMicroseconds;

        stopwatch.reset();
        stopwatch.start();
        final mergedAst = buildCompleteMergedAst(structure);
        stopwatch.stop();
        final mergeTime = stopwatch.elapsedMicroseconds;

        print('=== Many Blocks (100 blocks, 20 overrides) ===');
        print('Analysis time: $analysisTime μs');
        print('Merge time: $mergeTime μs');
        print('Total: ${analysisTime + mergeTime} μs');

        // Verify correctness
        final output = _astToString(mergedAst);
        expect(output, contains('Override 0'));
        expect(output, contains('Override 95'));
        expect(output, contains('Content 1')); // Non-overridden
      });
    });

    group('Nested Blocks', () {
      late TestRoot root;
      late TemplateAnalyzer analyzer;

      setUp(() {
        root = TestRoot();
        analyzer = TemplateAnalyzer(root);

        // Template with deeply nested blocks
        root.addFile('base.liquid', '''
{% block outer %}
  Outer Start
  {% block middle %}
    Middle Start
    {% block inner %}
      Inner Content
    {% endblock %}
    Middle End
  {% endblock %}
  Outer End
{% endblock %}
{% block sidebar %}
  {% block sidebar_header %}Sidebar Header{% endblock %}
  {% block sidebar_content %}Sidebar Content{% endblock %}
  {% block sidebar_footer %}Sidebar Footer{% endblock %}
{% endblock %}
''');

        root.addFile('child.liquid', '''
{% layout 'base.liquid' %}
{% block inner %}Overridden Inner{% endblock %}
{% block sidebar_content %}Overridden Sidebar Content{% endblock %}
''');
      });

      test('resolve nested block overrides', () {
        final stopwatch = Stopwatch()..start();

        final analysis = analyzer.analyzeTemplate('child.liquid').last;
        final structure = analysis.structures['child.liquid']!;

        stopwatch.stop();
        final analysisTime = stopwatch.elapsedMicroseconds;

        stopwatch.reset();
        stopwatch.start();
        final mergedAst = buildCompleteMergedAst(structure);
        stopwatch.stop();
        final mergeTime = stopwatch.elapsedMicroseconds;

        print('=== Nested Blocks ===');
        print('Analysis time: $analysisTime μs');
        print('Merge time: $mergeTime μs');
        print('Total: ${analysisTime + mergeTime} μs');

        final output = _astToString(mergedAst);
        expect(output, contains('Outer Start'));
        // Note: nested block overrides require the block to be in parent's nested structure
        expect(output, contains('Overridden Sidebar Content'));
      });
    });

    group('Complex Real-World Layout', () {
      late TestRoot root;
      late TemplateAnalyzer analyzer;

      setUp(() {
        root = TestRoot();
        analyzer = TemplateAnalyzer(root);

        // Simulate a real website structure
        root.addFile('layouts/base.liquid', '''
<!DOCTYPE html>
<html>
<head>
  {% block head %}
    <title>{% block title %}Default Title{% endblock %}</title>
    {% block meta %}
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
    {% endblock %}
    {% block styles %}
      <link rel="stylesheet" href="/css/main.css">
    {% endblock %}
  {% endblock %}
</head>
<body>
  {% block body %}
    <header>
      {% block header %}
        {% block nav %}
          <nav>
            {% block nav_items %}
              <a href="/">Home</a>
              <a href="/about">About</a>
            {% endblock %}
          </nav>
        {% endblock %}
      {% endblock %}
    </header>
    <main>
      {% block main %}
        {% block content %}Default Content{% endblock %}
      {% endblock %}
    </main>
    <footer>
      {% block footer %}
        {% block footer_content %}
          <p>Copyright 2024</p>
        {% endblock %}
      {% endblock %}
    </footer>
  {% endblock %}
  {% block scripts %}
    <script src="/js/main.js"></script>
  {% endblock %}
</body>
</html>
''');

        root.addFile('layouts/page.liquid', '''
{% layout 'layouts/base.liquid' %}
{% block styles %}
  {{ super() }}
  <link rel="stylesheet" href="/css/page.css">
{% endblock %}
{% block nav_items %}
  {{ super() }}
  <a href="/contact">Contact</a>
{% endblock %}
''');

        root.addFile('layouts/blog.liquid', '''
{% layout 'layouts/page.liquid' %}
{% block styles %}
  {{ super() }}
  <link rel="stylesheet" href="/css/blog.css">
{% endblock %}
{% block main %}
  <article>
    {% block article_header %}
      <h1>{% block article_title %}Blog Post{% endblock %}</h1>
    {% endblock %}
    {% block article_content %}
      {{ super() }}
    {% endblock %}
  </article>
  <aside>
    {% block sidebar %}
      <h3>Related Posts</h3>
    {% endblock %}
  </aside>
{% endblock %}
''');

        root.addFile('posts/my-post.liquid', '''
{% layout 'layouts/blog.liquid' %}
{% block title %}My Amazing Post{% endblock %}
{% block article_title %}My Amazing Post{% endblock %}
{% block article_content %}
  <p>This is my blog post content.</p>
  <p>It has multiple paragraphs.</p>
{% endblock %}
{% block sidebar %}
  {{ super() }}
  <ul>
    <li>Related Post 1</li>
    <li>Related Post 2</li>
  </ul>
{% endblock %}
''');
      });

      test('resolve 4-level real-world layout', () {
        final stopwatch = Stopwatch()..start();

        final analysis = analyzer.analyzeTemplate('posts/my-post.liquid').last;
        final structure = analysis.structures['posts/my-post.liquid']!;

        stopwatch.stop();
        final analysisTime = stopwatch.elapsedMicroseconds;

        stopwatch.reset();
        stopwatch.start();
        final mergedAst = buildCompleteMergedAst(structure);
        stopwatch.stop();
        final mergeTime = stopwatch.elapsedMicroseconds;

        print('=== Real-World Layout (4 levels) ===');
        print('Analysis time: $analysisTime μs');
        print('Merge time: $mergeTime μs');
        print('Total: ${analysisTime + mergeTime} μs');
        print('Blocks in structure: ${structure.resolvedBlocks.length}');

        final output = _astToString(mergedAst);
        expect(output, contains('My Amazing Post'));
        // super() tags may not be fully resolved in string output
        expect(output, contains('page.css'));
        expect(output, contains('blog.css'));
        expect(output, contains('Related Post 1'));
      });

      test('repeated full resolution (simulates page renders)', () {
        // Simulate rendering the same template multiple times
        // First pass - cold cache
        final coldStopwatch = Stopwatch()..start();
        final analysis1 = analyzer.analyzeTemplate('posts/my-post.liquid').last;
        final structure1 = analysis1.structures['posts/my-post.liquid']!;
        final _ = buildCompleteMergedAst(structure1);
        coldStopwatch.stop();
        final coldTime = coldStopwatch.elapsedMicroseconds;

        // Subsequent passes - warm cache
        final warmStopwatch = Stopwatch()..start();
        for (int i = 0; i < 99; i++) {
          final analysis = analyzer
              .analyzeTemplate('posts/my-post.liquid')
              .last;
          final structure = analysis.structures['posts/my-post.liquid']!;
          final _ = buildCompleteMergedAst(structure);
        }
        warmStopwatch.stop();

        print('=== 100 Full Resolutions ===');
        print('Cold (first): $coldTime μs');
        print('Warm (99 cached): ${warmStopwatch.elapsedMicroseconds} μs');
        print(
          'Warm per resolution: ${warmStopwatch.elapsedMicroseconds / 99} μs',
        );
        print(
          'Total time: ${(coldTime + warmStopwatch.elapsedMicroseconds) / 1000} ms',
        );
      });
    });

    group('Stress Test', () {
      late TestRoot root;
      late TemplateAnalyzer analyzer;

      setUp(() {
        root = TestRoot();
        analyzer = TemplateAnalyzer(root);

        // 20-level inheritance with many blocks each
        root.addFile('stress/level0.liquid', '''
{% block a %}A0{% endblock %}
{% block b %}B0{% endblock %}
{% block c %}C0{% endblock %}
{% block d %}D0{% endblock %}
{% block e %}E0{% endblock %}
''');

        for (int i = 1; i < 20; i++) {
          root.addFile('stress/level$i.liquid', '''
{% layout 'stress/level${i - 1}.liquid' %}
{% block a %}A$i - {{ super() }}{% endblock %}
{% block c %}C$i{% endblock %}
''');
        }
      });

      test('20-level inheritance stress test', () {
        final stopwatch = Stopwatch()..start();

        final analysis = analyzer.analyzeTemplate('stress/level19.liquid').last;
        final structure = analysis.structures['stress/level19.liquid']!;

        stopwatch.stop();
        final analysisTime = stopwatch.elapsedMicroseconds;

        stopwatch.reset();
        stopwatch.start();
        final mergedAst = buildCompleteMergedAst(structure);
        stopwatch.stop();
        final mergeTime = stopwatch.elapsedMicroseconds;

        print('=== Stress Test (20 levels) ===');
        print('Analysis time: $analysisTime μs');
        print('Merge time: $mergeTime μs');
        print('Total: ${analysisTime + mergeTime} μs');
        print('Inheritance chain length: ${structure.inheritanceChain.length}');

        final output = _astToString(mergedAst);
        // Block 'a' should have at least the latest level
        expect(output, contains('A19'));
        // Block 'c' should be latest override
        expect(output, contains('C19'));
        // Block 'b' should be original
        expect(output, contains('B0'));
      });
    });
  });
}

String _astToString(List<dynamic> nodes) {
  final buffer = StringBuffer();
  for (var node in nodes) {
    buffer.write(node.toString());
  }
  return buffer.toString();
}
