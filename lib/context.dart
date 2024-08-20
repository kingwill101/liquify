import 'filter_registry.dart';

class Environment {
  final List<Map<String, dynamic>> _variableStack;
  final Map<String, FilterFunction> _filters;

  Environment([Map<String, dynamic> data = const {}])
      : _variableStack = [data],
        _filters = {};

  Environment._clone(this._variableStack, this._filters);

  Environment clone() {
    // Deep copy the variable stack
    final clonedVariableStack = _variableStack
        .map((scope) => Map<String, dynamic>.from(scope))
        .toList();
    // Shallow copy the filters (assuming filters are immutable)
    final clonedFilters = Map<String, FilterFunction>.from(_filters);
    return Environment._clone(clonedVariableStack, clonedFilters);
  }

  Map<String, dynamic> get variables => _variableStack.last;

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
    for (var i = 0; i < _variableStack.length; i++) {
      if (_variableStack[i].containsKey(name)) {
        return _variableStack[i][name];
      }
    }
    throw Exception('Undefined variable: $name');
  }

  void setVariable(String name, dynamic value) {
    _variableStack.last[name] = value;
  }

  void registerFilter(String name, FilterFunction function) {
    _filters[name] = function;
  }

  FilterFunction? getFilter(String name) {
    return _filters[name];
  }
}
