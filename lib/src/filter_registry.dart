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
  static final Map<String, FilterFunction> _filters = {
    'upper': (value, args, namedArgs) => value.toString().toUpperCase(),
    'lower': (value, args, namedArgs) => value.toString().toLowerCase(),
    'length': (value, args, namedArgs) => value.toString().length,
  };

  /// Registers a new filter function with the given name.
  ///
  /// [name] The name of the filter to be registered.
  /// [function] The filter function to be associated with the given name.
  static void register(String name, FilterFunction function) {
    _filters[name] = function;
  }

  /// Retrieves a filter function by its name.
  ///
  /// [name] The name of the filter to retrieve.
  ///
  /// Returns the filter function if found, or null if not found.
  static FilterFunction? getFilter(String name) {
    return _filters[name];
  }
}
