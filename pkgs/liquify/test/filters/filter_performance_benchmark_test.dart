import 'package:test/test.dart';
import 'package:liquify/liquify.dart';
import 'package:liquify/parser.dart' show parseInput;
import 'package:liquify/src/context.dart';
import 'package:liquify/src/evaluator.dart';

/// Uncached version of expression evaluation for comparison
dynamic _evaluateLiquidExpressionUncached(
  dynamic item,
  String itemName,
  String expression,
) {
  try {
    final liquidExpression = '{{ $expression }}';
    // Always parse - no caching
    final parsed = parseInput(liquidExpression);
    if (parsed.isEmpty) return false;

    final context = Environment();
    if (item is Map) {
      context.setVariable(itemName, item);
      for (final entry in item.entries) {
        if (entry.key is String) {
          context.setVariable(entry.key as String, entry.value);
        }
      }
    } else {
      context.setVariable(itemName, item);
    }

    final evaluator = Evaluator(context);
    final result = evaluator.evaluate(parsed.first);

    if (result == null || result == false) return false;
    if (result == true) return true;
    if (result is String && result.isEmpty) return false;
    if (result is num && result == 0) return false;
    if (result is List && result.isEmpty) return false;
    return true;
  } catch (e) {
    return false;
  }
}

void main() {
  group('Filter Performance Benchmarks - Cached vs Uncached', () {
    test('where_exp: Cached vs Uncached expression parsing', () {
      final products = List.generate(
        500,
        (i) => {'name': 'Product $i', 'price': i * 10, 'active': i % 2 == 0},
      );

      print('\n=== where_exp Expression Parsing: Cached vs Uncached ===');

      // Uncached: parse expression for EVERY item
      final swUncached = Stopwatch()..start();
      for (var run = 0; run < 10; run++) {
        final filtered = products.where((item) {
          return _evaluateLiquidExpressionUncached(
            item,
            'item',
            'item.active == true',
          );
        }).toList();
        expect(filtered.length, equals(250));
      }
      swUncached.stop();

      // Cached: use Template which uses the cached version
      final whereExpTemplate = Template.parse(
        "{{ products | where_exp: 'item', 'item.active == true' | size }}",
        data: {'products': products},
      );
      whereExpTemplate.render(); // warmup

      final swCached = Stopwatch()..start();
      for (var run = 0; run < 10; run++) {
        final result = whereExpTemplate.render();
        expect(result, equals('250'));
      }
      swCached.stop();

      final uncachedMs = swUncached.elapsedMilliseconds;
      final cachedMs = swCached.elapsedMilliseconds;
      final speedup = uncachedMs / cachedMs;

      print('500 items x 10 runs:');
      print('  Uncached: ${uncachedMs}ms (parses expression 5000 times)');
      print('  Cached:   ${cachedMs}ms (parses expression once)');
      print('  Speedup:  ${speedup.toStringAsFixed(1)}x faster');

      // Cached should be significantly faster
      expect(cachedMs, lessThan(uncachedMs));
    });

    test('sort_natural: RegExp caching impact', () {
      final items = List.generate(500, (i) => 'item${i % 50}');
      final regex = RegExp(r'^(.*?)(\d+)(.*)$');

      print('\n=== sort_natural RegExp: Cached vs Uncached ===');

      // Uncached: create new RegExp for each comparison
      int uncachedComparisons = 0;
      int uncachedCompare(dynamic a, dynamic b) {
        uncachedComparisons++;
        String aStr = a.toString();
        String bStr = b.toString();
        // Create NEW RegExp each time (what old code did)
        final aMatch = RegExp(r'^(.*?)(\d+)(.*)$').firstMatch(aStr);
        final bMatch = RegExp(r'^(.*?)(\d+)(.*)$').firstMatch(bStr);

        if (aMatch != null && bMatch != null) {
          int prefixCmp = (aMatch.group(1) ?? '').compareTo(
            bMatch.group(1) ?? '',
          );
          if (prefixCmp != 0) return prefixCmp;
          int aNum = int.tryParse(aMatch.group(2) ?? '0') ?? 0;
          int bNum = int.tryParse(bMatch.group(2) ?? '0') ?? 0;
          int numCmp = aNum.compareTo(bNum);
          if (numCmp != 0) return numCmp;
          return (aMatch.group(3) ?? '').compareTo(bMatch.group(3) ?? '');
        }
        return aStr.compareTo(bStr);
      }

      // Cached: reuse RegExp
      int cachedComparisons = 0;
      int cachedCompare(dynamic a, dynamic b) {
        cachedComparisons++;
        String aStr = a.toString();
        String bStr = b.toString();
        // Reuse cached RegExp
        final aMatch = regex.firstMatch(aStr);
        final bMatch = regex.firstMatch(bStr);

        if (aMatch != null && bMatch != null) {
          int prefixCmp = (aMatch.group(1) ?? '').compareTo(
            bMatch.group(1) ?? '',
          );
          if (prefixCmp != 0) return prefixCmp;
          int aNum = int.tryParse(aMatch.group(2) ?? '0') ?? 0;
          int bNum = int.tryParse(bMatch.group(2) ?? '0') ?? 0;
          int numCmp = aNum.compareTo(bNum);
          if (numCmp != 0) return numCmp;
          return (aMatch.group(3) ?? '').compareTo(bMatch.group(3) ?? '');
        }
        return aStr.compareTo(bStr);
      }

      final swUncached = Stopwatch()..start();
      for (var run = 0; run < 100; run++) {
        final sorted = List.from(items);
        sorted.sort(uncachedCompare);
      }
      swUncached.stop();

      final swCached = Stopwatch()..start();
      for (var run = 0; run < 100; run++) {
        final sorted = List.from(items);
        sorted.sort(cachedCompare);
      }
      swCached.stop();

      final uncachedMs = swUncached.elapsedMilliseconds;
      final cachedMs = swCached.elapsedMilliseconds;
      final speedup = uncachedMs / cachedMs;

      print('500 items x 100 sorts:');
      print(
        '  Uncached: ${uncachedMs}ms (creates ~${uncachedComparisons * 2} RegExp objects)',
      );
      print('  Cached:   ${cachedMs}ms (reuses 1 RegExp)');
      print('  Speedup:  ${speedup.toStringAsFixed(1)}x faster');
      print('  Comparisons per sort: ${uncachedComparisons ~/ 100}');

      expect(cachedMs, lessThan(uncachedMs));
    });

    test('Summary: Filter caching benchmark results', () {
      print('\n');
      print('=' * 60);
      print('FILTER CACHING OPTIMIZATION SUMMARY');
      print('=' * 60);
      print('');
      print('Optimizations implemented:');
      print('  1. Expression parsing cache for *_exp filters');
      print('     - where_exp, find_exp, group_by_exp, reject_exp, etc.');
      print('     - Parses expression ONCE per unique expression string');
      print('     - Previously: parsed for EVERY array item');
      print('');
      print('  2. Natural sort RegExp cache');
      print('     - Single RegExp instance reused across all comparisons');
      print('     - Previously: created 2 RegExp per comparison');
      print('');
      print('  3. String filter RegExp cache');
      print('     - Cached: whitespace, newline, CJK patterns');
      print('     - Used by: truncatewords, strip_newlines,');
      print('       normalize_whitespace, number_of_words');
      print('');
      print('  4. Unified filter registry lookup cache');
      print('     - O(1) filter lookup instead of iterating modules');
      print('=' * 60);
    });
  });
}
