# Liquify Parser Profiling Results

**Date:** January 18, 2026  
**PetitParser Version:** ^7.0.0  
**Profiling Tools Used:** `profile()`, `progress()`, `linter()` from `petitparser/debug.dart`

---

## Executive Summary

After a comprehensive optimization effort, the Liquify Liquid template parser has achieved **92-95% reduction in parser activations**. The original profiling identified several bottlenecks that have now been addressed through lookahead-based routing, pattern-based fast paths, and precedence-based expression parsing.

---

## 1. Performance Comparison: Before vs After

### Parser Activations

| Template Size | Characters | Before | After | Reduction |
|---------------|------------|--------|-------|-----------|
| Tiny          | 17         | 2,800  | 344   | **88%**   |
| Small         | 50         | 19,975 | 1,689 | **92%**   |
| Medium        | 134        | 21,062 | 1,451 | **93%**   |
| Large         | 822        | 130,961| 6,827 | **95%**   |
| XL            | 1,095      | 203,806| 9,832 | **95%**   |

### Activations per Character

| Template | Before | After | Improvement |
|----------|--------|-------|-------------|
| Tiny     | 165    | 20    | **8.2x**    |
| XL       | 186    | 9     | **20.7x**   |

---

## 2. Optimizations Applied

### Phase 1: Lookahead-based Element Routing (57-66% reduction)
- Modified `element()` to check for `{%` or `{{` before trying tag/variable parsers
- Plain text now routes directly without checking all tag alternatives

### Phase 2: Precedence-based Expression Parser (20-40% reduction)
- Replaced 12-way `.or()` chain with proper operator precedence
- Eliminates repeated prefix parsing for complex expressions

### Phase 3: Remove Redundant Trim (~1% reduction)
- Removed `.trim()` from arithmetic operators since `primaryTerm().trim()` handles it

### Phase 4: Pattern-based text() Parser (76% reduction)
- Uses `pattern('[^{]').star()` for bulk text matching
- Special handling for standalone `{` characters

### Phase 5: Pattern-based identifier() (5-7% reduction)
- Uses `pattern('[a-zA-Z]') & pattern('[a-zA-Z0-9_-]').star()` 
- Avoids multiple flatMap/where operations

### Phase 6: Pattern-based memberAccess() Fast Path (~50% for simple chains)
- Checks for simple identifier pattern before full parsing
- Avoids trying memberAccess for non-dot cases

### Phase 7: Pattern-based expressionWithAssignment() (3.5% reduction)
- Uses pattern matching instead of full identifier parsing in lookaheads
- Avoids parsing identifier 3 times in lookahead checks

### Phase 8: First-character Routing in primaryTerm() (15-22% reduction)
- Routes by first character to skip impossible alternatives
- Letters go directly to identifier-like parsers
- Quotes/digits go directly to string/numeric parsers

---

## 3. Current Hotspots (E-commerce Template)

