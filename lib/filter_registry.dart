typedef FilterFunction = dynamic Function(dynamic value, List<dynamic> arguments, Map<String, dynamic> namedArguments);

class FilterRegistry {
  static final Map<String, FilterFunction> _filters = {
    'upper': (value, args, namedArgs) => value.toString().toUpperCase(),
    'lower': (value, args, namedArgs) => value.toString().toLowerCase(),
    'length': (value, args, namedArgs) => value.toString().length,
    // Add more filters as needed
  };

  static void register(String name, FilterFunction function) {
    _filters[name] = function;
  }

  static FilterFunction? getFilter(String name) {
    return _filters[name];
  }
}