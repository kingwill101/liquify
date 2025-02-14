import 'package:liquify/src/filters/module.dart';
import 'package:liquify/src/filters/filters.dart';

/// Represents a function that can be used as a filter in the Liquid template engine.
///
/// [value] The input value to be filtered.
/// [arguments] A list of positional arguments passed to the filter.
/// [namedArguments] A map of named arguments passed to the filter.
typedef FilterFunction = dynamic Function(dynamic value,
    List<dynamic> arguments, Map<String, dynamic> namedArguments);

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

  /// Registers a new filter function with the given name.
  ///
  /// [name] The name of the filter to be registered.
  /// [function] The filter function to be associated with the given name.
  /// [dotNotation] If true, the filter can be used with dot notation.
  static void register(String name, FilterFunction function,
      {bool dotNotation = false}) {
    _filters[name] = function;
    if (dotNotation) {
      _dotNotationFilters.add(name);
    }
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
  /// [name] The name of the filter to retrieve.
  ///
  /// Returns the filter function if found, or null if not found.
  static FilterFunction? getFilter(String name) {
    if (_filters.containsKey(name)) {
      return _filters[name];
    }
    // search in modules first
    for (var module in modules.values) {
      if (module.filters.containsKey(name)) {
        return module.filters[name];
      }
    }
    return null;
  }

  /// Registers a new module with the given name.
  ///
  /// [name] The name of the module to be registered.
  /// [module] The module to be associated with the given name.
  static void registerModule(String name, Module module) {
    module.register();
    modules[name] = module;
  }

  static void initModules() {
    for (var module in modules.values) {
      module.register();
    }
  }
}
