import 'package:liquify/parser.dart';
import 'package:liquify/src/fs.dart';
import 'package:liquify/src/util.dart';

import 'block_info.dart';
import 'template_analysis.dart';
import 'template_structure.dart';

/// A template analyzer that processes Liquid templates to understand their structure,
/// block hierarchy, and inheritance relationships.
///
/// The analyzer is responsible for:
/// * Parsing and analyzing Liquid templates
/// * Tracking template inheritance through `layout` and `extends` tags
/// * Managing block overrides and nested block relationships
/// * Building a complete picture of the template structure
///
/// Example usage:
/// ```dart
/// final analyzer = TemplateAnalyzer(root);
/// final analysis = analyzer.analyzeTemplate('path/to/template.liquid').last;
/// final structure = analysis.structures['path/to/template.liquid'];
/// ```
class TemplateAnalyzer {
  /// The root directory context for resolving template paths.
  ///
  /// When provided, the analyzer uses this to locate and read template files.
  /// If null, the analyzer can only work with explicitly provided template content.
  final Root? root;

  /// Logger instance for debugging and tracing template analysis.
  final Logger logger = Logger('TemplateAnalyzer');

  /// Creates a new template analyzer with an optional root directory context.
  ///
  /// The [root] parameter provides the context for resolving template paths and
  /// reading template content. If not provided, the analyzer can only work with
  /// explicitly provided template content through [initialNodes].
  TemplateAnalyzer([this.root]);

  /// Analyzes a template and yields analysis results as they become available.
  ///
  /// This method processes a template and its inheritance chain, building a complete
  /// picture of the template's structure including blocks, overrides, and layout relationships.
  ///
  /// Parameters:
  /// * [templatePath] - The path to the template file, relative to the root
  /// * [initialNodes] - Optional pre-parsed AST nodes if the template content is already available
  /// * [parentStructure] - Optional parent structure if this template's parent has already been analyzed
  ///
  /// Returns an [Iterable] of [TemplateAnalysis] objects, which contain:
  /// * The analyzed structures for this template and its parents
  /// * Any warnings or errors encountered during analysis
  ///
  /// Example:
  /// ```dart
  /// final analysis = await analyzer.analyzeTemplate('child.liquid').last;
  /// final childStructure = analysis.structures['child.liquid'];
  /// ```
  Iterable<TemplateAnalysis> analyzeTemplate(
    String templatePath, {
    List<ASTNode>? initialNodes,
    TemplateStructure? parentStructure,
  }) sync* {
    final analysis = TemplateAnalysis();
    if (root == null && initialNodes == null) {
      analysis.warnings
          .add('No root directory set and no initial nodes provided');
      yield analysis;
      return;
    }
    try {
      final nodes =
          initialNodes ?? parseInput(root!.resolve(templatePath).content);

      for (final structure in _analyzeStructure(templatePath, nodes, analysis,
          providedParent: parentStructure)) {
        if (structure != null) {
          analysis.structures[templatePath] = structure;
        }
        yield analysis;
      }
    } catch (e) {
      analysis.warnings.add('Failed to analyze template: $e');
      yield analysis;
    }
  }

