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
  });
}
