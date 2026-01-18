import 'package:liquify/parser.dart';
import 'package:liquify/src/analyzer/block_info.dart';
import 'package:liquify/src/analyzer/template_structure.dart';
import 'package:liquify/src/util.dart';

final resolverLogger = Logger('Resolver');

/// Cache for nested block name lookups.
/// Maps simple block names to their full qualified names.
final _nestedBlockNameCache = Expando<Map<String, String>>('nestedBlockNames');

/// Cache the last overrides map we built a lookup for.
/// This allows reuse within a single buildCompleteMergedAst call.
Map<String, BlockInfo>? _lastOverridesMap;
Map<String, String>? _lastNestedLookup;

/// Recursive helper to merge a single AST node.
/// - If the node is a block tag, attempt to replace it with the resolved content.
/// - Otherwise, process its children (body and content) recursively.
List<ASTNode> _mergeNode(ASTNode node, TemplateStructure structure) {
  if (node is Tag && node.name == 'block') {
    final blockName = _getBlockName(node);
    resolverLogger.info(
      "[_mergeNode] Processing block tag with name: $blockName",
    );

    if (blockName == null) {
      resolverLogger.info(
        "[_mergeNode] Block name is null, returning original node",
      );
      return [node];
    }

    // Use optimized block lookup
    final resolvedBlocks = structure.resolvedBlocks;
    BlockInfo? block = _findBlockInResolved(blockName, resolvedBlocks);
    resolverLogger.info(
      "[_mergeNode] Block lookup for '$blockName': ${block != null ? 'found' : 'not found'}",
    );

    // If we found a block (either direct or nested)
    if (block != null && block.content != null) {
      resolverLogger.info(
        "[_mergeNode] Found block override: isOverride=${block.isOverride}, hasSuperCall=${block.hasSuperCall}",
      );

      // If this is an override with super call, process it
      if (block.hasSuperCall) {
        resolverLogger.info(
          "[_mergeNode] Processing super call for block: $blockName",
        );
        return _processSuperCall(node, block, structure);
      }

      // If this is an override, use its content
      if (block.isOverride) {
        resolverLogger.info(
          "[_mergeNode] Using override content for block: $blockName",
        );
        return block.content!;
      }
    }

    resolverLogger.info(
      "[_mergeNode] No override found or not an override, processing block body",
    );
    return node.body.expand((n) => _mergeNode(n, structure)).toList();
  }

  // For non-block nodes, recursively process children
  if (node is Tag) {
    resolverLogger.info("[_mergeNode] Processing non-block tag: ${node.name}");
    final newContent = node.content
        .expand((n) => _mergeNode(n, structure))
        .toList();
    final newBody = node.body.expand((n) => _mergeNode(n, structure)).toList();
    return [Tag(node.name, newContent, body: newBody)];
  }

  return [node];
}

/// Optimized block lookup - tries direct match first, then nested lookup.
BlockInfo? _findBlockInResolved(
  String blockName,
  Map<String, BlockInfo> resolvedBlocks,
) {
  // Direct lookup (O(1))
  var block = resolvedBlocks[blockName];
  if (block != null) return block;

  // Build nested lookup and try
  var nestedLookup = _getOrBuildNestedLookup(resolvedBlocks);
  var fullName = nestedLookup[blockName];
  if (fullName != null) {
    return resolvedBlocks[fullName];
  }

  return null;
}

String? _getBlockName(Tag blockTag) {
  final name = blockTag.content.firstWhere(
    (n) => n is Identifier,
    orElse: () => TextNode(''),
  );
  if (name is! Identifier) return null;
  return name.name;
}

List<ASTNode> _processSuperCall(
  Tag node,
  BlockInfo block,
  TemplateStructure structure,
) {
  if (structure.parent == null) {
    return [];
  }

  // Get the block name without any parent prefixes
  final blockName = block.name.split('.').last;

  // Use optimized block lookup
  final parentResolvedBlocks = structure.parent!.resolvedBlocks;
  BlockInfo? parentBlock = _findBlockInResolved(
    blockName,
    parentResolvedBlocks,
  );

  if (parentBlock == null || parentBlock.content == null) {
    return [];
  }

  // Process the parent's content recursively
  return parentBlock.content!
      .expand((n) => _mergeNode(n, structure.parent!))
      .toList();
}

List<ASTNode> buildCompleteMergedAst(
  TemplateStructure structure, {
  Map<String, BlockInfo>? overrides,
}) {
  final chain = structure.inheritanceChain;
  List<ASTNode> baseNodes = chain.first.nodes;
  Map<String, BlockInfo> currentOverrides = {...overrides ?? {}};

  resolverLogger.startScope('Building complete merged AST');

  // Process templates from most specific to least specific
  for (int i = chain.length - 1; i >= 0; i--) {
    final current = chain[i];
    resolverLogger.startScope('Processing template: ${current.templatePath}');
    resolverLogger.info(
      'Available blocks: (${current.resolvedBlocks.keys.join(', ')})',
    );

    // Collect overrides from this level
    for (var entry in current.resolvedBlocks.entries) {
      if (entry.value.isOverride && !currentOverrides.containsKey(entry.key)) {
        resolverLogger.info(
          'Adding override for block: ${entry.key} from ${current.templatePath}',
        );
        currentOverrides[entry.key] = entry.value;
      }
    }
    resolverLogger.endScope();
  }

  // Now process the base nodes with all collected overrides
  resolverLogger.startScope('Processing base nodes');
  resolverLogger.info(
    'Available overrides: ${currentOverrides.keys.join(', ')}',
  );
  baseNodes = _processNodesWithOverrides(
    baseNodes,
    chain.last,
    currentOverrides,
  );
  resolverLogger.endScope();

  resolverLogger.endScope('AST building completed');
  return _collapseNodes(baseNodes);
}

