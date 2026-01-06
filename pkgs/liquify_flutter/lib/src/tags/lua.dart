import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';
import 'package:lualike/lualike.dart' as lualike;

import 'tag_helpers.dart';

class LuaTag extends AbstractTag with CustomTagParser, AsyncTag {
  LuaTag(super.content, super.filters, [super.body]);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final allowSync =
        evaluator.context.getRegister('_liquify_flutter_allow_sync_lua') ==
        true;
    if (allowSync) {
      return null;
    }
    throw Exception('lua tag requires renderAsync()');
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    String? assignName;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'assign':
          if (arg.value is Identifier) {
            assignName = (arg.value as Identifier).name;
          } else {
            final resolved = evaluator.evaluate(arg.value);
            assignName = resolved?.toString().trim();
          }
          break;
        default:
          handleUnknownTagArg('lua', name);
          break;
      }
    }

    final script = _extractScript();
    if (script.trim().isEmpty) {
      return null;
    }

    final lua = lualike.LuaLike();
    _configureLua(lua, evaluator);

    final Object? result;
    try {
      result = await lua.execute(script, scriptPath: 'liquid:lua');
    } catch (error) {
      throw Exception('lua tag failed: $error');
    }

    final converted = _sanitizeData(lualike.fromLuaValue(result), path: 'lua');

    if (assignName != null && assignName.isNotEmpty) {
      evaluator.context.setVariable(assignName, converted);
    }
    return null;
  }

  String _extractScript() {
    if (body.isEmpty) {
      return '';
    }
    final buffer = StringBuffer();
    for (final node in body) {
      if (node is TextNode) {
        buffer.write(node.text);
      }
    }
    return buffer.toString();
  }

  void _configureLua(lualike.LuaLike lua, Evaluator evaluator) {
    final globals = lua.vm.globals;
    const blockedGlobals = <String>{
      'io',
      'os',
      'debug',
      'package',
      'coroutine',
      'crypto',
      'dofile',
      'loadfile',
      'load',
      'require',
      'collectgarbage',
    };
    for (final name in blockedGlobals) {
      globals.defineGlobal(name, null);
    }

    lua.expose('get', (List<Object?> args) {
      if (args.isEmpty) {
        throw Exception('lua get(name) requires a key');
      }
      final key = _coerceKey(args.first);
      final value = evaluator.context.getVariable(key);
      final sanitized = _sanitizeData(value, path: key);
      final luaReady = _toLuaInput(sanitized);
      return lualike.toLuaValue(luaReady);
    });

    lua.expose('set', (List<Object?> args) {
      if (args.length < 2) {
        throw Exception('lua set(name, value) requires 2 arguments');
      }
      final key = _coerceKey(args[0]);
      final value = _sanitizeData(lualike.fromLuaValue(args[1]), path: key);
      evaluator.context.setVariable(key, value);
      return null;
    });

    lua.expose('log', (List<Object?> args) {
      final message = args.isEmpty
          ? ''
          : args.map((value) => lualike.fromLuaValue(value)).join(' ');
      debugPrint('[lua] $message');
      return null;
    });
  }

  String _coerceKey(Object? value) {
    final raw = lualike.fromLuaValue(value);
    final key = raw?.toString().trim() ?? '';
    if (key.isEmpty) {
      throw Exception('lua key must be a non-empty string');
    }
    return key;
  }

  Object? _sanitizeData(Object? value, {required String path}) {
    if (value is lualike.Value) {
      return _sanitizeData(lualike.fromLuaValue(value), path: path);
    }
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is Widget) {
      throw Exception('lua tag only supports data, not widgets ($path)');
    }
    if (value is Iterable) {
      final items = <Object?>[];
      var index = 0;
      for (final entry in value) {
        items.add(
          _sanitizeData(lualike.fromLuaValue(entry), path: '$path[$index]'),
        );
        index += 1;
      }
      return items;
    }
    if (value is Map) {
      final mapped = <String, Object?>{};
      for (final entry in value.entries) {
        final rawKey = lualike.fromLuaValue(entry.key);
        if (rawKey is! String) {
          throw Exception('lua map keys must be strings ($path)');
        }
        mapped[rawKey] = _sanitizeData(
          lualike.fromLuaValue(entry.value),
          path: '$path.$rawKey',
        );
      }
      return mapped;
    }
    throw Exception('lua tag only supports data values ($path)');
  }

  Object? _toLuaInput(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is List) {
      final table = <int, Object?>{};
      for (var i = 0; i < value.length; i += 1) {
        table[i + 1] = _toLuaInput(value[i]);
      }
      return table;
    }
    if (value is Map) {
      final mapped = <String, Object?>{};
      for (final entry in value.entries) {
        mapped[entry.key.toString()] = _toLuaInput(entry.value);
      }
      return mapped;
    }
    return value;
  }

  @override
  Parser parser() {
    return (tagStart() &
            string('lua').trim() &
            tagContent().optional().trim() &
            tagEnd() &
            any()
                .starLazy((tagStart() & string('endlua').trim() & tagEnd()))
                .flatten() &
            tagStart() &
            string('endlua').trim() &
            tagEnd())
        .map((values) {
          final content = values[2] as List<ASTNode>? ?? const [];
          final script = values[4] as String? ?? '';
          return Tag('lua', content, body: [TextNode(script)]);
        });
  }
}
