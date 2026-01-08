import 'package:liquify/parser.dart';

class PropertyScope {
  final Map<String, Object?> values = {};
}

const String _propertyScopeKey = '_liquify_flutter_property_scopes';
const String _propertyDefaultsKey = '_liquify_flutter_property_defaults';

void ensurePropertyResolver(Environment environment) {
  if (environment.getRegister(_propertyScopeKey) is! List<PropertyScope>) {
    environment.setRegister(_propertyScopeKey, <PropertyScope>[]);
  }
  if (environment.getRegister(_propertyDefaultsKey) is! Map<String, Object?>) {
    environment.setRegister(_propertyDefaultsKey, <String, Object?>{});
  }
}

PropertyScope pushPropertyScope(Environment environment) {
  final stack = _scopeStack(environment);
  final scope = PropertyScope();
  stack.add(scope);
  return scope;
}

void popPropertyScope(Environment environment, PropertyScope scope) {
  final stack = environment.getRegister(_propertyScopeKey);
  if (stack is! List<PropertyScope> || stack.isEmpty) {
    return;
  }
  if (identical(stack.last, scope)) {
    stack.removeLast();
  } else {
    stack.remove(scope);
  }
  if (stack.isEmpty) {
    environment.removeRegister(_propertyScopeKey);
  }
}

PropertyScope? currentPropertyScope(Environment environment) {
  final stack = environment.getRegister(_propertyScopeKey);
  if (stack is List<PropertyScope> && stack.isNotEmpty) {
    return stack.last;
  }
  return null;
}

void setPropertyValue(Environment environment, String name, Object? value) {
  final scope = currentPropertyScope(environment);
  if (scope != null) {
    scope.values[name] = value;
    return;
  }
  final defaults = _propertyDefaults(environment);
  defaults[name] = value;
}

bool hasPropertyValue(Environment environment, String name) {
  final scope = currentPropertyScope(environment);
  return scope?.values.containsKey(name) ?? false;
}

Object? getPropertyValue(Environment environment, String name) {
  final scope = currentPropertyScope(environment);
  return scope?.values[name];
}

bool hasPropertyDefault(Environment environment, String name) {
  final defaults = environment.getRegister(_propertyDefaultsKey);
  return defaults is Map<String, Object?> && defaults.containsKey(name);
}

Object? getPropertyDefault(Environment environment, String name) {
  final defaults = environment.getRegister(_propertyDefaultsKey);
  if (defaults is Map<String, Object?>) {
    return defaults[name];
  }
  return null;
}

T? resolvePropertyValue<T>({
  required Environment environment,
  required Map<String, Object?> namedArgs,
  required String name,
  required T? Function(Object? value) parser,
}) {
  if (namedArgs.containsKey(name)) {
    return parser(namedArgs[name]);
  }
  final scope = currentPropertyScope(environment);
  if (scope != null && scope.values.containsKey(name)) {
    return parser(scope.values[name]);
  }
  final defaults = environment.getRegister(_propertyDefaultsKey);
  if (defaults is Map<String, Object?> && defaults.containsKey(name)) {
    return parser(defaults[name]);
  }
  return null;
}

List<PropertyScope> _scopeStack(Environment environment) {
  final existing = environment.getRegister(_propertyScopeKey);
  if (existing is List<PropertyScope>) {
    return existing;
  }
  final stack = <PropertyScope>[];
  environment.setRegister(_propertyScopeKey, stack);
  return stack;
}

Map<String, Object?> _propertyDefaults(Environment environment) {
  final existing = environment.getRegister(_propertyDefaultsKey);
  if (existing is Map<String, Object?>) {
    return existing;
  }
  final defaults = <String, Object?>{};
  environment.setRegister(_propertyDefaultsKey, defaults);
  return defaults;
}
