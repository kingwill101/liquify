import 'package:flutter/material.dart';
import 'package:liquify/liquify.dart';
import 'package:lualike/lualike.dart' as lualike;

import 'flutter_template.dart';
import 'lua_callback_drop.dart';
import 'tag_registry.dart';

/// A stateful widget that renders a Liquid template with integrated Lua state management.
/// 
/// Each LiquidPage has its own LuaLike instance and state that persists across rebuilds.
/// Lua callbacks can call `rebuild()` to trigger a Flutter rebuild with the updated state.
/// 
/// Example:
/// ```dart
/// LiquidPage(
///   template: 'my_app/app.liquid',
///   root: myAssetRoot,
///   data: {'initialValue': 42},
/// )
/// ```
class LiquidPage extends StatefulWidget {
  const LiquidPage({
    super.key,
    required this.template,
    required this.root,
    this.data = const {},
    this.sharedState,
    this.onAction,
    this.useAsync = true,
  });

  /// The template file path relative to the root.
  final String template;
  
  /// The asset root for resolving templates.
  final Root root;
  
  /// Initial data to pass to the template.
  final Map<String, dynamic> data;

  /// Optional shared state map to persist data across pages.
  /// When provided, Lua get/set will read/write to this map.
  final Map<String, dynamic>? sharedState;
  
  /// Callback for handling navigation and other actions from the template.
  final void Function(String action)? onAction;
  
  /// Whether to use async rendering (required for Lua).
  final bool useAsync;

  @override
  State<LiquidPage> createState() => LiquidPageState();
}

class LiquidPageState extends State<LiquidPage> {
  /// The persistent state managed by this page.
  /// Lua's get/set functions read and write to this map.
  late final Map<String, dynamic> _state;
  
  /// The LuaLike instance for this page.
  lualike.LuaLike? _lua;
  
  /// Cached render future for async rendering.
  Future<Widget>? _renderFuture;

  /// Cached environment - reused across builds to avoid re-registration.
  Environment? _cachedEnvironment;
  
  /// Tracks if Flutter tags have been registered to the cached environment.
  bool _environmentConfigured = false;

  @override
  void initState() {
    super.initState();
    _state = widget.sharedState ?? <String, dynamic>{};
    // Initialize state from widget data
    _state.addAll(widget.data);
    _initLua();
  }

