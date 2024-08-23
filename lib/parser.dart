/// Liquify Parser: Core parsing, tag management, and registry for Liquid templates
///
/// This library provides essential components for parsing Liquid templates,
/// managing custom tags, and registering built-in and custom functionality.
///
/// Key components:
///
/// 1. Parsing and Grammar (in `src/grammar/shared.dart`):
///    - Basic Liquid syntax parsers: [tagStart], [tagEnd], [varStart], [varEnd]
///    - Expression parsers: [expression], [literal], [identifier], [memberAccess]
///    - Tag helpers: [someTag], [breakTag], [continueTag], [elseTag]
///    - Main parsing function: [parseInput]
///
///    Note: The [someTag] helper is designed for simple tags without end tags.
///    For tags that require an end tag or more complex parsing, custom parser
///    implementation is necessary.
///
/// 2. Tag Management (in `src/tags/tag.dart`):
///    - [AbstractTag]: Base class for all Liquid tags
///    - [Tag]: Standard implementation of a Liquid tag
///
/// 3. Tag Registry (in `src/registry.dart`):
///    - [TagRegistry]: Central management system for Liquid template tags
///      - [TagRegistry.register]: Register new custom tags
///      - [TagRegistry.createTag]: Create instances of registered tags
///      - [TagRegistry.hasEndTag]: Check if a tag has an end tag
///    - [registerBuiltIns]: Function to register all built-in Liquid tags
///
/// 4. AST (Abstract Syntax Tree) (in `src/ast.dart`):
///    - Node types for representing parsed Liquid templates
///    - Includes [ASTNode], [TextNode], [Variable], [Filter], etc.
///
/// 5. Evaluation (in `src/evaluator.dart`):
///    - [Evaluator]: Class for evaluating parsed Liquid templates
///      - [Evaluator.evaluate]: Evaluates a single ASTNode
///      - [Evaluator.evaluateNodes]: Evaluates a list of ASTNodes
///
/// Usage:
/// ```dart
/// import 'package:liquify/parser.dart';
///
/// // Define a custom tag with an end tag
/// class UppercaseTag extends AbstractTag with CustomTagParser {
///   UppercaseTag(List<ASTNode> content, List<Filter> filters) : super(content, filters);
///
///   @override
///   dynamic evaluate(Evaluator evaluator, Buffer buffer) {
///     buffer.write('<span style="text-transform: uppercase;">');
///     for (final node in content) {
///       final result = evaluator.evaluate(node);
///       buffer.write(result);
///     }
///     buffer.write('</span>');
///   }
///
///   @override
///   Parser parser() {
///     // Custom parser implementation for tags with end tags
///     return (tagStart() &
///             string('uppercase').trim() &
///             tagEnd() &
///             any()
///                 .starLazy(tagStart() & string('enduppercase').trim() & tagEnd())
///                 .flatten() &
///             tagStart() &
///             string('enduppercase').trim() &
///             tagEnd())
///         .map((values) {
///       return Tag("uppercase", [TextNode(values[3])]);
///     });
///   }
/// }
///
/// // For a simple tag without an end tag, you could use someTag:
/// // Parser simpleParser() => someTag('simpletag');
///
/// // Register the custom tag
/// TagRegistry.register('uppercase', (content, filters) => UppercaseTag(content, filters));
///
/// // Parse a template using the custom tag
/// List<ASTNode> nodes = parseInput('{% uppercase %}Hello, {{ name }}!{% enduppercase %}');
///
/// // Evaluate the template
/// Evaluator evaluator = Evaluator(Environment({'name': 'World'}));
/// final result = evaluator.evaluateNodes(nodes);
/// print(result); // Output: <span style="text-transform: uppercase;">Hello, World!</span>
/// ```
///
/// This library is used internally by the Liquify engine but can also be
/// used directly for advanced customization of the Liquid parsing and
/// evaluation process.
library liquify_parser;

export 'package:liquify/src/tag.dart';
export 'package:liquify/src/registry.dart';
