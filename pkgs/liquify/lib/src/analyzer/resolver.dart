import 'package:liquify/parser.dart';
import 'package:liquify/src/analyzer/block_info.dart';
import 'package:liquify/src/analyzer/template_structure.dart';
import 'package:liquify/src/util.dart';

final resolverLogger = Logger('Resolver');

/// Recursive helper to merge a single AST node.
/// - If the node is a block tag, attempt to replace it with the resolved content.
/// - Otherwise, process its children (body and content) recursively.
List<ASTNode> _mergeNode(ASTNode node, TemplateStructure structure) {
  if (node is Tag && node.name == 'block') {
    final blockName = _getBlockName(node);
    resolverLogger
        .info("[_mergeNode] Processing block tag with name: $blockName");

    if (blockName == null) {
      resolverLogger
          .info("[_mergeNode] Block name is null, returning original node");
      return [node];
    }

    // First try to find a direct override for this block
    BlockInfo? block = structure.resolvedBlocks[blockName];
    resolverLogger.info(
        "[_mergeNode] Direct block lookup for '$blockName': ${block != null ? 'found' : 'not found'}");

    // If no direct override found, look for nested block override
    if (block == null) {
      final nestedBlockName = structure.resolvedBlocks.keys
          .firstWhere((key) => key.endsWith('.$blockName'), orElse: () => '');
      if (nestedBlockName.isNotEmpty) {
        block = structure.resolvedBlocks[nestedBlockName];
        resolverLogger
            .info("[_mergeNode] Found nested block override: $nestedBlockName");
      }
    }

    // If we found a block (either direct or nested)
    if (block != null && block.content != null) {
      resolverLogger.info(
          "[_mergeNode] Found block override: isOverride=${block.isOverride}, hasSuperCall=${block.hasSuperCall}");

      // If this is an override with super call, process it
      if (block.hasSuperCall) {
        resolverLogger
            .info("[_mergeNode] Processing super call for block: $blockName");
        return _processSuperCall(node, block, structure);
      }

      // If this is an override, use its content
      if (block.isOverride) {
        resolverLogger
            .info("[_mergeNode] Using override content for block: $blockName");
        return block.content!;
      }
    }

    resolverLogger.info(
        "[_mergeNode] No override found or not an override, processing block body");
    return node.body.expand((n) => _mergeNode(n, structure)).toList();
  }

  // For non-block nodes, recursively process children
  if (node is Tag) {
    resolverLogger.info("[_mergeNode] Processing non-block tag: ${node.name}");
    final newContent =
        node.content.expand((n) => _mergeNode(n, structure)).toList();
    final newBody = node.body.expand((n) => _mergeNode(n, structure)).toList();
    return [Tag(node.name, newContent, body: newBody)];
  }

  return [node];
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
    Tag node, BlockInfo block, TemplateStructure structure) {
  if (structure.parent == null) {
    return [];
  }

  // Get the block name without any parent prefixes
  final blockName = block.name.split('.').last;

  // Try to find the parent's version of this block
  BlockInfo? parentBlock = structure.parent!.resolvedBlocks[blockName];

  // If not found directly, look for it as a nested block
  if (parentBlock == null) {
    final nestedBlockName = structure.parent!.resolvedBlocks.keys
        .firstWhere((key) => key.endsWith('.$blockName'), orElse: () => '');
    if (nestedBlockName.isNotEmpty) {
      parentBlock = structure.parent!.resolvedBlocks[nestedBlockName];
    }
  }

  if (parentBlock == null || parentBlock.content == null) {
    return [];
  }

  // Process the parent's content recursively
  return parentBlock.content!
      .expand((n) => _mergeNode(n, structure.parent!))
      .toList();
}

List<ASTNode> buildCompleteMergedAst(TemplateStructure structure,
    {Map<String, BlockInfo>? overrides}) {
  final chain = structure.inheritanceChain;
  List<ASTNode> baseNodes = chain.first.nodes;
  Map<String, BlockInfo> currentOverrides = {
    ...overrides ?? {},
  };

  resolverLogger.startScope('Building complete merged AST');

  // Process templates from most specific to least specific
  for (int i = chain.length - 1; i >= 0; i--) {
    final current = chain[i];
    resolverLogger.startScope('Processing template: ${current.templatePath}');
    resolverLogger
        .info('Available blocks: (${current.resolvedBlocks.keys.join(', ')})');

    // Collect overrides from this level
    for (var entry in current.resolvedBlocks.entries) {
      if (entry.value.isOverride && !currentOverrides.containsKey(entry.key)) {
        resolverLogger.info(
            'Adding override for block: ${entry.key} from ${current.templatePath}');
        currentOverrides[entry.key] = entry.value;
      }
    }
    resolverLogger.endScope();
  }

  // Now process the base nodes with all collected overrides
  resolverLogger.startScope('Processing base nodes');
  resolverLogger
      .info('Available overrides: ${currentOverrides.keys.join(', ')}');
  baseNodes =
      _processNodesWithOverrides(baseNodes, chain.last, currentOverrides);
  resolverLogger.endScope();

  resolverLogger.endScope('AST building completed');
  return _collapseNodes(baseNodes);
}

