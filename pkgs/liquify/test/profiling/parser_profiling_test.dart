/// Parser Profiling Tests for Liquify
///
/// This file contains profiling tests to identify performance bottlenecks
/// in the Liquify Liquid template parser using PetitParser's profiling tools.
///
/// Run with: dart test test/profiling/parser_profiling_test.dart -r expanded
///
/// The profiling output shows:
/// - Activation count: How many times each parser was invoked
/// - Total time: Microseconds spent in each parser (including children)
///
/// Use this to identify:
/// - Parsers with excessive activations (potential inefficiencies)
/// - Parsers consuming disproportionate time (bottlenecks)
/// - Backtracking patterns that could be optimized
library;

import 'package:liquify/src/grammar/grammar.dart';
import 'package:liquify/src/grammar/shared.dart';
import 'package:liquify/src/registry.dart';
import 'package:petitparser/debug.dart';
import 'package:petitparser/reflection.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

// ============================================================================
// Grammar Wrappers for Sub-Parser Testing
// ============================================================================

/// Grammar wrapper that builds individual sub-parsers with resolved references.
/// This is necessary because sub-parsers like expression() use ref0() which
/// creates unresolved references that only work when built through a GrammarDefinition.

class ExpressionGrammar extends GrammarDefinition {
  @override
  Parser start() => ref0(expression).end();
}

class VariableGrammar extends GrammarDefinition {
  @override
  Parser start() => ref0(variable).end();
}

class FilterGrammar extends GrammarDefinition {
  @override
  Parser start() => ref0(filter).end();
}

class ComparisonGrammar extends GrammarDefinition {
  @override
  Parser start() => ref0(comparison).end();
}

class LogicalExpressionGrammar extends GrammarDefinition {
  @override
  Parser start() => ref0(logicalExpression).end();
}

class PrimaryTermGrammar extends GrammarDefinition {
  @override
  Parser start() => ref0(primaryTerm).end();
}

class IdentifierGrammar extends GrammarDefinition {
  @override
  Parser start() => ref0(identifier).end();
}

class ArithmeticExprGrammar extends GrammarDefinition {
  @override
  Parser start() => ref0(arithmeticExpr).end();
}

class ComparisonExprGrammar extends GrammarDefinition {
  @override
  Parser start() => ref0(comparisonExpr).end();
}

class LogicalExprGrammar extends GrammarDefinition {
  @override
  Parser start() => ref0(logicalExpr).end();
}

// ============================================================================
// Benchmark Templates
// ============================================================================

/// Simple templates for baseline measurements
class SimpleTemplates {
  static const helloWorld = 'Hello {{ name }}!';

  static const simpleVariable = '{{ user }}';

  static const variableWithFilter = '{{ name | upcase }}';

  static const multipleFilters =
      '{{ name | upcase | append: "!" | prepend: "Hello, " }}';

  static const simpleTag = '{% assign x = 5 %}';

  static const simpleIf = '{% if true %}yes{% endif %}';

  static const memberAccess = '{{ user.profile.name }}';

  static const arrayAccess = '{{ items[0] }}';
}

/// Medium complexity templates
class MediumTemplates {
  static const ifElse = '''
{% if user.logged_in %}
  <p>Welcome back, {{ user.name }}!</p>
{% else %}
  <p>Please log in.</p>
{% endif %}
''';

  static const nestedIf = '''
{% if user.logged_in %}
  {% if user.admin %}
    <p>Admin Panel</p>
  {% else %}
    <p>User Dashboard</p>
  {% endif %}
{% endif %}
''';

  static const forLoop = '''
{% for item in items %}
  <li>{{ item.name }} - {{ item.price | money }}</li>
{% endfor %}
''';

  static const forLoopWithElse = '''
{% for item in items %}
  <li>{{ item }}</li>
{% else %}
  <p>No items found.</p>
{% endfor %}
''';

  static const complexExpression = '''
{% if user.age >= 18 and user.verified == true or user.admin %}
  <p>Access granted</p>
{% endif %}
''';

  static const multipleAssignments = '''
{% assign greeting = "Hello" %}
{% assign name = user.first_name | capitalize %}
{% assign full_greeting = greeting | append: " " | append: name | append: "!" %}
{{ full_greeting }}
''';

