import 'package:liquify/src/fs.dart';

import 'filter_registry.dart';

/// Represents the execution environment for a code context.
///
/// The `Environment` class manages the variable stack and filters used within a
/// code context. It provides methods for pushing and popping scopes, as well as
/// accessing and modifying variables within the current scope.
enum BlockMode {
  output, // Normal template rendering
  store // Store blocks for layout
}

class Environment {
  final List<Map<String, dynamic>> _variableStack;
  final Map<String, dynamic> _registers;

  void setRegister(String key, dynamic value) {
    _registers[key] = value;
  }

  void removeRegister(String s) {
    _registers.remove(s);
  }

  get registers => _registers;

  dynamic getRegister(String key) {
    return _registers[key];
  }

  /// Constructs a new `Environment` instance with the provided initial data.
  ///
  /// The `Environment` class manages the variable stack and filters used within a
  /// code context. This constructor initializes the variable stack with the given
  /// `data` map, which represents the initial variables and their values.
  ///
  /// Parameters:
  /// - `data`: An optional map of initial variables and their values. Defaults to an empty map.
  Environment(
      [Map<String, dynamic> data = const {}, Map<String, dynamic>? register])
      : _variableStack = [data],
        _registers = register ?? {};

  Environment._clone(this._variableStack, this._registers);

  /// Creates a new [Environment] instance that is a deep copy of the current instance.
  ///
  /// This method creates a new [Environment] instance with a deep copy of the current
  /// variable stack. This ensures that any changes made to the new instance do not
  /// affect the original instance.
  ///
  /// Returns:
  ///   A new [Environment] instance that is a deep copy of the current instance.
  Environment clone() {
    // Deep copy the variable stack
    final clonedVariableStack = _variableStack
        .map((scope) => Map<String, dynamic>.from(scope))
        .toList();
    // Shallow copy the filters (assuming filters are immutable)
    // final clonedFilters = Map<String, FilterFunction>.from(_filters);
    final cloned = Environment._clone(clonedVariableStack, _registers);
    cloned._root = _root;
    return cloned;
  }

  Root? _root;

  void setRoot(Root? root) {
    _root = root;
  }

  Root? getRoot() {
    return _root;
  }

  call(String key) {
    return getVariable(key);
  }

  /// Pushes a new scope onto the variable stack.
  ///
  /// This creates a new empty scope that can be used to store variables. The new
  /// scope is added to the top of the variable stack, allowing variables to be
  /// accessed and modified within the current scope.
  void pushScope() {
    _variableStack.add({});
  }

  /// Removes the most recently added scope from the variable stack.
  ///
  /// If the global scope is the only remaining scope, an exception is thrown.
  void popScope() {
    if (_variableStack.length > 1) {
      _variableStack.removeLast();
    } else {
      throw Exception('Cannot pop the global scope.');
    }
  }

  /// Retrieves the value of a variable from the current scope or any parent scopes.
  ///
  /// This method searches the variable stack from the top (most recent scope) to the
  /// bottom (global scope) to find the first occurrence of the specified variable
  /// name. If the variable is found, its value is returned. If the variable is not
  /// found, `null` is returned.
  ///
  /// @param name The name of the variable to retrieve.
  /// @return The value of the variable, or `null` if the variable is not found.
  dynamic getVariable(String name) {
    // Iterate from the top of the stack (most recent scope) to the bottom (global scope)
    for (var i = _variableStack.length - 1; i >= 0; i--) {
      if (_variableStack[i].containsKey(name)) {
        return _variableStack[i][name];
      }
    }
    return null;
  }

  /// Sets a variable in the current scope.
  ///
  /// If the current scope is the global scope, a new scope is automatically pushed
  /// before setting the variable. This ensures that variables are always set in
  /// the current scope, rather than the global scope.
  ///
  /// @param name The name of the variable to set.
  /// @param value The value to assign to the variable.

  void setVariable(String name, dynamic value) {
    if (_variableStack.length == 1 &&
        _variableStack.last == _variableStack.first) {
      // If we're still in the global scope, automatically push a new scope
      pushScope();
    }
    _variableStack.last[name] = value;
  }

  /// Registers a new filter function with the given name.
  ///
  /// This method adds a new filter function to the [FilterRegistry] under the
  /// specified name. Filters can be used to transform or manipulate data in the
  /// context.
  ///
  /// @param name The name to register the filter function under.
  /// @param function The filter function to register.
  void registerFilter(String name, FilterFunction function) {
    FilterRegistry.register(name, function);
  }

  /// Gets the filter function registered with the given name.
  ///
  /// This method retrieves a filter function from the [FilterRegistry] by the
  /// specified name. If the filter is not found, it returns `null`.
  ///
  /// @param name The name of the filter function to retrieve.
  /// @return The filter function registered with the given name, or `null` if not found.
  FilterFunction? getFilter(String name) {
    return FilterRegistry.getFilter(name);
  }

  /// Clears the variable stack and adds a new global scope.
  ///
  /// This method is used to reset the context to a clean state, removing all
  /// previously set variables and scopes. It ensures that the context starts
  /// with a fresh global scope.
  void clear() {
    _variableStack.clear();
    _variableStack.add({});
  }

  /// Merges new data into the current scope.
  ///
  /// This method takes a map of new data and merges it into the current scope.
  /// If a variable with the same name already exists in the current scope,
  /// its value will be overwritten with the new value.
  ///
  /// @param newData A map containing the new data to be merged.
  void merge(Map<String, dynamic> newData) {
    newData.forEach((key, value) {
      setVariable(key, value);
    });
  }

  /// Returns a map containing all variables in the current context.
  ///
  /// This method iterates through the variable stack and collects all the
  /// variables defined in the current context, merging them into a single map.
  /// The resulting map contains all the variables that are currently in scope.
  Map<String, dynamic> all() {
    Map<String, dynamic> result = {};
    for (var scope in _variableStack) {
      result.addAll(scope);
    }
    return result;
  }
}
