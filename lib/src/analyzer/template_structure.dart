import 'package:liquify/parser.dart';
import 'package:logging/logging.dart';

import 'block_info.dart';

// Create a logger for this file.
final Logger logger = Logger('TemplateStructure');

initLogger() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}

/// Represents the structure of a Liquid template, including its blocks,
/// inheritance relationships, and content.
///
/// TemplateStructure is a key component in template analysis that:
/// * Maintains the hierarchy of template inheritance
/// * Tracks blocks and their relationships
/// * Provides methods to query and manipulate the template structure
///
/// The structure is built during template analysis and can be used to:
/// * Resolve block overrides
/// * Handle super() calls
/// * Generate the final merged template
class TemplateStructure {
  /// The path to this template file.
  final String templatePath;

  /// The AST nodes that make up this template's content.
  final List<ASTNode> nodes;

  /// Map of blocks defined in this template.
  ///
  /// The keys are block names (which may use dot notation for nested blocks)
  /// and the values are [BlockInfo] objects containing the block details.
  final Map<String, BlockInfo> blocks;

  /// The parent template structure if this template extends another.
  ///
  /// This is set when the template uses the `layout` or `extends` tag
  /// to inherit from another template.
  final TemplateStructure? parent;

  /// Creates a new template structure.
  ///
  /// Parameters:
  /// * [templatePath] - The path to this template file
  /// * [nodes] - The AST nodes of the template
  /// * [blocks] - Map of blocks defined in this template
  /// * [parent] - The parent template structure if this extends another
  const TemplateStructure({
    required this.templatePath,
    required this.nodes,
    required this.blocks,
    this.parent,
  });

  /// Returns true if this template extends another template
  bool get hasParent => parent != null;

  /// Returns the root template in the inheritance chain
  TemplateStructure get root {
    var current = this;
    while (current.parent != null) {
      current = current.parent!;
    }
    return current;
  }

  /// Returns true if this template has any blocks
  bool get hasBlocks => blocks.isNotEmpty;

  /// Returns the inheritance chain from root to leaf
  List<TemplateStructure> get inheritanceChain {
    final chain = <TemplateStructure>[];
    var current = this;
    while (current.parent != null) {
      chain.add(current);
      current = current.parent!;
    }
    chain.add(current); // Add the root template
    return chain.reversed.toList(); // Return from root to leaf
  }

  /// Returns the names of all blocks in this template
  Set<String> get blockNames => blocks.keys.toSet();

  /// Returns true if this template has a block with the given name
  bool hasBlock(String name) => blocks.containsKey(name);

  /// Gets the block info for a given block name
  BlockInfo? getBlock(String name) => blocks[name];

  /// Adds a block to this template's structure
  void addBlock(String name, BlockInfo info) {
    blocks[name] = info;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Template: $templatePath');
    if (hasParent) {
      buffer.writeln('Parent: ${parent!.templatePath}');
    }
    buffer.writeln('Blocks:');
    blocks.forEach((name, info) {
      buffer.writeln('  $name: $info');
    });
    return buffer.toString();
  }

  /// Returns a map of all blocks in this template and its parents.
  ///
  /// This method provides a complete view of all blocks available in the
  /// template hierarchy, with child template blocks taking precedence
  /// over parent template blocks.
  ///
  /// The returned map uses dot notation for nested blocks and includes
  /// override information.
  ///
  /// Example:
  /// ```dart
  /// final allBlocks = structure.resolvedBlocks;
  /// print(allBlocks['header']?.source); // Template where header is defined
  /// ```
  Map<String, BlockInfo> get resolvedBlocks {
    Map<String, BlockInfo> local = {};
    var ancestorChain = <TemplateStructure>[];
    var current = parent;
    while (current != null) {
      ancestorChain.add(current);
      current = current.parent;
    }
    for (var ancestor in ancestorChain.reversed) {
      final flattened = flatten(ancestor.blocks);
      local.addAll(flattened);
    }
    local.addAll(flatten(blocks));

    return local;
  }

  /// Converts this template structure to a JSON-compatible map.
  ///
  /// This is useful for:
  /// * Debugging template structures
  /// * Serializing template information
  /// * Generating documentation
  ///
  /// Returns a map containing:
  /// * name: The template path
  /// * parent: The parent template path (if any)
  /// * blocks: Map of blocks in this template
  /// * variables: Map of variables used in this template
  /// * dependencies: List of template dependencies
  /// * allBlockNames: List of all block names in this template
  Map<String, dynamic> toJson() {
    return {
      'name': templatePath,
      'parent': parent?.templatePath,
      'blocks': blocks.map((key, value) => MapEntry(key, value.toJson())),
      'variables': {},
      'dependencies': [],
      'allBlockNames': allBlockNames.toList(),
    };
  }