List<ASTNode> _processNodesWithOverrides(List<ASTNode> nodes,
    TemplateStructure structure, Map<String, BlockInfo> overrides) {
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
              // For super() calls, process parent's content
              for (var parentNode in override.parent!.content ?? []) {
                if (parentNode is Tag && parentNode.name == 'nav') {
                  // For nav tags in parent content, extract only the text
                  processedContent.addAll(_extractTextContent(parentNode.body));
                } else {
                  processedContent.add(parentNode);
                }
              }
            } else {
              // For other nodes, process them recursively
              processedContent.addAll(_processNodesWithOverrides(
                  [contentNode], structure, overrides));
            }
          }
          result.addAll(processedContent);
          resolverLogger.endScope('Override processing completed');
        } else {
          resolverLogger.info('No override found, processing block body');
          // No override found - process the block's body recursively
          result.addAll(node.body
              .expand(
                  (n) => _processNodesWithOverrides([n], structure, overrides))
              .toList());
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

/// Helper function to recursively extract text content from nodes
List<ASTNode> _extractTextContent(List<ASTNode> nodes) {
  List<ASTNode> result = [];
  for (var node in nodes) {
    if (node is Tag) {
      result.addAll(_extractTextContent(node.body));
    } else if (node is TextNode) {
      result.add(node);
    }
  }
  return result;
}

BlockInfo? _findOverride(String blockName, Map<String, BlockInfo> overrides) {
  resolverLogger.startScope('Looking for override: $blockName');

  // Try direct match first
  var override = overrides[blockName];
  if (override != null) {
    resolverLogger.endScope('Found direct override');
    return override;
  }

  // Try nested notation
  for (var key in overrides.keys) {
    if (key.endsWith('.$blockName')) {
      resolverLogger.endScope('Found nested override as $key');
      return overrides[key];
    }
  }

  resolverLogger.endScope('No override found');
  return null;
}

List<ASTNode> _collapseNodes(List<ASTNode> nodes) {
  List<ASTNode> result = [];
  TextNode? currentText;

  for (var node in nodes) {
    if (node is TextNode) {
      if (currentText == null) {
        currentText = node;
      } else {
        currentText = TextNode(currentText.text + node.text);
      }
    } else {
      if (currentText != null) {
        result.add(currentText);
        currentText = null;
      }
      result.add(node);
    }
  }

  if (currentText != null) {
    result.add(currentText);
  }

  return result;
}

List<ASTNode> _applyOverride(ASTNode node, TemplateStructure structure,
    Map<String, BlockInfo> overrides) {
  if (node is Tag && node.name == 'block') {
    // Extract block name
    String? blockName;
    for (var child in node.content) {
      if (child is Identifier) {
        blockName = child.name;
        break;
      }
    }

    if (blockName != null) {
      // Check both direct and nested block names
      BlockInfo? override = overrides[blockName];
      if (override == null) {
        // Look for nested block notation
        for (var key in overrides.keys) {
          if (key.endsWith('.$blockName')) {
            override = overrides[key];
            break;
          }
        }
      }

      if (override != null && override.isOverride) {
        if (override.content != null) {
          return override.content!.expand((child) {
            if (child is Tag && child.name == 'super') {
              // Handle super() calls by using parent content
              return node.body.expand((parentChild) =>
                  _applyOverride(parentChild, structure, overrides));
            }
            return _applyOverride(child, structure, overrides);
          }).toList();
        }
      }
    }

    // If no override found or not marked as override, use original content
    return node.body
        .expand((child) => _applyOverride(child, structure, overrides))
        .toList();
  } else if (node is Tag) {
    // For other tags, process content and body
    final newContent = node.content
        .expand((child) => _applyOverride(child, structure, overrides))
        .toList();
    final newBody = node.body
        .expand((child) => _applyOverride(child, structure, overrides))
        .toList();
    return [Tag(node.name, newContent, body: newBody)];
  } else if (node is TextNode) {
    // Preserve TextNodes as-is
    return [node];
  } else {
    // Handle other node types
    return [node];
  }
}

List<ASTNode> resolveSuperCalls(
    List<ASTNode>? overrideContent,
    List<ASTNode>? parentContent,
    TemplateStructure structure,
    Map<String, BlockInfo> overrides) {
  if (overrideContent == null) return [];
  List<ASTNode> result = [];

  for (var node in overrideContent) {
    if (node is Tag && node.name == 'super') {
      // On super() call, inject parent content
      if (parentContent != null) {
        result.addAll(parentContent.expand((child) => _applyOverride(
            child, structure.parent!, structure.parent!.resolvedBlocks)));
      }
    } else if (node is TextNode) {
      // Preserve text nodes
      result.add(node);
    } else if (node is Tag) {
      // Process other tags recursively
      final newContent =
          resolveSuperCalls(node.content, parentContent, structure, overrides);
      final newBody =
          resolveSuperCalls(node.body, parentContent, structure, overrides);
      result.add(Tag(node.name, newContent, body: newBody));
    } else {
      result.add(node);
    }
  }
  return result;
}
