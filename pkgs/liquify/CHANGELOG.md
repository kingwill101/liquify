## 1.4.0

### Liquid tag improvements
- Treat each non-empty line in `{% liquid %}` blocks as a statement
- Ignore whitespace-only lines inside `{% liquid %}` blocks
- Error on CR-only line endings in `{% liquid %}` blocks for consistent parsing behavior
- Route `{% liquid %}` output through the active buffer (works correctly inside captures)

### Output and scope semantics
- Preserve value types for single-expression tag content so numeric filters (e.g., `times`) behave correctly
- `assign` inside `for` loops now persists after the loop while keeping `forloop` and loop variables local

### Tests
- Add `{% liquid %}` shorthand syntax and whitespace handling tests
- Add capture regression coverage for `{% liquid %}` output routing

## 1.3.1
- Fix string literal parsing to correctly handle escaped quotes and characters
- Add regression tests covering render tag and evaluator behaviour with escaped strings

## 1.3.0
- Correctly check for elsif tags and not elseif
- tablerow - use seperate buffer for each row being rendered
- refactor parsers for if/case/for to better capture content in else branches etc


## 1.2.0

### 🔒 Environment-Scoped Registry
- Add environment-scoped filter and tag registration
- Add strict mode for security sandboxing
- Add `Environment.withStrictMode()` constructor
- Add Template API support for custom environments
- Add environment cloning with local registrations

### 🔧 Parser Improvements
- Fix operators to prevent invalid matches with adjacent words
- Enhance comparison, logical, and unary operator parsing
- Improve operator precedence handling

### 🏷️ Render Tag Fixes
- Fix variable scope isolation in render tags
- Prevent variable leakage to parent scope
- Add comprehensive scope isolation tests

### 📚 Documentation
- Add environment-scoped registry documentation


## 1.1.0

### 📚 Documentation
- **Complete documentation overhaul**: Added comprehensive documentation system
- **Examples documentation**: Added 5 detailed example guides covering basic usage, layouts, custom tags, drop objects, and file system integration
- **Tags documentation**: Complete reference for all 21 tags with usage patterns and examples
- **Filters documentation**: Comprehensive documentation for 68+ filters across 7 categories (array, string, math, date, HTML, URL, misc)
- **API documentation**: Structured documentation hub with cross-references and navigation

### 🧮 Filters
- **NEW**: Add `parse_json` filter for parsing JSON strings into Dart objects
- **Enhancement**: Math filters now handle null values gracefully (null treated as 0, prevents runtime type cast errors)
- **Enhancement**: Complete expression-based filters (where_exp, find_exp, group_by_exp, etc.) with proper Liquid expression evaluation
- **Enhancement**: Add missing array manipulation filters: compact, concat, push, pop, shift, unshift, reject, sum, sort_natural, group_by, has
- **Fix**: Filter arguments now support member access expressions (e.g., `append: features.size`)

### 🏗️ Core Improvements
- **Fix**: Boolean literal parsing in comparison operations (true/false now parsed as literals instead of identifiers)
- **Enhancement**: FileSystemRoot and MapRoot now have extensions and throwOnError support
- **Complete**: 100% filter test coverage with comprehensive regression tests

### 🏷️ Tags
- **NEW**: comment
- **NEW**: doc

### 🧪 Testing
- Complete test coverage for all implemented filters
- Add regression tests for boolean literal parsing
- Enhanced render tag tests

## 1.0.4
- Fix FileSystemRoot to handle null fileSystem argument safely and consistently fallback to LocalFileSystem
- Add tests for FileSystemRoot null fileSystem behavior

## 1.0.3
- Fix contains operator

## 1.0.2
- allow iterating over key value pairs in for tags

## 1.0.1
- Disable internal resolver/analyzer logging

## 1.0.0
- Layout tag support
- Async rendering support

## 1.0.0-dev.2
- **Template Enhancements:**
  - Added layout tag support with title filter.
  - Implemented template analyzer and resolver.

- **Analyzer Improvements:**
  - Initial support for a static analyzer.
  - Extensive testing and improvements in static analysis.
  - Enhanced resolver and analyzer integration.

- **Filter Enhancements:**
  - Enabled dot notation for array filters.

## 1.0.0-dev.1
- layout tag support

## 0.8.2
- Make sure we register all the missing string filters

## 0.8.1
- support elseif tags

## 0.8.0
- Start throwing exceptions when parsing fails

## 0.7.4
- For tag: make sure iterable is not null before assignment

## 0.7.3
- Truthy support for binary operators

 ## 0.7.2
- Array support

## 0.7.1
- array support

## 0.7.0
- Fix parse failure for single { character
- Better whitespace control handling
- Optional tracing and linting

## 0.6.6

- Allow identifiers with hyphens

## 0.6.5

- Member access fix

## 0.6.3

- Filtered assignment fix

## 0.6.2

- Group filters into modules

## 0.6.0

- Empty type
- MapRoot Root implementation

## 0.5.0

- Filesystem lookup
- Render tag

## 0.4.0

- Drop support

## 0.3.0

- Support floating point numbers
- Support negative numbers

## 0.2.0

- Add built in filters
## 0.1.0

- Initial version.
