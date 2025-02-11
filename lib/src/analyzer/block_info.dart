import 'package:liquify/parser.dart';

/// Represents information about a block in a Liquid template.
///
/// A block is a section of a template that can be overridden by child templates.
/// BlockInfo tracks the block's content, inheritance relationships, and metadata
/// about how it's used in the template hierarchy.
///
/// Example of a block in a Liquid template:
/// ```liquid
/// {% block header %}
///   <header>Default content</header>
/// {% endblock %}
/// ```
///
/// The BlockInfo for this would contain:
/// * name: "header"
/// * content: The AST nodes for the header content
/// * isOverride: Whether this block overrides a parent template's block
/// * nestedBlocks: Any blocks defined within this block
class BlockInfo {
  /// The name of the block, which can be a simple name or a dot-notation path
  /// for nested blocks (e.g., "header.navigation").
  final String name;

  /// The source template path where this block is defined.
  final String source;

  /// The AST nodes that make up the block's content.
  ///
  /// This includes everything between the opening and closing block tags.
  final List<ASTNode>? content;

  /// Whether this block overrides a block from a parent template.
  ///
  /// This is true in cases like:
  /// * Direct override of a parent's block
  /// * Override of a nested block from an ancestor
  /// * Block defined in a child template that extends a parent
  final bool isOverride;

  /// The parent block if this is a nested block or an override.
  ///
  /// For example, if this is a "navigation" block nested inside a "header"
  /// block, [parent] would point to the "header" BlockInfo.
  final BlockInfo? parent;

  /// Map of blocks that are defined within this block.
  ///
  /// The keys are the simple names of the nested blocks, and the values
  /// are the BlockInfo objects for those blocks.
  final Map<String, BlockInfo> nestedBlocks;

  /// Whether this block contains a super() call to include parent content.
  ///
  /// When true, this block uses the `{{ super() }}` syntax to include
  /// the content from the parent template's version of this block.
  final bool hasSuperCall;

  /// Creates a new BlockInfo instance.
  ///
  /// All parameters except [content] are required:
  /// * [name] - The block's name or dot-notation path
  /// * [source] - The template path where this block is defined
  /// * [content] - The block's AST nodes (optional)
  /// * [isOverride] - Whether this overrides a parent block
  /// * [parent] - The parent block for nested blocks
  /// * [nestedBlocks] - Map of blocks defined within this one
  /// * [hasSuperCall] - Whether this block uses super()
  const BlockInfo({
    required this.name,
    required this.source,
    this.content,
    required this.isOverride,
    this.parent,
    required this.nestedBlocks,
    required this.hasSuperCall,
  });

  /// Creates a copy of this BlockInfo with optionally modified properties.
  ///
  /// This is useful when you need to create a variation of an existing
  /// BlockInfo while keeping most properties the same.
  ///
  /// Example:
  /// ```dart
  /// final overriddenBlock = originalBlock.copyWith(isOverride: true);
  /// ```
  BlockInfo copyWith({
    String? name,
    String? source,
    List<ASTNode>? content,
    bool? isOverride,
    BlockInfo? parent,
    Map<String, BlockInfo>? nestedBlocks,
    bool? hasSuperCall,
  }) {
    return BlockInfo(
      name: name ?? this.name,
      source: source ?? this.source,
      content: content ?? this.content,
      isOverride: isOverride ?? this.isOverride,
      parent: parent ?? this.parent,
      nestedBlocks: nestedBlocks ?? this.nestedBlocks,
      hasSuperCall: hasSuperCall ?? this.hasSuperCall,
    );
  }

  @override
  String toString() {
    return 'BlockInfo(name: $name, source: $source, isOverride: $isOverride, hasSuperCall: $hasSuperCall)';
  }

  /// Converts this block information to a JSON-compatible map structure.
  ///
  /// This is useful for:
  /// * Serializing block information
  /// * Debugging block structures
  /// * Generating reports
  ///
  /// Returns a map containing:
  /// * name: The block's name
  /// * source: The template path where this block is defined
  /// * isOverride: Whether this block overrides a parent block
  /// * hasSuperCall: Whether this block uses super()
  /// * hasParent: Whether this block has a parent block
  /// * parentSource: The source template of the parent block (if any)
  /// * nestedBlocks: Map of nested blocks within this block
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'source': source,
      'isOverride': isOverride,
      'hasSuperCall': hasSuperCall,
      'hasParent': parent != null,
      'parentSource': parent?.source,
      'nestedBlocks':
          nestedBlocks.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  /// Creates a deep copy of this block with a new source template.
  ///
  /// This method creates a completely new instance of BlockInfo and all its
  /// nested blocks, with the new source template path. This is useful when
  /// copying blocks between templates.
  ///
  /// Parameters:
  /// * [newSource] - The new template path to use as the source
  ///
  /// Returns a new [BlockInfo] instance with all nested blocks copied.
  ///
  /// Example:
  /// ```dart
  /// final copiedBlock = originalBlock.deepCopy('new_template.liquid');
  /// ```
  BlockInfo deepCopy(String newSource) {
    final nestedBlocksCopy = <String, BlockInfo>{};
    for (final nested in nestedBlocks.entries) {
      nestedBlocksCopy[nested.key] = nested.value.deepCopy(newSource);
    }
    return BlockInfo(
      name: name,
      source: newSource,
      content: content,
      isOverride: false,
      parent: this,
      nestedBlocks: nestedBlocksCopy,
      hasSuperCall: hasSuperCall,
    );
  }

  /// Creates a new BlockInfo with an additional nested block.
  ///
  /// Since BlockInfo is immutable, this method returns a new instance
  /// with the additional nested block added to the nestedBlocks map.
  ///
  /// Parameters:
  /// * [name] - The name of the nested block to add
  /// * [block] - The BlockInfo instance for the nested block
  ///
  /// Returns a new [BlockInfo] instance with the additional nested block.
  ///
  /// Example:
  /// ```dart
  /// final newBlock = block.withNestedBlock('navigation', navBlock);
  /// ```
  BlockInfo withNestedBlock(String name, BlockInfo block) {
    final newNestedBlocks = Map<String, BlockInfo>.from(nestedBlocks);
    newNestedBlocks[name] = block;
    return copyWith(nestedBlocks: newNestedBlocks);
  }

  /// Finds a nested block by its dot-notation path.
  ///
  /// This method traverses the nested block hierarchy using a dot-separated
  /// path to find a specific nested block.
  ///
  /// Parameters:
  /// * [path] - The dot-notation path to the nested block
  ///
  /// Returns the [BlockInfo] for the found block, or null if not found.
  ///
  /// Example:
  /// ```dart
  /// final navBlock = headerBlock.findNestedBlock('navigation.menu');
  /// ```
  BlockInfo? findNestedBlock(String path) {
    final parts = path.split('.');
    var current = this;
    for (var part in parts) {
      final block = current.nestedBlocks[part];
      if (block == null) return null;
      current = block;
    }
    return current;
  }
}