  static const caseStatement = '''
{% case day %}
  {% when "Monday" %}
    <p>Start of the week</p>
  {% when "Friday" %}
    <p>Almost weekend!</p>
  {% else %}
    <p>Regular day</p>
{% endcase %}
''';
}

/// Complex templates for stress testing
class ComplexTemplates {
  /// Deeply nested if statements (10 levels)
  static String get deeplyNestedIf {
    final buffer = StringBuffer();
    for (var i = 0; i < 10; i++) {
      buffer.write('{% if level$i %}');
    }
    buffer.write('<p>Deep content</p>');
    for (var i = 9; i >= 0; i--) {
      buffer.write('{% endif %}');
    }
    return buffer.toString();
  }

  /// Long filter chain (15 filters)
  static const longFilterChain = '''
{{ text | strip | downcase | capitalize | prepend: "Hello " | append: "!" | split: " " | first | upcase | strip_html | escape | truncate: 10 | replace: "a", "b" | remove: "x" | strip_newlines | lstrip }}
''';

  /// Many variables (50 interpolations)
  static String get manyVariables {
    final buffer = StringBuffer();
    for (var i = 0; i < 50; i++) {
      buffer.write('{{ var$i }}');
    }
    return buffer.toString();
  }

  /// Complex member access chain
  static const deepMemberAccess = '''
{{ site.data.navigation.header.menu.items[0].submenu[1].link.url }}
''';

  /// Multiple nested loops
  static const nestedLoops = '''
{% for category in categories %}
  <h2>{{ category.name }}</h2>
  {% for product in category.products %}
    <div>
      {{ product.name }} - {{ product.price | money }}
      {% for tag in product.tags %}
        <span>{{ tag }}</span>
      {% endfor %}
    </div>
  {% endfor %}
{% endfor %}
''';

  /// Complex logical expressions
  static const complexLogical = '''
{% if (a == 1 and b == 2) or (c == 3 and d == 4) or not e %}
  {% if x > 10 and x < 20 or y contains "test" %}
    <p>Complex condition met</p>
  {% endif %}
{% endif %}
''';

  /// Real-world e-commerce template
  static const ecommerceTemplate = '''
{% if product.available %}
  <div class="product">
    <h1>{{ product.title | escape }}</h1>
    <p class="price">{{ product.price | money }}</p>
    
    {% if product.compare_at_price > product.price %}
      <p class="sale">Was: {{ product.compare_at_price | money }}</p>
    {% endif %}
    
    {% for variant in product.variants %}
      {% if variant.available %}
        <option value="{{ variant.id }}">
          {{ variant.title }} - {{ variant.price | money }}
        </option>
      {% endif %}
    {% endfor %}
    
    {% if product.tags contains "featured" %}
      <span class="badge">Featured</span>
    {% endif %}
    
    <div class="description">
      {{ product.description | strip_html | truncate: 200 }}
    </div>
  </div>
{% else %}
  <p>This product is currently unavailable.</p>
{% endif %}
''';

  /// Blog post template with multiple sections
  static const blogTemplate = '''
{% if post.published %}
  <article>
    <header>
      <h1>{{ post.title | escape }}</h1>
      <time>{{ post.date | date: "%B %d, %Y" }}</time>
      {% if post.author %}
        <span class="author">by {{ post.author.name }}</span>
      {% endif %}
    </header>
    
    {% if post.featured_image %}
      <img src="{{ post.featured_image | img_url: 'large' }}" alt="{{ post.title | escape }}">
    {% endif %}
    
    <div class="content">
      {{ post.content }}
    </div>
    
    {% if post.tags.size > 0 %}
      <div class="tags">
        {% for tag in post.tags %}
          <a href="/tags/{{ tag | handleize }}">{{ tag }}</a>
        {% endfor %}
      </div>
    {% endif %}
    
    {% if post.comments_enabled %}
      <section class="comments">
        {% for comment in post.comments %}
          <div class="comment">
            <strong>{{ comment.author }}</strong>
            <time>{{ comment.date | date: "%Y-%m-%d" }}</time>
            <p>{{ comment.body | escape }}</p>
          </div>
        {% endfor %}
      </section>
    {% endif %}
  </article>
{% endif %}
''';
}

// ============================================================================
// Profiling Utilities
// ============================================================================