  /// Returns a flattened map of all blocks in this template.
  ///
  /// This method takes a map of blocks (potentially with nested blocks)
  /// and flattens it into a single map where nested block names use
  /// dot notation (e.g., "header.navigation").
  ///
  /// Parameters:
  /// * [blocks] - The blocks to flatten
  /// * [prefix] - Optional prefix for nested block names
  ///
  /// Returns a map where keys are the full block paths and values
  /// are the corresponding [BlockInfo] objects.
  ///
  /// Example:
  /// ```dart
  /// final flatBlocks = structure.flatten(blocks);
  /// print(flatBlocks['header.navigation']); // Prints nested block info
  /// ```
  Map<String, BlockInfo> flatten(Map<String, BlockInfo> blocks,
      {String prefix = ''}) {
    final map = <String, BlockInfo>{};
    blocks.forEach((key, blockInfo) {
      final fullName = prefix.isEmpty ? key : '$prefix.$key';

      // Check if any ancestor template has defined this block
      bool isOverride = false;
      var ancestor = parent;
      while (ancestor != null && !isOverride) {
        // Check direct blocks
        if (ancestor.blocks.containsKey(fullName) ||
            ancestor.blocks.containsKey(key)) {
          isOverride = true;
        } else {
          // Check nested blocks in each top-level block
          for (final block in ancestor.blocks.values) {
            if (block.nestedBlocks.containsKey(key)) {
              isOverride = true;
              break;
            }
          }
        }
        ancestor = ancestor.parent;
      }

      final effectiveBlock =
          isOverride ? blockInfo.copyWith(isOverride: true) : blockInfo;
      map[fullName] = effectiveBlock;

      // Also flatten any nested blocks
      if (blockInfo.nestedBlocks.isNotEmpty) {
        map.addAll(flatten(blockInfo.nestedBlocks, prefix: fullName));
      }
    });
    return map;
  }

  /// Returns a set of all block names in the inheritance chain.
  ///
  /// This includes block names from:
  /// * This template
  /// * All parent templates
  /// * All nested blocks in any template
  ///
  /// Example:
  /// ```dart
  /// final names = structure.allBlockNames;
  /// print(names.contains('header.navigation')); // Check if block exists
  /// ```
  Set<String> get allBlockNames {
    final names = <String>{};
    final inheritanceChain = <TemplateStructure>[];

    TemplateStructure? current = this;
    while (null != current) {
      inheritanceChain.add(current);
      current = current.parent;
    }
    void addBlockNames(Map<String, BlockInfo> blocks) {
      for (final block in blocks.values) {
        names.add(block.name);
        names.addAll(block.nestedBlocks.keys);
      }
    }

    for (final template in inheritanceChain) {
      addBlockNames(template.blocks);
    }
    return names;
  }

  /// Finds a block by its fully qualified name.
  ///
  /// This method can find both top-level and nested blocks using
  /// dot notation (e.g., "header.navigation").
  ///
  /// Parameters:
  /// * [name] - The fully qualified block name to find
  ///
  /// Returns the [BlockInfo] for the found block, or null if not found.
  ///
  /// Example:
  /// ```dart
  /// final navBlock = structure.findBlock('header.navigation');
  /// if (navBlock != null) {
  ///   print('Navigation defined in: ${navBlock.source}');
  /// }
  /// ```
  BlockInfo? findBlock(String name) {
    var parts = name.split('.');
    var container = blocks;
    BlockInfo? result;
    for (var part in parts) {
      result = container[part];
      if (result == null) {
        return null;
      }
      container = result.nestedBlocks;
    }
    return result;
  }

  /// Checks if this template or any of its parents has a block.
  ///
  /// This method searches for a block through the entire template
  /// inheritance chain, including nested blocks.
  ///
  /// Parameters:
  /// * [blockName] - The name of the block to find
  ///
  /// Returns true if the block is found anywhere in the inheritance chain.
  ///
  /// Example:
  /// ```dart
  /// if (structure.hasBlockInChain('navigation')) {
  ///   print('Navigation block exists in template hierarchy');
  /// }
  /// ```
  bool hasBlockInChain(String blockName) {
    // Check if this template has the block
    if (blocks.containsKey(blockName)) {
      return true;
    }
    // Check if any block in this template has the given block as a nested block
    for (final block in blocks.values) {
      if (block.nestedBlocks.containsKey(blockName)) {
        return true;
      }
    }
    // Check parent templates
    return parent?.hasBlockInChain(blockName) ?? false;
  }
}