  /// Internal method that performs the actual template structure analysis.
  ///
  /// This method handles:
  /// * Processing layout/extends tags to build the inheritance chain
  /// * Analyzing and categorizing blocks within the template
  /// * Managing block overrides and nested block relationships
  /// * Building the complete template structure
  ///
  /// The analysis happens in two passes:
  /// 1. First pass processes layout/extends tags and builds parent structures
  /// 2. Second pass processes blocks with full knowledge of the inheritance chain
  ///
  /// Parameters:
  /// * [templatePath] - The path to the template being analyzed
  /// * [nodes] - The AST nodes of the template
  /// * [analysis] - The current analysis state
  /// * [providedParent] - Optional pre-analyzed parent structure
  ///
  /// Returns an [Iterable] of [TemplateStructure] objects representing the
  /// analyzed template structure.
  Iterable<TemplateStructure?> _analyzeStructure(
    String templatePath,
    List<ASTNode> nodes,
    TemplateAnalysis analysis, {
    TemplateStructure? providedParent,
  }) sync* {
    TemplateStructure? parentStructure = providedParent;
    final localBlocks = <String, BlockInfo>{};
    var structureBody = <ASTNode>[];
    bool layoutFound = false;

    // First pass: Process layout/extends tags and build parent structure
    for (final node in nodes) {
      if (!layoutFound &&
          node is Tag &&
          (node.name == 'layout' || node.name == 'extends')) {
        if (node.content.isNotEmpty && node.content.first is Literal) {
          final parentPath = (node.content.first as Literal).value.toString();
          logger.info('[Analyzer] Found parent template: $parentPath');
          final parentSource = root!.resolve(parentPath);
          final parentNodes = parseInput(parentSource.content);

          // Process parent structure completely before continuing
          var lastParentStructure = parentStructure;
          for (final structure
              in _analyzeStructure(parentPath, parentNodes, analysis)) {
            lastParentStructure = structure;
            if (lastParentStructure != null) {
              analysis.structures[parentPath] = lastParentStructure;
            }
          }
          parentStructure = lastParentStructure;

          // Ensure parent blocks are fully processed
          if (parentStructure != null) {
            logger.info(
                '[Analyzer] Parent blocks: ${parentStructure.blocks.keys.join(', ')}');
          }
        }
        structureBody = List.from(node.body);
        layoutFound = true;
      } else if (!layoutFound) {
        structureBody.add(node);
      }
    }
    if (!layoutFound) {
      structureBody = nodes;
    }

    /// Internal helper function that processes block nodes recursively.
    ///
    /// This function:
    /// * Extracts block names and content
    /// * Handles nested blocks and their relationships
    /// * Manages block overrides and inheritance
    /// * Processes super() calls within blocks
    ///
    /// Parameters:
    /// * [nodes] - The AST nodes to process
    /// * [parentBlock] - Optional parent block for nested blocks
    void processBlockNodes(List<ASTNode> nodes, {BlockInfo? parentBlock}) {
      for (final node in nodes) {
        if (node is Tag && node.name == 'block') {
          String? simpleName;
          for (final c in node.content) {
            if (c is Identifier) {
              simpleName = c.name;
              break;
            }
            if (c is Literal) {
              final text = c.value.toString().trim();
              if (text.isNotEmpty) {
                simpleName = text;
                break;
              }
            }
          }
          if (simpleName != null) {
            String finalName = simpleName;
            BlockInfo? inheritedParent;

            if (parentBlock != null) {
              finalName = '${parentBlock.name}.$simpleName';
            }

            // Check for block in parent structure
            bool isOverride = false;
            if (parentStructure != null) {
              // If this block exists in any ancestor, it's an override
              TemplateStructure? ancestor = parentStructure;
              while (!isOverride && ancestor != null) {
                // First check if any parent's block key ends with '.$simpleName'
                bool found = false;
                for (final key in ancestor.blocks.keys) {
                  if (key.endsWith('.$simpleName')) {
                    finalName = key;
                    inheritedParent = ancestor.blocks[key];
                    isOverride = true;
                    found = true;
                    break;
                  }
                }

                if (!found) {
                  // Then check if parent's blocks directly contain the simple name
                  if (ancestor.blocks.containsKey(simpleName)) {
                    inheritedParent = ancestor.blocks[simpleName];
                    finalName = simpleName;
                    isOverride = true;
                  } else {
                    // Finally check each parent's topBlock nestedBlocks
                    for (final topBlock in ancestor.blocks.values) {
                      if (topBlock.nestedBlocks.containsKey(simpleName)) {
                        finalName = '${topBlock.name}.$simpleName';
                        inheritedParent = topBlock.nestedBlocks[simpleName];
                        isOverride = true;
                        found = true;
                        break;
                      }
                    }
                  }
                }

                ancestor = ancestor.parent;
              }
            }

            // Check if this block has any nested blocks that are overridden
            bool hasOverriddenSubBlocks = false;
            if (parentStructure != null) {
              hasOverriddenSubBlocks = parentStructure.blocks.keys.any((key) =>
                  key.startsWith('$finalName.') &&
                  parentStructure?.blocks[key]?.isOverride == true);
            }

            bool foundSuper = false;
            void checkForSuper(List<ASTNode> nodes) {
              for (final n in nodes) {
                if (n is Tag && n.name == "super") {
                  foundSuper = true;
                  break;
                }
                if (n is Tag) {
                  checkForSuper(n.body);
                  checkForSuper(n.content);
                }
              }
            }

            checkForSuper(node.body);

            final newBlock = BlockInfo(
              name: finalName,
              source: templatePath,
              content: node.body,
              isOverride: isOverride ||
                  hasOverriddenSubBlocks ||
                  parentBlock != null ||
                  parentStructure != null,
              parent: inheritedParent ?? parentBlock,
              nestedBlocks: {},
              hasSuperCall: foundSuper,
            );

            if (parentBlock != null) {
              parentBlock.nestedBlocks[simpleName] = newBlock;
            } else {
              localBlocks[finalName] = newBlock;
            }

            logger.info(
                '[Analyzer] Created block: $finalName (override: ${newBlock.isOverride})');
            processBlockNodes(node.body, parentBlock: newBlock);
          }
        } else if (node is Tag) {
          processBlockNodes(node.body, parentBlock: parentBlock);
          processBlockNodes(node.content, parentBlock: parentBlock);
        }
      }
    }

    processBlockNodes(structureBody, parentBlock: null);

    final structure = TemplateStructure(
      templatePath: templatePath,
      nodes: structureBody.cast<ASTNode>(),
      blocks: localBlocks,
      parent: parentStructure,
    );

    logger.info('[Analyzer] Completed structure for $templatePath');
    logger.info('[Analyzer] Blocks: ${localBlocks.keys.join(', ')}');
    yield structure;
  }