/// Collected profile data for analysis
class ProfileData {
  final String parserName;
  final int activationCount;
  final int totalMicroseconds;

  ProfileData(this.parserName, this.activationCount, this.totalMicroseconds);

  @override
  String toString() =>
      '${activationCount.toString().padLeft(8)}  ${totalMicroseconds.toString().padLeft(10)}  $parserName';
}

/// Runs profiling on a parser and collects results
List<ProfileData> runProfile(Parser parser, String input) {
  final frames = <ProfileData>[];

  final profiledParser = profile(
    parser,
    output: (frame) {
      frames.add(
        ProfileData(
          frame.parser.toString(),
          frame.count,
          frame.elapsed.inMicroseconds,
        ),
      );
    },
  );

  profiledParser.parse(input);
  return frames;
}

/// Prints a formatted profiling report
void printProfilingReport(
  String name,
  String input,
  List<ProfileData> frames, {
  int topN = 15,
}) {
  print('\n${'=' * 70}');
  print('PROFILING: $name');
  print('${'=' * 70}');
  print('Input length: ${input.length} characters');
  print('Total parsers profiled: ${frames.length}');

  // Calculate totals
  final totalActivations = frames.fold<int>(
    0,
    (sum, f) => sum + f.activationCount,
  );
  final maxTime = frames.isEmpty
      ? 0
      : frames.map((f) => f.totalMicroseconds).reduce((a, b) => a > b ? a : b);

  print('Total activations: $totalActivations');
  print('Max parser time: $maxTime μs');
  print('');

  // Sort by time (descending) and show top N
  final byTime = List<ProfileData>.from(frames)
    ..sort((a, b) => b.totalMicroseconds.compareTo(a.totalMicroseconds));

  print('TOP $topN BY TIME (μs):');
  print('${'─' * 70}');
  print('${' ' * 2}Count${' ' * 5}Time(μs)  Parser');
  print('${'─' * 70}');
  for (var i = 0; i < topN && i < byTime.length; i++) {
    print(byTime[i]);
  }

  // Sort by activation count (descending) and show top N
  final byCount = List<ProfileData>.from(frames)
    ..sort((a, b) => b.activationCount.compareTo(a.activationCount));

  print('');
  print('TOP $topN BY ACTIVATION COUNT:');
  print('${'─' * 70}');
  print('${' ' * 2}Count${' ' * 5}Time(μs)  Parser');
  print('${'─' * 70}');
  for (var i = 0; i < topN && i < byCount.length; i++) {
    print(byCount[i]);
  }

  print('${'=' * 70}\n');
}

/// Runs progress tracking on a parser (shows backtracking)
void runProgress(Parser parser, String input, {int maxLines = 50}) {
  print('\n--- Progress (first $maxLines lines) ---');
  print('Input: "$input"');
  print('');
  var lineCount = 0;
  var lastPosition = -1;

  final progressParser = progress(
    parser,
    output: (frame) {
      if (lineCount < maxLines) {
        // Track position changes to identify backtracking
        final backtrackIndicator = frame.position < lastPosition
            ? ' <-- BACKTRACK'
            : '';
        print(
          'pos ${frame.position.toString().padLeft(4)}: ${frame.parser}$backtrackIndicator',
        );
        lastPosition = frame.position;
        lineCount++;
      }
    },
  );

  progressParser.parse(input);

  if (lineCount >= maxLines) {
    print('... (output truncated)');
  }
}