| Count | Parser |
|-------|--------|
| 1,019 | SingleCharacterParser[whitespace expected] |
| 867   | ChoiceParser<dynamic> |
| 722   | SequenceParser<dynamic> |
| 426   | SingleCharacterParser[[a-zA-Z0-9_-] expected] |
| 387   | SingleCharacterParser[[^{] expected] |
| 297   | TrimmingParser<String> |

The remaining hotspots are mostly fundamental parsing operations that are difficult to optimize further without significant architectural changes.

---

## 4. Original Analysis (Historical Reference)

### Original Scaling Analysis

| Template Size | Characters | Parser Activations | Ratio vs Baseline |
|---------------|------------|-------------------|-------------------|
| Tiny          | 17         | 2,800             | 1.00x             |
| Small         | 50         | 19,975            | 7.13x             |
| Medium        | 134        | 21,062            | 7.52x             |
| Large         | 822        | 130,961           | 46.77x            |
| XL            | 1,095      | 203,806           | 72.79x            |

**Observation:** Parser activations grew faster than input size, indicating inefficient backtracking or redundant parsing attempts. This has been addressed.

---

## 2. Top Time-Consuming Parsers

### Simple Template: `Hello {{ name }}!` (17 chars)

| Count | Time (μs) | Parser |
|-------|-----------|--------|
| 1     | 12,708    | SkipParser<Document> |
| 1     | 12,138    | LabelParser<Document>[document] |
| 9     | 10,396    | LabelParser<dynamic>[element] |
| 9     | 10,349    | ChoiceParser<dynamic> |
| 9     | 3,578     | LabelParser<ASTNode>[variable] |

### Complex Template: E-commerce (822 chars)

| Count | Time (μs) | Parser |
|-------|-----------|--------|
| 1     | 77,888    | SkipParser<Document> |
| 381   | 70,155    | LabelParser<dynamic>[element] |
| 381   | 69,978    | ChoiceParser<dynamic> |
| 4     | 47,445    | LabelParser<List>[ifBranchContent] |
| 4     | 47,442    | LazyRepeatingParser<dynamic>[0..*] |

### Blog Template (1,095 chars)

| Count | Time (μs) | Parser |
|-------|-----------|--------|
| 1     | 114,793   | SkipParser<Document> |
| 564   | 102,673   | LabelParser<dynamic>[element] |
| 564   | 102,422   | ChoiceParser<dynamic> |
| 5     | 86,397    | LabelParser<List>[ifBranchContent] |
| 564   | 12,348    | LabelParser<Tag>[ifBlock] |

---

## 3. Most Activated Parsers

### Whitespace Parsing (Major Issue)

In the Blog template (1,095 chars), whitespace-related parsers dominate:

| Count | Parser |
|-------|--------|
| 5,615 | SingleCharacterParser[whitespace expected] |
| 1,873 | SingleCharacterParser[whitespace expected] |
| 1,868 | SingleCharacterParser[whitespace expected] |
| 1,866 | SingleCharacterParser[whitespace expected] (multiple instances) |

**Problem:** Excessive whitespace trimming via `.trim()` causes thousands of unnecessary character checks.

### Choice Parser Activations

| Count | Parser | Context |
|-------|--------|---------|
| 3,120 | ChoiceParser<dynamic> | Many Variables (50) test |
| 1,267 | ChoiceParser<dynamic> | E-commerce template |

**Problem:** The `element()` choice parser tries many alternatives before finding a match.

### Identifier Parsing

| Count | Time (μs) | Parser |
|-------|-----------|--------|
| 650   | 16,917    | LabelParser<Identifier>[identifier] |
| 650   | 12,997    | WhereParser<String> |
| 650   | 8,972     | FlattenParser |

**Problem:** Identifier parsing is called excessively due to its position in multiple choice parsers.

---

## 4. Linter Analysis Results

### Full Grammar (via `LiquidGrammar().build()`)
**Result:** No issues found - the `build()` method properly resolves references.

### Unresolved `expression()` Parser
**Result:** 78 issues found

#### Issue Type 1: Repeated Choices (66 warnings)
```
The choices at index 0 and 1 are identical:
 0: ReferenceParser<dynamic>
 1: ReferenceParser<dynamic>
The second choice can never succeed and can therefore be removed.
```

This pattern repeats for many index combinations (0-1, 0-2, 0-3, ..., 10-11), indicating that the `expression()` parser has many `ref0()` calls that resolve to the same parser, creating redundant choice branches.

#### Issue Type 2: Unnecessary Resolvable Parsers (12 warnings)
```
Resolvable parsers are used during construction of recursive grammars. 
While they typically dispatch to their delegate, they add unnecessary 
overhead and can be avoided by removing them before parsing using `resolve(parser)`.
```

### Unresolved `element()` Parser
**Result:** 65 issues found

Similar pattern of repeated choices and unnecessary resolvable parsers.

---

## 5. Specific Parser Bottlenecks

### `expression()` Parser

The expression parser (`shared.dart:224-237`) uses a long chain of `.or()` calls:

```dart
Parser expression() {
  return (ref0(logicalExpression)
          .or(ref0(comparison))
          .or(ref0(groupedExpression))
          .or(ref0(arithmeticExpression))
          .or(ref0(unaryOperation))
          .or(ref0(arrayAccess))
          .or(ref0(memberAccess))
          .or(ref0(assignment))
          .or(ref0(namedArgument))
          .or(ref0(literal))
          .or(ref0(identifier))
          .or(ref0(range)))
      .labeled('expression');
}
```

**Issues:**
1. 12 alternatives tried in order for every expression
2. Many of these start with similar tokens (e.g., identifier)
3. Backtracking happens frequently

### `element()` Parser

The element parser (`shared.dart:616-628`) is a large choice:

```dart
Parser element() => [
  ref0(ifBlock),
  ref0(forBlock),
  ref0(caseBlock),
  ref0(whenBlock),
  ref0(elseBlockForCase),
  ref0(elseBlockForFor),
  ref0(hashBlockComment),
  ...TagRegistry.customParsers.map((p) => p.parser()),
  ref0(tag),
  ref0(variable),
  ref0(text),
].toChoiceParser().labeled('element');
```

**Issues:**
1. For every character position, all block parsers are tried first
2. `text()` is last but most frequently matched
3. Custom parsers add to the choice list dynamically

### `tagStart()` and Tag Detection

```dart
Parser tagStart() => (string('{%-').trim() | string('{%')).labeled('tagStart');
```

**Issues:**
1. The `.trim()` on `{%-` causes whitespace parsing overhead
2. Both alternatives are tried frequently

---

## 6. Recommendations

### Priority 1: High Impact

1. **Reorder `element()` choices**
   - Move `text()` higher (or use negative lookahead)
   - Group tag parsers after checking for `{%` prefix
   - Consider a two-stage approach: detect delimiter first, then parse

2. **Optimize `expression()` ordering**
   - Put `identifier` and `literal` earlier (most common)
   - Use lookahead to avoid trying complex parsers on simple inputs

3. **Reduce whitespace trimming**
   - Remove `.trim()` from inner parsers
   - Trim only at tag/variable boundaries
   - Consider custom whitespace handling

### Priority 2: Medium Impact

4. **Factor out common prefixes**
   - Many parsers check for `{%` or `{{` repeatedly
   - Create a single check that branches to the appropriate parser

5. **Optimize identifier parsing**
   - Cache or memoize identifier results
   - Consider a specialized identifier parser

6. **Review `tagStart()` trimming**
   - The `.trim()` on `{%-` variant may be unnecessary
   - Whitespace control should be handled separately

### Priority 3: Structural Improvements

7. **Use `resolve()` for production parsing**
   - The linter suggests this reduces overhead
   - Already done via `LiquidGrammar().build()`

8. **Consider packrat parsing / memoization**
   - PetitParser supports memoization for expensive parsers
   - Could help with repeated expression parsing

9. **Profile with real-world templates**
   - Create benchmarks using actual production templates
   - Identify patterns that cause worst-case performance

---

## 7. Test Commands

```bash
# Run all profiling tests
cd pkgs/liquify
dart test test/profiling/parser_profiling_test.dart -r expanded

# Run specific test groups
dart test test/profiling/parser_profiling_test.dart --name "Simple Templates"
dart test test/profiling/parser_profiling_test.dart --name "Medium Templates"
dart test test/profiling/parser_profiling_test.dart --name "Complex Templates"
dart test test/profiling/parser_profiling_test.dart --name "Individual Parser"
dart test test/profiling/parser_profiling_test.dart --name "Linter"
dart test test/profiling/parser_profiling_test.dart --name "Comparative"
dart test test/profiling/parser_profiling_test.dart --name "Progress"
```

---

## 8. Baseline Metrics (for future comparison)

| Metric | Value |
|--------|-------|
| Hello World parse time | ~12,700 μs |
| E-commerce template parse time | ~77,900 μs |
| Blog template parse time | ~114,800 μs |
| Activations per char (tiny) | 165 |
| Activations per char (XL) | 186 |

---

## 9. Files Modified/Created

- `test/profiling/parser_profiling_test.dart` - Comprehensive profiling test suite
- `test/profiling/PROFILING_RESULTS.md` - This document

---

## 10. Next Steps

1. [ ] Address Priority 1 recommendations
2. [ ] Re-run profiling after each change
3. [ ] Ensure all existing tests pass
4. [ ] Update baseline metrics
5. [ ] Consider adding performance regression tests