  /// Builds a hierarchical tree representation of the template's block structure.
  ///
  /// This method takes a template path and returns a nested map structure that
  /// represents the template's blocks and their relationships. The tree preserves
  /// the dot notation hierarchy of nested blocks.
  ///
  /// Parameters:
  /// * [templatePath] - The path to the template to analyze
  ///
  /// Returns a [Map] where:
  /// * Keys are block names
  /// * Values are maps containing block information including:
  ///   * source: The template where the block is defined
  ///   * isOverride: Whether the block overrides a parent block
  ///   * hasSuperCall: Whether the block calls super()
  ///   * children: Nested blocks within this block
  ///
  /// Example:
  /// ```dart
  /// final tree = analyzer.buildResolvedTree('template.liquid');
  /// print(tree['header']['children']['navigation']);
  /// ```
  Map<String, dynamic> buildResolvedTree(String templatePath) {
    final analysis = analyzeTemplate(templatePath).last;
    final structure = analysis.structures[templatePath];
    if (structure == null) {
      throw Exception('Template structure not found for $templatePath');
    }
    final nestedTree = _nestByDotNotation(structure.blocks);
    logger.info(
        "[Analyzer][buildResolvedTree] Final nested tree produced: $nestedTree");
    return nestedTree;
  }

  /// Internal helper that converts a flat map of blocks with dot notation keys
  /// into a nested tree structure.
  ///
  /// This method takes block names like "header.navigation.menu" and creates
  /// a nested structure: header -> navigation -> menu.
  ///
  /// Parameters:
  /// * [flatMap] - The flat map of blocks using dot notation keys
  ///
  /// Returns a nested [Map] structure preserving the block hierarchy.
  Map<String, dynamic> _nestByDotNotation(Map<String, BlockInfo> flatMap) {
    final Map<String, dynamic> root = {};
    flatMap.forEach((dottedKey, blockInfo) {
      final parts = dottedKey.split('.');
      Map<String, dynamic> current = root;
      for (int i = 0; i < parts.length; i++) {
        final segment = parts[i];
        current.putIfAbsent(segment, () => <String, dynamic>{});
        if (i == parts.length - 1) {
          current[segment] = {
            'source': blockInfo.source,
            'isOverride': blockInfo.isOverride,
            'hasSuperCall': blockInfo.hasSuperCall,
            'children': <String, dynamic>{},
          };
        } else {
          current[segment].putIfAbsent('children', () => <String, dynamic>{});
          current =
              Map<String, dynamic>.from(current[segment]['children'] as Map);
        }
      }
    });
    return root;
  }
}
