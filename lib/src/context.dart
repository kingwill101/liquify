import 'filter_registry.dart';

class Environment {
  final List<Map<String, dynamic>> _variableStack;

  /*final Map<String, FilterFunction> _filters;*/

  Environment([Map<String, dynamic> data = const {}])
      : _variableStack = [data] /*_filters = {}*/;

  Environment._clone(
    this._variableStack,
    /*this._filters*/
  );

  Environment clone() {
    // Deep copy the variable stack
    final clonedVariableStack = _variableStack
        .map((scope) => Map<String, dynamic>.from(scope))
        .toList();
    // Shallow copy the filters (assuming filters are immutable)
    // final clonedFilters = Map<String, FilterFunction>.from(_filters);
    return Environment._clone(clonedVariableStack /*, clonedFilters*/);
  }

  call(String key) {
    return getVariable(key);
  }

  void pushScope() {
    _variableStack.add({});
  }

  void popScope() {
    if (_variableStack.length > 1) {
      _variableStack.removeLast();
    } else {
      throw Exception('Cannot pop the global scope.');
    }
  }

  dynamic getVariable(String name) {
    // Iterate from the top of the stack (most recent scope) to the bottom (global scope)
    for (var i = _variableStack.length - 1; i >= 0; i--) {
      if (_variableStack[i].containsKey(name)) {
        return _variableStack[i][name];
      }
    }
    return null;
  }

  void setVariable(String name, dynamic value) {
    if (_variableStack.length == 1 &&
        _variableStack.last == _variableStack.first) {
      // If we're still in the global scope, automatically push a new scope
      pushScope();
    }
    _variableStack.last[name] = value;
  }

  void registerFilter(String name, FilterFunction function) {
    FilterRegistry.register(name, function);
  }

  FilterFunction? getFilter(String name) {
    return FilterRegistry.getFilter(name);
  }
}
