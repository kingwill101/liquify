import 'grammar/shared.dart' show parseInput, ASTNode;

/// A global cache for parsed template ASTs.
///
/// This cache stores the parsed AST nodes keyed by the template content,
/// avoiding expensive re-parsing of templates that have already been parsed.
class TemplateCache {
  TemplateCache._();

  static final TemplateCache _instance = TemplateCache._();

  /// Gets the singleton instance of the template cache.
  static TemplateCache get instance => _instance;

  /// The internal cache map from template content to parsed AST.
  final Map<String, List<ASTNode>> _cache = {};

  /// Maximum number of templates to cache. Oldest entries are evicted when exceeded.
  int maxSize = 100;

  /// Keys in insertion order for LRU eviction.
  final List<String> _keys = [];

  /// Whether caching is enabled globally.
  bool enabled = true;

  /// Parses a template string, using the cache if available.
  ///
  /// If the template has been parsed before and caching is enabled,
  /// returns the cached AST. Otherwise, parses the template and caches
  /// the result.
  List<ASTNode> parse(String content) {
    if (!enabled || content.isEmpty) {
      return parseInput(content);
    }

    final cached = _cache[content];
    if (cached != null) {
      // Move to end for LRU
      _keys.remove(content);
      _keys.add(content);
      return cached;
    }

    final parsed = parseInput(content);
    _addToCache(content, parsed);
    return parsed;
  }

  void _addToCache(String content, List<ASTNode> parsed) {
    // Evict oldest if at capacity
    while (_keys.length >= maxSize && _keys.isNotEmpty) {
      final oldest = _keys.removeAt(0);
      _cache.remove(oldest);
    }

    _cache[content] = parsed;
    _keys.add(content);
  }

  /// Clears the entire cache.
  void clear() {
    _cache.clear();
    _keys.clear();
  }

  /// Removes a specific template from the cache.
  void invalidate(String content) {
    _cache.remove(content);
    _keys.remove(content);
  }

  /// Returns the current number of cached templates.
  int get size => _cache.length;

  /// Returns cache statistics for debugging.
  Map<String, dynamic> get stats => {
        'size': _cache.length,
        'maxSize': maxSize,
        'enabled': enabled,
      };
}

/// Global template cache instance for convenience.
final templateCache = TemplateCache.instance;