/// Runs the linter on a parser and reports issues
void runLinter(Parser parser) {
  print('\n--- Linter Results ---');
  final issues = linter(parser);
  if (issues.isEmpty) {
    print('No issues found.');
  } else {
    print('Found ${issues.length} issue(s):');
    for (final issue in issues) {
      print('  - $issue');
    }
  }
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  // Ensure built-ins are registered
  registerBuiltIns();

  group('Parser Profiling', () {
    late Parser documentParser;

    setUp(() {
      registerBuiltIns();
      documentParser = LiquidGrammar().build();
    });

    group('Simple Templates', () {
      test('Hello World', () {
        final input = SimpleTemplates.helloWorld;
        final frames = runProfile(documentParser, input);
        printProfilingReport('Hello World', input, frames);
        expect(frames, isNotEmpty);
      });

      test('Simple Variable', () {
        final input = SimpleTemplates.simpleVariable;
        final frames = runProfile(documentParser, input);
        printProfilingReport('Simple Variable', input, frames);
        expect(frames, isNotEmpty);
      });

      test('Variable with Filter', () {
        final input = SimpleTemplates.variableWithFilter;
        final frames = runProfile(documentParser, input);
        printProfilingReport('Variable with Filter', input, frames);
        expect(frames, isNotEmpty);
      });

      test('Multiple Filters', () {
        final input = SimpleTemplates.multipleFilters;
        final frames = runProfile(documentParser, input);
        printProfilingReport('Multiple Filters', input, frames);
        expect(frames, isNotEmpty);
      });

      test('Member Access', () {
        final input = SimpleTemplates.memberAccess;
        final frames = runProfile(documentParser, input);
        printProfilingReport('Member Access', input, frames);
        expect(frames, isNotEmpty);
      });
    });

    group('Medium Templates', () {
      test('If-Else Block', () {
        final input = MediumTemplates.ifElse;
        final frames = runProfile(documentParser, input);
        printProfilingReport('If-Else Block', input, frames);
        expect(frames, isNotEmpty);
      });

      test('Nested If', () {
        final input = MediumTemplates.nestedIf;
        final frames = runProfile(documentParser, input);
        printProfilingReport('Nested If', input, frames);
        expect(frames, isNotEmpty);
      });

      test('For Loop', () {
        final input = MediumTemplates.forLoop;
        final frames = runProfile(documentParser, input);
        printProfilingReport('For Loop', input, frames);
        expect(frames, isNotEmpty);
      });

      test('Complex Expression', () {
        final input = MediumTemplates.complexExpression;
        final frames = runProfile(documentParser, input);
        printProfilingReport('Complex Expression', input, frames);
        expect(frames, isNotEmpty);
      });

      test('Case Statement', () {
        final input = MediumTemplates.caseStatement;
        final frames = runProfile(documentParser, input);
        printProfilingReport('Case Statement', input, frames);
        expect(frames, isNotEmpty);
      });
    });

    group('Complex Templates (Stress Tests)', () {
      test('Deeply Nested If (10 levels)', () {
        final input = ComplexTemplates.deeplyNestedIf;
        final frames = runProfile(documentParser, input);
        printProfilingReport('Deeply Nested If (10 levels)', input, frames);
        expect(frames, isNotEmpty);
      });

      test('Long Filter Chain (15 filters)', () {
        final input = ComplexTemplates.longFilterChain;
        final frames = runProfile(documentParser, input);
        printProfilingReport('Long Filter Chain', input, frames);
        expect(frames, isNotEmpty);
      });

      test('Many Variables (50)', () {
        final input = ComplexTemplates.manyVariables;
        final frames = runProfile(documentParser, input);
        printProfilingReport('Many Variables (50)', input, frames);
        expect(frames, isNotEmpty);
      });

      test('Deep Member Access', () {
        final input = ComplexTemplates.deepMemberAccess;
        final frames = runProfile(documentParser, input);
        printProfilingReport('Deep Member Access', input, frames);
        expect(frames, isNotEmpty);
      });

      test('Nested Loops', () {
        final input = ComplexTemplates.nestedLoops;
        final frames = runProfile(documentParser, input);
        printProfilingReport('Nested Loops', input, frames);
        expect(frames, isNotEmpty);
      });

      test('Complex Logical Expressions', () {
        final input = ComplexTemplates.complexLogical;
        final frames = runProfile(documentParser, input);
        printProfilingReport('Complex Logical', input, frames);
        expect(frames, isNotEmpty);
      });

      test('E-commerce Template', () {
        final input = ComplexTemplates.ecommerceTemplate;
        final frames = runProfile(documentParser, input);
        printProfilingReport('E-commerce Template', input, frames);
        expect(frames, isNotEmpty);
      });

      test('Blog Template', () {
        final input = ComplexTemplates.blogTemplate;
        final frames = runProfile(documentParser, input);
        printProfilingReport('Blog Template', input, frames);
        expect(frames, isNotEmpty);
      });
    });

    group('Individual Parser Profiling', () {
      test('expression() parser', () {
        final parser = ExpressionGrammar().build();
        final inputs = [
          'user',
          'user.name',
          'user.profile.name',
          '1 + 2',
          'a == b',
          'true and false',
          'a == 1 and b == 2 or c == 3',
          'not user.active',
        ];

        for (final input in inputs) {
          final frames = runProfile(parser, input);
          printProfilingReport(
            'expression(): "$input"',
            input,
            frames,
            topN: 10,
          );
        }
      });

      test('variable() parser', () {
        final parser = VariableGrammar().build();
        final inputs = [
          '{{ x }}',
          '{{ user.name }}',
          '{{ price | money }}',
          '{{ name | upcase | append: "!" }}',
        ];

        for (final input in inputs) {
          final frames = runProfile(parser, input);
          printProfilingReport('variable(): "$input"', input, frames, topN: 10);
        }
      });

      test('filter() parser', () {
        final parser = FilterGrammar().build();
        final inputs = ['| upcase', '| append: "test"', '| replace: "a", "b"'];

        for (final input in inputs) {
          final frames = runProfile(parser, input);
          printProfilingReport('filter(): "$input"', input, frames, topN: 10);
        }
      });

      test('comparison() parser', () {
        final parser = ComparisonGrammar().build();
        final inputs = ['a == b', '1 < 2', 'x >= 10', 'name contains "test"'];

        for (final input in inputs) {
          final frames = runProfile(parser, input);
          printProfilingReport(
            'comparison(): "$input"',
            input,
            frames,
            topN: 10,
          );
        }
      });

      test('logicalExpression() parser', () {
        final parser = LogicalExpressionGrammar().build();
        final inputs = [
          'true and false',
          'a or b',
          'a == 1 and b == 2',
          'x and y or z',
        ];

        for (final input in inputs) {
          final frames = runProfile(parser, input);
          printProfilingReport(
            'logicalExpression(): "$input"',
            input,
            frames,
            topN: 10,
          );
        }
      });
    });

    group('Progress Tracking (Backtracking Analysis)', () {
      test('Simple variable progress', () {
        print('\n=== Progress: Simple Variable ===');
        runProgress(documentParser, '{{ user }}', maxLines: 30);
      });

      test('If block progress', () {
        print('\n=== Progress: If Block ===');
        runProgress(
          documentParser,
          '{% if true %}yes{% endif %}',
          maxLines: 50,
        );
      });

      test('Complex expression progress', () {
        print('\n=== Progress: Complex Expression ===');
        final input = '{% if a == 1 and b == 2 %}yes{% endif %}';
        runProgress(documentParser, input, maxLines: 80);
      });
    });

    group('Linter Analysis', () {
      test('Full grammar linter check', () {
        print('\n=== Linter: Full Grammar ===');
        runLinter(documentParser);
      });

      test('expression() linter check', () {
        print('\n=== Linter: expression() ===');
        runLinter(expression());
      });

      test('element() linter check', () {
        print('\n=== Linter: element() ===');
        runLinter(element());
      });
    });

    group('Comparative Analysis', () {
      test('Compare activation counts across template sizes', () {
        final templates = {
          'Tiny (15 chars)': SimpleTemplates.helloWorld,
          'Small (50 chars)': MediumTemplates.ifElse.substring(0, 50),
          'Medium (200 chars)': MediumTemplates.nestedIf,
          'Large (500+ chars)': ComplexTemplates.ecommerceTemplate,
          'XL (1000+ chars)': ComplexTemplates.blogTemplate,
        };

        print('\n${'=' * 70}');
        print('COMPARATIVE ANALYSIS: Activation Counts by Template Size');
        print('${'=' * 70}');
        print(
          '${'Template'.padRight(25)} ${'Chars'.padLeft(8)} ${'Activations'.padLeft(12)} ${'Ratio'.padLeft(10)}',
        );
        print('${'─' * 70}');

        int? baselineActivations;

        for (final entry in templates.entries) {
          final frames = runProfile(documentParser, entry.value);
          final totalActivations = frames.fold<int>(
            0,
            (sum, f) => sum + f.activationCount,
          );

          baselineActivations ??= totalActivations;
          final ratio = (totalActivations / baselineActivations)
              .toStringAsFixed(2);

          print(
            '${entry.key.padRight(25)} ${entry.value.length.toString().padLeft(8)} ${totalActivations.toString().padLeft(12)} ${ratio.padLeft(10)}x',
          );
        }

        print('${'=' * 70}\n');
      });
    });

    // =========================================================================
    // Performance Regression Tests
    // =========================================================================
    // These tests establish baseline activation counts for key scenarios.
    // If optimizations regress, these tests will help identify the problem.
    // Update the expected values when legitimate improvements are made.

    group('Performance Regression Guards', () {
      test('Simple variable should have bounded activations', () {
        final input = '{{ user }}';
        final frames = runProfile(documentParser, input);
        final totalActivations = frames.fold<int>(
          0,
          (sum, f) => sum + f.activationCount,
        );

        print('Simple variable activations: $totalActivations');

        // Baseline after text() optimization: ~299
        // After primaryTerm() optimization: ~274
        // Allow 30% tolerance for minor variations
        expect(
          totalActivations,
          lessThan(360),
          reason:
              'Simple variable parsing regressed. '
              'Expected <360, got $totalActivations',
        );
      });

      test('Member access should scale linearly with depth', () {
        final depths = [1, 2, 3, 4, 5];
        final activations = <int>[];

        for (final depth in depths) {
          final members = List.generate(depth, (i) => 'member$i').join('.');
          final input = '{{ user.$members }}';
          final frames = runProfile(documentParser, input);
          final total = frames.fold<int>(
            0,
            (sum, f) => sum + f.activationCount,
          );
          activations.add(total);
        }

        print('Member access activations by depth: $activations');

        // Check that each additional level adds roughly the same cost
        // (not exponential growth)
        for (var i = 1; i < activations.length; i++) {
          final growth = activations[i] - activations[i - 1];
          final previousGrowth = i > 1
              ? activations[i - 1] - activations[i - 2]
              : growth;

          // Growth should not more than double between levels
          expect(
            growth,
            lessThan(previousGrowth * 2.5),
            reason:
                'Member access scaling regressed at depth ${depths[i]}. '
                'Growth: $growth, previous: $previousGrowth',
          );
        }
      });

      test('For loop should have bounded per-element overhead', () {
        final input = MediumTemplates.forLoop;
        final frames = runProfile(documentParser, input);
        final totalActivations = frames.fold<int>(
          0,
          (sum, f) => sum + f.activationCount,
        );

        print('For loop activations: $totalActivations');

        // Baseline after text() optimization: ~1686
        expect(
          totalActivations,
          lessThan(2100),
          reason:
              'For loop parsing regressed. '
              'Expected <2100, got $totalActivations',
        );
      });

      test('Nested if blocks should scale sub-quadratically', () {
        final nestingLevels = [2, 4, 6, 8];
        final activations = <int>[];

        for (final level in nestingLevels) {
          final buffer = StringBuffer();
          for (var i = 0; i < level; i++) {
            buffer.write('{% if x$i %}');
          }
          buffer.write('content');
          for (var i = 0; i < level; i++) {
            buffer.write('{% endif %}');
          }

          final frames = runProfile(documentParser, buffer.toString());
          final total = frames.fold<int>(
            0,
            (sum, f) => sum + f.activationCount,
          );
          activations.add(total);
        }

        print('Nested if activations by level: $activations');
        print('Nesting levels: $nestingLevels');

        // Compute growth ratios - should not be quadratic
        for (var i = 1; i < activations.length; i++) {
          final levelRatio = nestingLevels[i] / nestingLevels[i - 1];
          final activationRatio = activations[i] / activations[i - 1];

          // Activation growth should be at most 2x the level growth (allowing for some overhead)
          expect(
            activationRatio,
            lessThan(levelRatio * 2.5),
            reason:
                'Nested if scaling is worse than linear at level ${nestingLevels[i]}. '
                'Level ratio: ${levelRatio.toStringAsFixed(2)}, '
                'Activation ratio: ${activationRatio.toStringAsFixed(2)}',
          );
        }
      });
    });

    // =========================================================================
    // Specific Parser Benchmarks
    // =========================================================================
    // These tests profile individual parsers to identify optimization targets.

    group('Specific Parser Benchmarks', () {
      test('identifier() parser efficiency', () {
        final parser = IdentifierGrammar().build();
        final inputs = [
          'x',
          'user',
          'my_variable',
          'camelCaseVar',
          'very_long_identifier_name',
        ];

        print('\n${'=' * 70}');
        print('BENCHMARK: identifier() parser');
        print('${'=' * 70}');
        print(
          '${'Input'.padRight(30)} ${'Chars'.padLeft(6)} ${'Activations'.padLeft(12)}',
        );
        print('${'─' * 70}');

        for (final input in inputs) {
          final frames = runProfile(parser, input);
          final total = frames.fold<int>(
            0,
            (sum, f) => sum + f.activationCount,
          );
          print(
            '${input.padRight(30)} ${input.length.toString().padLeft(6)} ${total.toString().padLeft(12)}',
          );

          // Identifier parsing should be O(n) where n is identifier length
          // Roughly 10-20 activations per character is acceptable
          expect(
            total,
            lessThan(input.length * 25 + 50),
            reason: 'identifier() too expensive for "$input"',
          );
        }
        print('${'=' * 70}\n');
      });

      test('primaryTerm() parser efficiency', () {
        final parser = PrimaryTermGrammar().build();
        final inputs = {
          'identifier': 'user',
          'number literal': '42',
          'string literal': '"hello"',
          'boolean literal': 'true',
          'member access': 'user.name',
          'array access': 'items[0]',
        };

        print('\n${'=' * 70}');
        print('BENCHMARK: primaryTerm() parser');
        print('${'=' * 70}');
        print(
          '${'Type'.padRight(20)} ${'Input'.padRight(15)} ${'Activations'.padLeft(12)}',
        );
        print('${'─' * 70}');

        for (final entry in inputs.entries) {
          final frames = runProfile(parser, entry.value);
          final total = frames.fold<int>(
            0,
            (sum, f) => sum + f.activationCount,
          );
          print(
            '${entry.key.padRight(20)} ${entry.value.padRight(15)} ${total.toString().padLeft(12)}',
          );
        }
        print('${'=' * 70}\n');
      });

      test('arithmeticExpr() parser efficiency', () {
        final parser = ArithmeticExprGrammar().build();
        final inputs = ['x', '1 + 2', 'a - b', 'x * y', 'a / b'];

        print('\n${'=' * 70}');
        print('BENCHMARK: arithmeticExpr() parser');
        print('${'=' * 70}');
        print('${'Input'.padRight(20)} ${'Activations'.padLeft(12)}');
        print('${'─' * 70}');

        for (final input in inputs) {
          final frames = runProfile(parser, input);
          final total = frames.fold<int>(
            0,
            (sum, f) => sum + f.activationCount,
          );
          print('${input.padRight(20)} ${total.toString().padLeft(12)}');
        }
        print('${'=' * 70}\n');
      });

      test('comparisonExpr() parser efficiency', () {
        final parser = ComparisonExprGrammar().build();
        final inputs = [
          'x',
          'a == b',
          'x < 10',
          'y >= 5',
          'name contains "test"',
        ];

        print('\n${'=' * 70}');
        print('BENCHMARK: comparisonExpr() parser');
        print('${'=' * 70}');
        print('${'Input'.padRight(25)} ${'Activations'.padLeft(12)}');
        print('${'─' * 70}');

        for (final input in inputs) {
          final frames = runProfile(parser, input);
          final total = frames.fold<int>(
            0,
            (sum, f) => sum + f.activationCount,
          );
          print('${input.padRight(25)} ${total.toString().padLeft(12)}');
        }
        print('${'=' * 70}\n');
      });

      test('logicalExpr() parser efficiency', () {
        final parser = LogicalExprGrammar().build();
        final inputs = [
          'x',
          'a and b',
          'x or y',
          'a == 1 and b == 2',
          'a and b or c',
        ];

        print('\n${'=' * 70}');
        print('BENCHMARK: logicalExpr() parser');
        print('${'=' * 70}');
        print('${'Input'.padRight(25)} ${'Activations'.padLeft(12)}');
        print('${'─' * 70}');

        for (final input in inputs) {
          final frames = runProfile(parser, input);
          final total = frames.fold<int>(
            0,
            (sum, f) => sum + f.activationCount,
          );
          print('${input.padRight(25)} ${total.toString().padLeft(12)}');
        }
        print('${'=' * 70}\n');
      });

      test('expression() precedence chain efficiency', () {
        final parser = ExpressionGrammar().build();
        final inputs = {
          'simple identifier': 'user',
          'arithmetic': '1 + 2',
          'comparison': 'a == b',
          'logical': 'x and y',
          'chained': 'a + b == c and d',
          'complex': 'a == 1 and b > 2 or c < 3',
        };

        print('\n${'=' * 70}');
        print('BENCHMARK: expression() precedence chain');
        print('${'=' * 70}');
        print(
          '${'Type'.padRight(20)} ${'Input'.padRight(30)} ${'Activations'.padLeft(12)}',
        );
        print('${'─' * 70}');

        for (final entry in inputs.entries) {
          final frames = runProfile(parser, entry.value);
          final total = frames.fold<int>(
            0,
            (sum, f) => sum + f.activationCount,
          );
          print(
            '${entry.key.padRight(20)} ${entry.value.padRight(30)} ${total.toString().padLeft(12)}',
          );
        }
        print('${'=' * 70}\n');
      });
    });

    // =========================================================================
    // Hotspot Analysis
    // =========================================================================
    // These tests help identify which parsers are activated most frequently.

    group('Hotspot Analysis', () {
      test('Top 10 most activated parsers in e-commerce template', () {
        final input = ComplexTemplates.ecommerceTemplate;
        final frames = runProfile(documentParser, input);

        // Aggregate by parser type (some parsers may appear multiple times)
        final byParser = <String, int>{};
        for (final frame in frames) {
          byParser[frame.parserName] =
              (byParser[frame.parserName] ?? 0) + frame.activationCount;
        }

        final sorted = byParser.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        print('\n${'=' * 70}');
        print('HOTSPOT ANALYSIS: E-commerce Template');
        print('${'=' * 70}');
        print('${'Parser'.padRight(50)} ${'Count'.padLeft(10)}');
        print('${'─' * 70}');

        for (var i = 0; i < 20 && i < sorted.length; i++) {
          final entry = sorted[i];
          final name = entry.key.length > 48
              ? '${entry.key.substring(0, 45)}...'
              : entry.key;
          print('${name.padRight(50)} ${entry.value.toString().padLeft(10)}');
        }
        print('${'=' * 70}\n');
      });

      test('Whitespace parser activation frequency', () {
        final templates = {
          'minimal whitespace': '{{x}}',
          'normal whitespace': '{{ x }}',
          'extra whitespace': '{{   x   }}',
          'multiline': '{{ x }}\n{{ y }}\n{{ z }}',
        };

        print('\n${'=' * 70}');
        print('WHITESPACE ANALYSIS');
        print('${'=' * 70}');
        print(
          '${'Template'.padRight(25)} ${'Whitespace Activations'.padLeft(25)}',
        );
        print('${'─' * 70}');

        for (final entry in templates.entries) {
          final frames = runProfile(documentParser, entry.value);
          final whitespaceActivations = frames
              .where((f) => f.parserName.contains('whitespace'))
              .fold<int>(0, (sum, f) => sum + f.activationCount);

          print(
            '${entry.key.padRight(25)} ${whitespaceActivations.toString().padLeft(25)}',
          );
        }
        print('${'=' * 70}\n');
      });

      test('ChoiceParser activation analysis', () {
        final input = MediumTemplates.complexExpression;
        final frames = runProfile(documentParser, input);

        final choiceParsers =
            frames.where((f) => f.parserName.contains('ChoiceParser')).toList()
              ..sort((a, b) => b.activationCount.compareTo(a.activationCount));

        print('\n${'=' * 70}');
        print('CHOICE PARSER ANALYSIS: Complex Expression');
        print('${'=' * 70}');
        print('${'Parser'.padRight(50)} ${'Count'.padLeft(10)}');
        print('${'─' * 70}');

        final totalChoiceActivations = choiceParsers.fold<int>(
          0,
          (sum, f) => sum + f.activationCount,
        );

        for (var i = 0; i < 10 && i < choiceParsers.length; i++) {
          final frame = choiceParsers[i];
          final name = frame.parserName.length > 48
              ? '${frame.parserName.substring(0, 45)}...'
              : frame.parserName;
          print(
            '${name.padRight(50)} ${frame.activationCount.toString().padLeft(10)}',
          );
        }
        print('${'─' * 70}');
        print(
          '${'Total ChoiceParser activations:'.padRight(50)} ${totalChoiceActivations.toString().padLeft(10)}',
        );
        print('${'=' * 70}\n');
      });
    });
  });
}
