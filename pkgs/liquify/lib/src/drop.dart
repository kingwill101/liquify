import 'package:gato/gato.dart' as gato;

extension SymbolExtension on Symbol {
  /// Retrieves the name of the Symbol without the "Symbol(\"" prefix and the trailing "\"".
  ///
  /// This extension method is defined on the Symbol type to provide a convenient way to get the
  /// name of a Symbol without the boilerplate of string manipulation.
  String get name {
    var name = toString();
    return toString()
        .replaceRange(name.length - 2, name.length, '')
        .replaceAll("Symbol(\"", '');
  }
}

/// The `Drop` class is an abstract class that provides a way to dynamically
/// invoke methods on an object. It maintains a list of invokable methods
/// (`invokable`) and a map of attributes (`attrs`). The `call` method is used
/// to invoke methods on the `Drop` object, and the `liquidMethodMissing` method
/// can be overridden to provide custom handling for missing methods.
abstract class Drop {
  List<Symbol> invokable = [];
  Map<String, dynamic> attrs = {};

  /// Handles the case where a method is missing from the `Drop` object.
  ///
  /// This method is called when a method is invoked on the `Drop` object that is not
  /// present in the `invokable` list. The default implementation returns `null`, but
  /// this method can be overridden in subclasses to provide custom handling for
  /// missing methods.
  ///
  /// @param method The Symbol representing the missing method.
  /// @return The result of handling the missing method, or `null` by default.
  dynamic liquidMethodMissing(Symbol method) => null;

  /// Invokes the method represented by the provided [attr] Symbol.
  ///
  /// This method first checks if the [attrs] map contains a value for the given [attr] name.
  /// If a value is found, it is returned.
  ///
  /// If the [invokable] list is not empty and contains the [attr] Symbol, the [invoke] method
  /// is called to execute the corresponding method.
  ///
  /// If neither of the above conditions are met, the [liquidMethodMissing] method is called
  /// to handle the missing method.
  dynamic call(Symbol attr) {
    if (get(attr.name) != null) return get(attr.name);
    if (invokable.isNotEmpty && invokable.contains(attr)) {
      return invoke(attr);
    }

    return liquidMethodMissing(attr);
  }

  /// Retrieves the value associated with the given [path] from the [attrs] map.
  ///
  /// This method is a helper for accessing values in the [attrs] map. It delegates
  /// the lookup to the [gato.get] function, which provides a convenient way to
  /// retrieve nested values from a map.
  dynamic operator [](String path) {
    return get(path);
  }

  /// Invokes the method represented by the provided [Symbol].
  ///
  /// This method is used to dynamically invoke a method on the `Drop` instance.
  /// If the method is present in the `invokable` list, it will be executed.
  /// Otherwise, the `liquidMethodMissing` method will be called to handle the
  /// missing method.
  dynamic invoke(Symbol symbol) {
    return null;
  }

  /// Invokes the method represented by the provided [Symbol].
  ///
  /// This method is used to dynamically invoke a method on the `Drop` instance.
  /// If the method is present in the `invokable` list, it will be executed.
  /// Otherwise, the `liquidMethodMissing` method will be called to handle the
  /// missing method.
  dynamic exec(Symbol method) {
    return this(method);
  }

  /// Retrieves the value associated with the given [path] from the [attrs] map.
  ///
  /// This method is a helper for accessing values in the [attrs] map. It delegates
  /// the lookup to the [gato.get] function, which provides a convenient way to
  /// retrieve nested values from a map.
  dynamic get(String path) {
    return gato.get(attrs, path);
  }
}