List<ASTNode> _processNodesWithOverrides(
  List<ASTNode> nodes,
  TemplateStructure structure,
  Map<String, BlockInfo> overrides,
) {
  List<ASTNode> result = [];

  for (var node in nodes) {
    if (node is Tag && node.name == 'block') {
      String? blockName = _getBlockName(node);
      resolverLogger.startScope('Processing block: $blockName');

      if (blockName != null) {
        // Check for both direct and nested block names
        BlockInfo? override = _findOverride(blockName, overrides);

        if (override != null && override.content != null) {
          resolverLogger.startScope('Processing override content');
          resolverLogger.info('Source: ${override.source}');
          resolverLogger.info('Is override: ${override.isOverride}');
          resolverLogger.info('Has super call: ${override.hasSuperCall}');

          // Process override content
          List<ASTNode> processedContent = [];
          for (var contentNode in override.content!) {
            if (contentNode is Tag &&
                contentNode.name == 'super' &&
                override.parent != null) {
              // For super() calls, process parent's content recursively
              for (var parentNode in override.parent!.content ?? []) {
                processedContent.addAll(
                  _processNodesWithOverrides(
                    [parentNode],
                    structure,
                    overrides,
                  ),
                );
              }
            } else {
              // For other nodes, process them recursively
              processedContent.addAll(
                _processNodesWithOverrides([contentNode], structure, overrides),
              );
            }
          }
          result.addAll(processedContent);
          resolverLogger.endScope('Override processing completed');
        } else {
          resolverLogger.info('No override found, processing block body');
          // No override found - process the block's body recursively
          result.addAll(
            node.body
                .expand(
                  (n) => _processNodesWithOverrides([n], structure, overrides),
                )
                .toList(),
          );
        }
      }
      resolverLogger.endScope();
    } else if (node is Tag) {
      resolverLogger.startScope('Processing non-block tag: ${node.name}');
      // Process other tags recursively
      final processedContent = node.content
          .expand((n) => _processNodesWithOverrides([n], structure, overrides))
          .toList();
      final processedBody = node.body
          .expand((n) => _processNodesWithOverrides([n], structure, overrides))
          .toList();
      result.add(Tag(node.name, processedContent, body: processedBody));
      resolverLogger.endScope();
    } else {
      result.add(node);
    }
  }

  return result;
}

BlockInfo? _findOverride(String blockName, Map<String, BlockInfo> overrides) {
  resolverLogger.startScope('Looking for override: $blockName');

  // Try direct match first (O(1) HashMap lookup)
  var override = overrides[blockName];
  if (override != null) {
    resolverLogger.endScope('Found direct override');
    return override;
  }

  // Build/retrieve nested name lookup cache for O(1) nested lookups
  // The cache maps simple names (e.g., "nav") to full names (e.g., "header.nav")
  var nestedLookup = _getOrBuildNestedLookup(overrides);
  var fullName = nestedLookup[blockName];
  if (fullName != null) {
    resolverLogger.endScope('Found nested override as $fullName');
    return overrides[fullName];
  }

  resolverLogger.endScope('No override found');
  return null;
}

/// Builds a reverse lookup map from simple block names to their full qualified names.
/// Caches the result for the same overrides map within a resolution pass.
Map<String, String> _getOrBuildNestedLookup(Map<String, BlockInfo> overrides) {
  // Return cached lookup if same overrides map
  if (identical(overrides, _lastOverridesMap) && _lastNestedLookup != null) {
    return _lastNestedLookup!;
  }

  final lookup = <String, String>{};
  for (var key in overrides.keys) {
    final lastDot = key.lastIndexOf('.');
    if (lastDot != -1) {
      final simpleName = key.substring(lastDot + 1);
      // Only store first match (most specific override wins)
      lookup.putIfAbsent(simpleName, () => key);
    }
  }

  _lastOverridesMap = overrides;
  _lastNestedLookup = lookup;
  return lookup;
}

List<ASTNode> _collapseNodes(List<ASTNode> nodes) {
  List<ASTNode> result = [];
  StringBuffer? textBuffer;

  for (var node in nodes) {
    if (node is TextNode) {
      textBuffer ??= StringBuffer();
      textBuffer.write(node.text);
    } else {
      if (textBuffer != null) {
        result.add(TextNode(textBuffer.toString()));
        textBuffer = null;
      }
      result.add(node);
    }
  }

  if (textBuffer != null) {
    result.add(TextNode(textBuffer.toString()));
  }

  return result;
}