  @override
  void didUpdateWidget(LiquidPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.template != widget.template || 
        oldWidget.root != widget.root) {
      _renderFuture = null;
      _cachedEnvironment = null;
      _environmentConfigured = false;
      _initLua();
    }
  }

  void _initLua() {
    _lua = lualike.LuaLike();
    _configureLua(_lua!);
  }

  void _configureLua(lualike.LuaLike lua) {
    final globals = lua.vm.globals;
    
    // Block dangerous globals
    const blockedGlobals = <String>{
      'io', 'os', 'debug', 'package', 'coroutine', 'crypto',
      'dofile', 'loadfile', 'load', 'require', 'collectgarbage',
    };
    for (final name in blockedGlobals) {
      globals.defineGlobal(name, null);
    }

    // Expose get(key) - reads from persistent state
    lua.expose('get', (List<Object?> args) {
      if (args.isEmpty) {
        throw Exception('get(key) requires a key argument');
      }
      final key = _coerceKey(args.first);
      final value = _state[key];
      return lualike.toLuaValue(_toLuaInput(value));
    });

    // Expose set(key, value) - writes to persistent state
    lua.expose('set', (List<Object?> args) {
      if (args.length < 2) {
        throw Exception('set(key, value) requires 2 arguments');
      }
      final key = _coerceKey(args[0]);
      final value = _sanitizeData(lualike.fromLuaValue(args[1]));
      _state[key] = value;
      return null;
    });

    // Expose rebuild() - triggers Flutter rebuild
    lua.expose('rebuild', (List<Object?> args) {
      _triggerRebuild();
      return null;
    });

    // Expose log(...) - debug logging
    lua.expose('log', (List<Object?> args) {
      final message = args.isEmpty
          ? ''
          : args.map((v) => lualike.fromLuaValue(v)).join(' ');
      debugPrint('[lua] $message');
      return null;
    });

    // Expose action(name) - triggers onAction callback
    lua.expose('action', (List<Object?> args) {
      if (args.isEmpty) return null;
      final actionName = _coerceKey(args.first);
      widget.onAction?.call(actionName);
      return null;
    });

    // Expose callback(fn) - creates VoidCallback drop
    lua.expose('callback', (List<Object?> args) {
      if (args.isEmpty || args.first is! lualike.Value) {
        throw Exception('callback(fn) requires a Lua function');
      }
      return lualike.toLuaValue(
        LuaCallbackDrop(args.first as lualike.Value, lua),
      );
    });

    // Expose callback1(fn) - creates ValueChanged drop
    lua.expose('callback1', (List<Object?> args) {
      if (args.isEmpty || args.first is! lualike.Value) {
        throw Exception('callback1(fn) requires a Lua function');
      }
      return lualike.toLuaValue(
        LuaValueCallbackDrop(args.first as lualike.Value, lua),
      );
    });

    // Expose callback2(fn) - creates 2-arg callback drop
    lua.expose('callback2', (List<Object?> args) {
      if (args.isEmpty || args.first is! lualike.Value) {
        throw Exception('callback2(fn) requires a Lua function');
      }
      return lualike.toLuaValue(
        LuaCallback2Drop(args.first as lualike.Value, lua),
      );
    });
  }

  void _triggerRebuild() {
    if (!mounted) return;
    // Schedule rebuild after current frame to avoid re-entering Lua
    // while callbacks are still executing on the Lua call stack.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _renderFuture = null;
      });
    });
  }

  /// Allows external code to update state and trigger rebuild.
  void updateState(Map<String, dynamic> newState) {
    _state.addAll(newState);
    _triggerRebuild();
  }

  /// Gets a value from the page state.
  dynamic getState(String key) => _state[key];

  String _coerceKey(Object? value) {
    if (value is String) return value;
    final converted = lualike.fromLuaValue(value);
    if (converted is String) return converted;
    if (converted is num) return converted.toString();
    throw Exception('Key must be a string or number, got: ${converted.runtimeType}');
  }

  Object? _sanitizeData(Object? value) {
    if (value is lualike.Value) {
      return _sanitizeData(lualike.fromLuaValue(value));
    }
    if (value == null) return null;
    if (value is String || value is num || value is bool) return value;
    if (value is List) {
      final table = <int, Object?>{};
      for (var i = 0; i < value.length; i++) {
        table[i + 1] = _sanitizeData(value[i]);
      }
      return table;
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _sanitizeData(v)));
    }
    return value.toString();
  }

  Object? _toLuaInput(Object? value) {
    if (value is lualike.Value) {
      return _toLuaInput(lualike.fromLuaValue(value));
    }
    if (value == null) return null;
    if (value is String || value is num || value is bool) return value;
    if (value is List) {
      final table = <int, Object?>{};
      for (var i = 0; i < value.length; i++) {
        table[i + 1] = _toLuaInput(value[i]);
      }
      return table;
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _toLuaInput(v)));
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final padding = mediaQuery.padding;
    
    // Reuse cached environment or create new one
    final environment = _cachedEnvironment ??= Environment();
    
    // Register tags/filters only once per environment instance
    if (!_environmentConfigured) {
      environment.setRegister('_liquify_flutter_lua', _lua);
      environment.setRegister('_liquify_flutter_page_state', _state);
      environment.setRegister('_liquify_flutter_rebuild', _triggerRebuild);
      environment.setRegister('_liquify_flutter_strict_props', true);
      environment.setRegister('_liquify_flutter_strict_tags', true);
      environment.setRegister('_liquify_flutter_generated_only', true);
      environment.setRegister('_liquify_flutter_allow_sync_lua', true);
      registerFlutterTags(environment: environment);
      _environmentConfigured = true;
    }
    
    // Update context-specific register every build (context changes)
    environment.setRegister('_liquify_flutter_context', context);
    
    // Merge widget data with current state (state takes precedence)
    final mergedData = {
      ...widget.data,
      ..._state,
      'screen': {
        'width': size.width,
        'height': size.height,
        'orientation': mediaQuery.orientation.name,
        'devicePixelRatio': mediaQuery.devicePixelRatio,
        'safeTop': padding.top,
        'safeBottom': padding.bottom,
        'safeLeft': padding.left,
        'safeRight': padding.right,
        'safeWidth': size.width - padding.left - padding.right,
        'safeHeight': size.height - padding.top - padding.bottom,
      },
    };
    
    final templateInstance = FlutterTemplate.fromFile(
      widget.template,
      widget.root,
      environment: environment,
      data: mergedData,
    );

    if (!widget.useAsync) {
      return templateInstance.render();
    }

    _renderFuture ??= templateInstance.renderAsync();
    
    return FutureBuilder<Widget>(
      future: _renderFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final details = FlutterErrorDetails(
            exception: snapshot.error!,
            stack: snapshot.stackTrace,
            context: ErrorDescription('LiquidPage render'),
          );
          FlutterError.reportError(details);
          debugPrint(
            '[LiquidPage] render error: ${snapshot.error}\n${snapshot.stackTrace}',
          );
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return snapshot.data!;
      },
    );
  }
}
