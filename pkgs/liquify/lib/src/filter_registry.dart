import 'package:liquify/src/filters/module.dart';
import 'package:liquify/src/filters/filters.dart';

/// Represents a function that can be used as a filter in the Liquid template engine.
///
/// [value] The input value to be filtered.
/// [arguments] A list of positional arguments passed to the filter.
/// [namedArguments] A map of named arguments passed to the filter.
typedef FilterFunction =
    dynamic Function(
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    );

/// A registry for storing and retrieving filter functions.
class FilterRegistry {
  /// A map of filter names to their corresponding filter functions.
  static final Map<String, FilterFunction> _filters = {};
  static final Map<String, Module> modules = {
    'array': ArrayModule(),
    'date': DateModule(),
    'html': HtmlModule(),
    'math': MathModule(),
    'misc': MiscModule(),
    'string': StringModule(),
    'url': UrlModule(),
  };

  /// Cached unified filter lookup map for O(1) access.
  static Map<String, FilterFunction>? _unifiedFilters;

  /// Invalidates the unified filter cache.
  /// Call this after registering new filters or modules.
  static void _invalidateCache() {
    _unifiedFilters = null;
  }

  /// Registers a new filter function with the given name.
  ///
  /// [name] The name of the filter to be registered.
  /// [function] The filter function to be associated with the given name.
  /// [dotNotation] If true, the filter can be used with dot notation.
  static void register(
    String name,
    FilterFunction function, {
    bool dotNotation = false,
  }) {
    _filters[name] = function;
    if (dotNotation) {
      _dotNotationFilters.add(name);
    }
    _invalidateCache();
  }

  /// List of filters that can be used with dot notation.
  static final Set<String> _dotNotationFilters = {};

  /// Checks if a filter can be used with dot notation.
  ///
  /// [name] The name of the filter to check.
  ///
  /// Returns true if the filter can be used with dot notation, false otherwise.
  static bool isDotNotationFilter(String name) {
    return _dotNotationFilters.contains(name);
  }

  /// Retrieves a filter function by its name.
  ///
  /// Uses a cached unified lookup map for O(1) access instead of
  /// iterating through modules.
  ///
  /// [name] The name of the filter to retrieve.
  ///
  /// Returns the filter function if found, or null if not found.
  static FilterFunction? getFilter(String name) {
    // Build unified filter map lazily
    if (_unifiedFilters == null) {
      _unifiedFilters = <String, FilterFunction>{};
      // Add module filters first (lower priority)
      for (var module in modules.values) {
        _unifiedFilters!.addAll(module.filters);
      }
      // Add direct filters last (higher priority, overwrites module filters)
      _unifiedFilters!.addAll(_filters);
    }
    return _unifiedFilters![name];
  }

  /// Registers a new module with the given name.
  ///
  /// [name] The name of the module to be registered.
  /// [module] The module to be associated with the given name.
  static void registerModule(String name, Module module) {
    module.register();
    modules[name] = module;
    _invalidateCache();
  }

  static void initModules() {
    for (var module in modules.values) {
      module.register();
    }
    _invalidateCache();
  }

  /// Returns a list of all registered filter names from the global registry.
  /// This includes both directly registered filters and module filters.
  static List<String> getRegisteredFilterNames() {
    final filters = <String>{};

    // Add directly registered filters
    filters.addAll(_filters.keys);

    // Add module filters
    for (var module in modules.values) {
      filters.addAll(module.filters.keys);
    }

    return filters.toList();
  }
}
