import 'package:liquify/liquify.dart';
import 'package:lualike/lualike.dart' as lualike;

/// A Drop that wraps a Lua function and can be used as a callback.
/// 
/// This enables defining callbacks in Lua templates:
/// ```liquid
/// {% lua assign: on_tap %}
///   return callback(function()
///     set("counter", get("counter") + 1)
///   end)
/// {% endlua %}
/// {% elevated_button onPressed: on_tap %}Click{% endelevated_button %}
/// ```
class LuaCallbackDrop extends Drop {
  LuaCallbackDrop(this._luaFunction, this._lua) {
    invokable = const [#execute, #tap, #clicked, #invoke];
  }

  final lualike.Value _luaFunction;
  final lualike.LuaLike _lua;

  @override
  dynamic invoke(Symbol symbol) {
    // Fire and forget - callbacks are usually void
    execute();
    return null;
  }

  /// Execute the Lua function with no arguments.
  /// Note: This is async internally but we fire-and-forget for sync callbacks.
  void execute([List<Object?>? args]) {
    final luaArgs = args?.map((a) => lualike.toLuaValue(a)).toList() ?? [];
    // Fire and forget - Lua execution is async
    _lua.vm.callFunction(_luaFunction, luaArgs).catchError((e) {
      throw Exception('Lua callback failed: $e');
    });
  }
}

/// A Drop that wraps a Lua function accepting one argument.
/// Used for callbacks like ValueChanged[T], onChanged, etc.
class LuaValueCallbackDrop extends Drop {
  LuaValueCallbackDrop(this._luaFunction, this._lua) {
    invokable = const [#execute, #tap, #clicked, #invoke];
  }

  final lualike.Value _luaFunction;
  final lualike.LuaLike _lua;

  @override
  dynamic invoke(Symbol symbol) {
    execute(null);
    return null;
  }

  /// Execute the Lua function with one argument.
  void execute(Object? value) {
    final luaValue = lualike.toLuaValue(value);
    _lua.vm.callFunction(_luaFunction, [luaValue]).catchError((e) {
      throw Exception('Lua callback failed: $e');
    });
  }
}

/// A Drop that wraps a Lua function accepting two arguments.
/// Used for callbacks like ReorderCallback(int, int), etc.
class LuaCallback2Drop extends Drop {
  LuaCallback2Drop(this._luaFunction, this._lua) {
    invokable = const [#execute, #tap, #clicked, #invoke];
  }

  final lualike.Value _luaFunction;
  final lualike.LuaLike _lua;

  @override
  dynamic invoke(Symbol symbol) {
    execute(null, null);
    return null;
  }

  /// Execute the Lua function with two arguments.
  void execute(Object? arg1, Object? arg2) {
    final luaArg1 = lualike.toLuaValue(arg1);
    final luaArg2 = lualike.toLuaValue(arg2);
    _lua.vm.callFunction(_luaFunction, [luaArg1, luaArg2]).catchError((e) {
      throw Exception('Lua callback failed: $e');
    });
  }
}

