export '../generated/type_parser_aliases.dart';

import 'package:flutter/material.dart';
import 'package:liquify/liquify.dart';
import 'package:liquify/parser.dart';
import '../generated/type_parser_aliases.dart';
import '../generated/type_parsers.dart' as generated_parsers;

List<Widget> withGap(
  List<Widget> children,
  Object? gapValue,
  Axis axis,
) {
  final gap = toDouble(gapValue);
  if (gap == null || gap <= 0 || children.length < 2) {
    return children;
  }
  final spaced = <Widget>[];
  for (var i = 0; i < children.length; i++) {
    if (i > 0) {
      spaced.add(
        SizedBox(
          width: axis == Axis.horizontal ? gap : null,
          height: axis == Axis.vertical ? gap : null,
        ),
      );
    }
    spaced.add(children[i]);
  }
  return spaced;
}

List<Widget> withSeparator(
  List<Widget> children,
  Widget? separator,
) {
  if (separator == null || children.length < 2) {
    return children;
  }
  final separated = <Widget>[];
  for (var i = 0; i < children.length; i++) {
    separated.add(children[i]);
    if (i < children.length - 1) {
      separated.add(KeyedSubtree(key: ValueKey('separator_$i'), child: separator));
    }
  }
  return separated;
}

Widget wrapChildren(List<Widget> children) {
  if (children.isEmpty) {
    return const SizedBox.shrink();
  }
  if (children.length == 1) {
    return children.first;
  }
  return Column(
    children: children,
  );
}

EdgeInsetsGeometry edgeInsetsFromNamedValues(
  Map<String, Object?> namedValues, {
  String? sourceName,
}) {
  double? all;
  double? horizontal;
  double? vertical;
  double? left;
  double? top;
  double? right;
  double? bottom;
  for (final entry in namedValues.entries) {
    final name = entry.key;
    final value = toDouble(entry.value);
    switch (name) {
      case 'all':
        all = value;
        break;
      case 'symmetric':
      case 'symetrical':
        horizontal = value;
        vertical = value;
        break;
      case 'horizontal':
        horizontal = value;
        break;
      case 'vertical':
        vertical = value;
        break;
      case 'left':
        left = value;
        break;
      case 'top':
        top = value;
        break;
      case 'right':
        right = value;
        break;
      case 'bottom':
        bottom = value;
        break;
      default:
        if (sourceName != null) {
          handleUnknownTagArg(sourceName, name);
        }
    }
  }

  if (all != null) {
    return EdgeInsets.all(all);
  }
  if (horizontal != null || vertical != null) {
    return EdgeInsets.symmetric(
      horizontal: horizontal ?? 0,
      vertical: vertical ?? 0,
    );
  }
  return EdgeInsets.only(
    left: left ?? 0,
    top: top ?? 0,
    right: right ?? 0,
    bottom: bottom ?? 0,
  );
}

Map<int, TableColumnWidth>? parseTableColumnWidths(Object? value) {
  if (value is Map) {
    final widths = <int, TableColumnWidth>{};
    for (final entry in value.entries) {
      final key = entry.key;
      final index = key is int ? key : int.tryParse(key.toString());
      if (index == null) {
        continue;
      }
      final width = parseTableColumnWidth(entry.value);
      if (width != null) {
        widths[index] = width;
      }
    }
    return widths.isEmpty ? null : widths;
  }
  return null;
}

double? toDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

String? toStringValue(Object? value) {
  if (value == null) {
    return null;
  }
  return value.toString();
}

int? toInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    var normalized = trimmed.toLowerCase();
    var hexCandidate = false;
    if (normalized.startsWith('#')) {
      hexCandidate = true;
      normalized = normalized.substring(1);
    }
    if (normalized.startsWith('0x')) {
      hexCandidate = true;
      normalized = normalized.substring(2);
    }
    if (RegExp(r'[a-f]').hasMatch(normalized)) {
      hexCandidate = true;
    }
    if (hexCandidate) {
      final parsed = int.tryParse(normalized, radix: 16);
      if (parsed != null) {
        return parsed;
      }
    }
    return int.tryParse(trimmed);
  }
  return null;
}

bool? toBool(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final lowered = value.toLowerCase();
    if (lowered == 'true') {
      return true;
    }
    if (lowered == 'false') {
      return false;
    }
  }
  return null;
}

bool strictPropertyParsing = false;

void setStrictPropertyParsing(bool value) {
  strictPropertyParsing = value;
}

bool strictTagParsing = false;

void setStrictTagParsing(bool value) {
  strictTagParsing = value;
}

void handleUnknownTagArg(String tagName, String name) {
  if (!strictTagParsing) {
    return;
  }
  throw Exception('$tagName tag does not support "$name"');
}

void _assertKnownKeys(
  Map<dynamic, dynamic> map,
  Set<String> allowed, {
  String? context,
}) {
  if (!strictPropertyParsing) {
    return;
  }
  final unknown = <String>[];
  for (final key in map.keys) {
    final normalized = key.toString();
    if (!allowed.contains(normalized)) {
      unknown.add(normalized);
    }
  }
  if (unknown.isEmpty) {
    return;
  }
  final label = context ?? 'property';
  throw Exception('Unsupported $label keys: ${unknown.join(', ')}');
}

ScrollPhysics? parseScrollPhysics(Object? value) {
  if (value is ScrollPhysics) {
    return value;
  }
  if (value is String) {
    final normalized =
        value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
    switch (normalized) {
      case 'never':
      case 'neverscrollable':
      case 'neverscrollphysics':
        return const NeverScrollableScrollPhysics();
      case 'always':
      case 'alwaysscrollable':
      case 'alwaysscrollphysics':
        return const AlwaysScrollableScrollPhysics();
      case 'bouncing':
      case 'bouncingscroll':
      case 'bouncingscrollphysics':
        return const BouncingScrollPhysics();
      case 'clamping':
      case 'clampingscroll':
      case 'clampingscrollphysics':
        return const ClampingScrollPhysics();
      case 'page':
      case 'pagescroll':
      case 'pagescrollphysics':
        return const PageScrollPhysics();
      case 'fixedextent':
      case 'fixedextentscroll':
      case 'fixedextentscrollphysics':
        return const FixedExtentScrollPhysics();
      case 'rangemaintaining':
      case 'rangemaintainingscroll':
      case 'rangemaintainingscrollphysics':
        return const RangeMaintainingScrollPhysics();
    }
  }
  return generated_parsers.parseGeneratedScrollPhysics(value);
}

Map<DismissDirection, double>? parseDismissThresholds(Object? value) {
  if (value is Map<DismissDirection, double>) {
    return value;
  }
  if (value is Map) {
    final result = <DismissDirection, double>{};
    value.forEach((key, val) {
      final direction = parseDismissDirection(key);
      final threshold = toDouble(val);
      if (direction != null && threshold != null) {
        result[direction] = threshold;
      }
    });
    return result.isEmpty ? null : result;
  }
  return null;
}

PreferredSizeWidget? parsePreferredSizeWidget(Object? value) {
  if (value is PreferredSizeWidget) {
    return value;
  }
  return null;
}

MaterialStatesController? parseMaterialStatesController(Object? value) {
  if (value is MaterialStatesController) {
    return value;
  }
  return null;
}

Future<void> Function()? parseAsyncCallback(
  Evaluator evaluator,
  Object? value,
) {
  final callback = resolveGenericCallback0(evaluator, value);
  if (callback == null) {
    return null;
  }
  return () async {
    final result = callback();
    if (result is Future) {
      await result;
    }
  };
}

double? parseStrokeAlign(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    final normalized =
        value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
    switch (normalized) {
      case 'inside':
      case 'strokealigninside':
        return CircularProgressIndicator.strokeAlignInside;
      case 'center':
      case 'strokealigncenter':
        return CircularProgressIndicator.strokeAlignCenter;
      case 'outside':
      case 'strokealignoutside':
        return CircularProgressIndicator.strokeAlignOutside;
    }
  }
  return toDouble(value);
}

ShapeBorder? parseShapeBorder(Object? value) {
  if (value is ShapeBorder) {
    return value;
  }
  if (value is String) {
    final normalized =
        value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
    switch (normalized) {
      case 'rounded':
      case 'roundedrectangle':
      case 'roundedrectangleborder':
        return const RoundedRectangleBorder();
      case 'stadium':
      case 'stadiumborder':
        return const StadiumBorder();
      case 'circle':
      case 'circleborder':
        return const CircleBorder();
    }
  }
  return generated_parsers.parseGeneratedShapeBorder(value);
}

const Set<String> _textStyleKeys = {
  'inherit',
  'color',
  'backgroundColor',
  'fontSize',
  'fontWeight',
  'fontStyle',
  'letterSpacing',
  'wordSpacing',
  'textBaseline',
  'height',
  'leadingDistribution',
  'locale',
  'foreground',
  'background',
  'shadows',
  'fontFeatures',
  'fontVariations',
  'decoration',
  'decorationColor',
  'decorationStyle',
  'decorationThickness',
  'debugLabel',
  'fontFamily',
  'fontFamilyFallback',
  'package',
  'overflow',
};

TextStyle? parseTextStyle(Object? value) {
  if (value is Map) {
    final map = <String, Object?>{};
    value.forEach((key, val) {
      map[key.toString()] = val;
    });
    final hasConstructor =
        map.containsKey('constructor') || map.containsKey('type');
    if (hasConstructor) {
      final payload = map.containsKey('args')
          ? map['args']
          : map.containsKey('values')
              ? map['values']
              : () {
                  final stripped = Map<String, Object?>.from(map);
                  stripped.remove('constructor');
                  stripped.remove('type');
                  stripped.remove('args');
                  stripped.remove('values');
                  return stripped;
                }();
      if (payload is Map) {
        final payloadMap = <String, Object?>{};
        payload.forEach((key, val) {
          payloadMap[key.toString()] = val;
        });
        _assertKnownKeys(payloadMap, _textStyleKeys, context: 'TextStyle');
      }
      return generated_parsers.parseGeneratedTextStyle(value);
    }
    if (map.length == 1 && map.keys.first.toLowerCase() == 'new') {
      final payload = map.values.first;
      if (payload is Map) {
        final payloadMap = <String, Object?>{};
        payload.forEach((key, val) {
          payloadMap[key.toString()] = val;
        });
        _assertKnownKeys(payloadMap, _textStyleKeys, context: 'TextStyle');
      }
      return generated_parsers.parseGeneratedTextStyle(value);
    }
    _assertKnownKeys(map, _textStyleKeys, context: 'TextStyle');
  }
  return generated_parsers.parseGeneratedTextStyle(value);
}

String formatDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

String formatTimeOfDay(TimeOfDay value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

WidgetStateProperty<Color?>? toWidgetStateColor(Object? value) {
  if (value is WidgetStateProperty<Color?>) {
    return value;
  }
  final color = parseColor(value);
  if (color != null) {
    return WidgetStatePropertyAll(color);
  }
  return null;
}

WidgetStateProperty<double?>? toWidgetStateDouble(Object? value) {
  if (value is WidgetStateProperty<double?>) {
    return value;
  }
  final number = toDouble(value);
  if (number != null) {
    return WidgetStatePropertyAll(number);
  }
  return null;
}

WidgetStateProperty<Icon?>? toWidgetStateIcon(Object? value) {
  if (value is WidgetStateProperty<Icon?>) {
    return value;
  }
  if (value is Icon) {
    return WidgetStatePropertyAll(value);
  }
  if (value is IconData) {
    return WidgetStatePropertyAll(Icon(value));
  }
  final props = <String, dynamic>{'icon': value};
  final resolved = resolveIcon(props);
  if (resolved != null) {
    return WidgetStatePropertyAll(Icon(resolved));
  }
  return null;
}

IconData? resolveIcon(Map<String, dynamic> props) {
  final codePoint = props['codePoint'] ?? props['code'];
  if (codePoint is num) {
    return IconData(codePoint.toInt(), fontFamily: 'MaterialIcons');
  }
  if (codePoint is String) {
    final parsed = int.tryParse(codePoint);
    if (parsed != null) {
      return IconData(parsed, fontFamily: 'MaterialIcons');
    }
  }
  final name = props['name']?.toString() ?? props['icon']?.toString();
  if (name == null) {
    return null;
  }
  return iconByName[name];
}

String resolveWidgetId(
  Evaluator evaluator,
  String tagName, {
  String? id,
  String? key,
}) {
  final provided = (id ?? key)?.trim();
  if (provided != null && provided.isNotEmpty) {
    return provided;
  }
  final env = evaluator.context;
  final counters =
      (env.getRegister('_liquify_flutter_widget_ids') as Map<String, int>?) ??
          <String, int>{};
  final next = (counters[tagName] ?? 0) + 1;
  counters[tagName] = next;
  env.setRegister('_liquify_flutter_widget_ids', counters);
  final namespace = (env.getRegister('_liquify_flutter_widget_ns') as String?) ??
      'env${identityHashCode(env)}';
  env.setRegister('_liquify_flutter_widget_ns', namespace);
  return '${namespace}_${tagName}_$next';
}

Key resolveWidgetKey(String id, [String? key]) {
  final value = (key != null && key.trim().isNotEmpty) ? key.trim() : id;
  return ValueKey<String>(value);
}

Map<String, dynamic> sanitizeProps(Map<String, Object?> props) {
  final sanitized = <String, dynamic>{};
  props.forEach((key, value) {
    if (value == null ||
        value is String ||
        value is num ||
        value is bool) {
      sanitized[key] = value;
      return;
    }
    sanitized[key] = value.toString();
  });
  return sanitized;
}

Map<String, dynamic> buildWidgetEvent({
  required String tag,
  required String id,
  String? key,
  String? action,
  Map<String, Object?>? props,
  String? event,
}) {
  final payload = <String, dynamic>{
    'tag': tag,
    'id': id,
  };
  if (key != null && key.isNotEmpty) {
    payload['key'] = key;
  }
  if (action != null && action.isNotEmpty) {
    payload['action'] = action;
  }
  if (event != null && event.isNotEmpty) {
    payload['event'] = event;
  }
  if (props != null && props.isNotEmpty) {
    payload['props'] = sanitizeProps(props);
  }
  return payload;
}

VoidCallback? toVoidCallback(Object? value) {
  if (value is VoidCallback) {
    return value;
  }
  if (value is Drop) {
    return () => _invokeDropAction(value, const ['tap', 'clicked']);
  }
  if (value is Function) {
    return () => value();
  }
  return null;
}

Widget? resolveIconWidget(Object? value) {
  if (value is Widget) {
    return value;
  }
  if (value is Icon) {
    return value;
  }
  if (value is IconData) {
    return Icon(value);
  }
  if (value == null) {
    return null;
  }
  if (value is Map) {
    final icon = resolveIcon(Map<String, dynamic>.from(value));
    return icon == null ? null : Icon(icon);
  }
  final icon = resolveIcon({'name': value.toString()});
  return icon == null ? null : Icon(icon);
}

Widget? resolveTextWidget(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is Widget) {
    return value;
  }
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : Text(trimmed);
  }
  return Text(value.toString());
}

Widget? resolveWidget(Object? value) {
  if (value is Widget) {
    return value;
  }
  return resolveTextWidget(value) ?? resolveIconWidget(value);
}

List<Widget>? resolveWidgetList(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is List<Widget>) {
    return value;
  }
  if (value is Iterable) {
    final widgets = <Widget>[];
    for (final entry in value) {
      final widget = resolveWidget(entry);
      if (widget != null) {
        widgets.add(widget);
      }
    }
    return widgets.isEmpty ? null : widgets;
  }
  final widget = resolveWidget(value);
  return widget == null ? null : [widget];
}

typedef ReorderActionCallback = void Function(int oldIndex, int newIndex);
typedef SortCallback = void Function(int columnIndex, bool ascending);

VoidCallback? resolveActionCallback(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}) {
  if (value is Drop) {
    return () => _withEvent(evaluator, event, () {
          _invokeDropAction(
            value,
            const ['tap', 'clicked'],
            event: event,
            actionValue: actionValue,
          );
        });
  }
  final direct = toVoidCallback(value);
  if (direct != null) {
    return () => _withEvent(evaluator, event, direct);
  }
  if (value is! String || value.isEmpty) {
    return null;
  }
  final actions = _resolveActions(evaluator);
  if (actions is Drop) {
    return () => _withEvent(evaluator, event, () {
          _invokeDropAction(
            actions,
            [value, 'tap', 'clicked'],
            event: event,
            actionValue: value,
          );
        });
  }
  if (actions is Map) {
    final entry = actions[value];
    final resolved = toVoidCallback(entry);
    if (resolved != null) {
      return () => _withEvent(evaluator, event, resolved);
    }
    if (entry is Drop) {
      return () => _withEvent(evaluator, event, () {
            _invokeDropAction(
              entry,
              const ['tap', 'clicked'],
              event: event,
              actionValue: value,
            );
          });
    }
    if (entry is VoidCallback) {
      return () => _withEvent(evaluator, event, entry);
    }
    if (entry is Function) {
      return () => _withEvent(evaluator, event, () => entry());
    }
  }
  if (actions is Function) {
    return () => _withEvent(evaluator, event, () => actions(value));
  }
  return null;
}

ValueChanged<bool>? resolveBoolActionCallback(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}
) {
  final direct = toBoolCallback(value);
  if (direct != null) {
    return direct;
  }
  if (value is! String || value.isEmpty) {
    return null;
  }
  final actions = _resolveActions(evaluator);
  if (actions is Drop) {
    return (state) => _withEvent(evaluator, event, () {
          _invokeDropAction(
            actions,
            [value, 'changed'],
            event: event,
            actionValue: value,
          );
        });
  }
  if (actions is Map) {
    final entry = actions[value];
    final resolved = toBoolCallback(entry);
    if (resolved != null) {
      return resolved;
    }
    if (entry is Drop) {
      return (state) => _withEvent(evaluator, event, () {
            _invokeDropAction(
              entry,
              const ['changed'],
              event: event,
              actionValue: value,
            );
          });
    }
    if (entry is ValueChanged<bool>) {
      return entry;
    }
    if (entry is Function) {
      return (state) => entry(state);
    }
  }
  if (actions is Function) {
    return (state) => actions(value, state);
  }
  return null;
}

bool Function(Object?)? resolveBoolPredicateCallback(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}
) {
  if (value is bool Function(Object?)) {
    return value;
  }
  if (value is Function) {
    return (payload) {
      try {
        final result = Function.apply(value, [payload]);
        return result is bool ? result : true;
      } on NoSuchMethodError {
        final result = Function.apply(value, const []);
        return result is bool ? result : true;
      }
    };
  }
  if (value is! String || value.isEmpty) {
    return null;
  }
  final actions = _resolveActions(evaluator);
  if (actions is Drop) {
    return (payload) {
      _withEvent(evaluator, event, () {
        _invokeDropAction(
          actions,
          [value, 'filter'],
          event: event,
          actionValue: value,
        );
      });
      return true;
    };
  }
  if (actions is Map) {
    final entry = actions[value];
    if (entry is bool Function(Object?)) {
      return entry;
    }
    if (entry is Function) {
      return (payload) {
        final result = Function.apply(entry, [payload]);
        return result is bool ? result : true;
      };
    }
    if (entry is Drop) {
      return (payload) {
        _withEvent(evaluator, event, () {
          _invokeDropAction(
            entry,
            [value, 'filter'],
            event: event,
            actionValue: value,
          );
        });
        return true;
      };
    }
  }
  if (actions is Function) {
    return (payload) {
      final result = Function.apply(actions, [value, payload]);
      return result is bool ? result : true;
    };
  }
  return null;
}

WidgetBuilder? resolveWidgetBuilderCallback(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}
) {
  if (value is WidgetBuilder) {
    return value;
  }
  if (value is Function) {
    return (context) {
      final result = Function.apply(value, [context]);
      return result is Widget ? result : const SizedBox.shrink();
    };
  }
  if (value is! String || value.isEmpty) {
    return null;
  }
  final actions = _resolveActions(evaluator);
  if (actions is Map) {
    final entry = actions[value];
    if (entry is WidgetBuilder) {
      return entry;
    }
    if (entry is Function) {
      return (context) {
        final result = Function.apply(entry, [context]);
        return result is Widget ? result : const SizedBox.shrink();
      };
    }
  }
  if (actions is Function) {
    return (context) {
      final result = Function.apply(actions, [value, context]);
      return result is Widget ? result : const SizedBox.shrink();
    };
  }
  if (actions is Drop) {
    return (context) {
      Widget? resolved;
      _withEvent(evaluator, event, () {
        resolved = actions.exec(Symbol(value)) as Widget?;
      });
      return resolved ?? const SizedBox.shrink();
    };
  }
  return null;
}

List<Widget> _coerceWidgetList(Object? value) {
  if (value is List<Widget>) {
    return value;
  }
  if (value is Widget) {
    return [value];
  }
  if (value is Iterable) {
    return value.whereType<Widget>().toList();
  }
  return const <Widget>[];
}

Widget _coerceWidget(Object? value) {
  if (value is Widget) {
    return value;
  }
  return const SizedBox.shrink();
}

List<Widget> Function(BuildContext)? resolveWidgetListBuilderCallback(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}
) {
  if (value is List<Widget> Function(BuildContext)) {
    return value;
  }
  if (value is Function) {
    return (context) => _coerceWidgetList(Function.apply(value, [context]));
  }
  if (value is! String || value.isEmpty) {
    return null;
  }
  final actions = _resolveActions(evaluator);
  if (actions is Map) {
    final entry = actions[value];
    if (entry is List<Widget> Function(BuildContext)) {
      return entry;
    }
    if (entry is Function) {
      return (context) =>
          _coerceWidgetList(Function.apply(entry, [context]));
    }
  }
  if (actions is Drop) {
    return (context) {
      Object? resolved;
      _withEvent(evaluator, event, () {
        resolved = actions.exec(Symbol(value));
      });
      return _coerceWidgetList(resolved);
    };
  }
  if (actions is Function) {
    return (context) =>
        _coerceWidgetList(Function.apply(actions, [value, context]));
  }
  return null;
}

List<Widget> Function(BuildContext, Object?)?
    resolveWidgetListBuilder2Callback(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}
) {
  if (value is List<Widget> Function(BuildContext, Object?)) {
    return value;
  }
  if (value is Function) {
    return (context, payload) =>
        _coerceWidgetList(Function.apply(value, [context, payload]));
  }
  if (value is! String || value.isEmpty) {
    return null;
  }
  final actions = _resolveActions(evaluator);
  if (actions is Map) {
    final entry = actions[value];
    if (entry is List<Widget> Function(BuildContext, Object?)) {
      return entry;
    }
    if (entry is Function) {
      return (context, payload) =>
          _coerceWidgetList(Function.apply(entry, [context, payload]));
    }
  }
  if (actions is Drop) {
    return (context, payload) {
      Object? resolved;
      _withEvent(evaluator, event, () {
        resolved = actions.exec(Symbol(value));
      });
      return _coerceWidgetList(resolved);
    };
  }
  if (actions is Function) {
    return (context, payload) => _coerceWidgetList(
        Function.apply(actions, [value, context, payload]));
  }
  return null;
}

Widget Function(BuildContext, Object?)? resolveWidgetBuilder2Callback(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}
) {
  if (value is Widget Function(BuildContext, Object?)) {
    return value;
  }
  if (value is Function) {
    return (context, payload) =>
        _coerceWidget(Function.apply(value, [context, payload]));
  }
  if (value is! String || value.isEmpty) {
    return null;
  }
  final actions = _resolveActions(evaluator);
  if (actions is Map) {
    final entry = actions[value];
    if (entry is Widget Function(BuildContext, Object?)) {
      return entry;
    }
    if (entry is Function) {
      return (context, payload) =>
          _coerceWidget(Function.apply(entry, [context, payload]));
    }
  }
  if (actions is Drop) {
    return (context, payload) {
      Object? resolved;
      _withEvent(evaluator, event, () {
        resolved = actions.exec(Symbol(value));
      });
      return _coerceWidget(resolved);
    };
  }
  if (actions is Function) {
    return (context, payload) =>
        _coerceWidget(Function.apply(actions, [value, context, payload]));
  }
  return null;
}

Object? Function(BuildContext)? resolveBuildContextCallback(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}
) {
  if (value is Object? Function(BuildContext)) {
    return value;
  }
  if (value is Function) {
    return (context) => Function.apply(value, [context]);
  }
  if (value is! String || value.isEmpty) {
    return null;
  }
  final actions = _resolveActions(evaluator);
  if (actions is Map) {
    final entry = actions[value];
    if (entry is Object? Function(BuildContext)) {
      return entry;
    }
    if (entry is Function) {
      return (context) => Function.apply(entry, [context]);
    }
    if (entry != null) {
      return (_) => entry;
    }
  }
  if (actions is Drop) {
    return (context) {
      Object? resolved;
      _withEvent(evaluator, event, () {
        resolved = actions.exec(Symbol(value));
      });
      return resolved;
    };
  }
  if (actions is Function) {
    return (context) => Function.apply(actions, [value, context]);
  }
  return null;
}

Object? Function(BuildContext, Object?)? resolveBuildContextCallback2(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}
) {
  if (value is Object? Function(BuildContext, Object?)) {
    return value;
  }
  if (value is Function) {
    return (context, payload) =>
        Function.apply(value, [context, payload]);
  }
  if (value is! String || value.isEmpty) {
    return null;
  }
  final actions = _resolveActions(evaluator);
  if (actions is Map) {
    final entry = actions[value];
    if (entry is Object? Function(BuildContext, Object?)) {
      return entry;
    }
    if (entry is Function) {
      return (context, payload) =>
          Function.apply(entry, [context, payload]);
    }
    if (entry != null) {
      return (_, __) => entry;
    }
  }
  if (actions is Drop) {
    return (context, payload) {
      Object? resolved;
      _withEvent(evaluator, event, () {
        resolved = actions.exec(Symbol(value));
      });
      return resolved;
    };
  }
  if (actions is Function) {
    return (context, payload) =>
        Function.apply(actions, [value, context, payload]);
  }
  return null;
}

Function? resolveCallbackValue(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}
) {
  if (value is Function) {
    return value;
  }
  if (value is! String || value.isEmpty) {
    return null;
  }
  final actions = _resolveActions(evaluator);
  if (actions is Map) {
    final entry = actions[value];
    if (entry is Function) {
      return entry;
    }
  }
  if (actions is Drop) {
    Object? resolved;
    _withEvent(evaluator, event, () {
      resolved = actions.exec(Symbol(value));
    });
    if (resolved is Function) {
      return resolved as Function;
    }
  }
  return null;
}

Object? Function()? resolveGenericCallback0(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}
) {
  if (value is Object? Function()) {
    return value;
  }
  if (value is Function) {
    return () => Function.apply(value, const []);
  }
  if (value is! String || value.isEmpty) {
    return null;
  }
  final actions = _resolveActions(evaluator);
  if (actions is Map) {
    final entry = actions[value];
    if (entry is Object? Function()) {
      return entry;
    }
    if (entry is Function) {
      return () => Function.apply(entry, const []);
    }
    if (entry != null) {
      return () => entry;
    }
  }
  if (actions is Drop) {
    return () {
      Object? resolved;
      _withEvent(evaluator, event, () {
        resolved = actions.exec(Symbol(value));
      });
      return resolved;
    };
  }
  if (actions is Function) {
    return () => Function.apply(actions, [value]);
  }
  return null;
}

Object? Function(Object?)? resolveGenericCallback1(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}
) {
  if (value is Object? Function(Object?)) {
    return value;
  }
  if (value is Function) {
    return (payload) => Function.apply(value, [payload]);
  }
  if (value is! String || value.isEmpty) {
    return null;
  }
  final actions = _resolveActions(evaluator);
  if (actions is Map) {
    final entry = actions[value];
    if (entry is Object? Function(Object?)) {
      return entry;
    }
    if (entry is Function) {
      return (payload) => Function.apply(entry, [payload]);
    }
    if (entry != null) {
      return (_) => entry;
    }
  }
  if (actions is Drop) {
    return (payload) {
      Object? resolved;
      _withEvent(evaluator, event, () {
        resolved = actions.exec(Symbol(value));
      });
      return resolved;
    };
  }
  if (actions is Function) {
    return (payload) => Function.apply(actions, [value, payload]);
  }
  return null;
}

SemanticFormatterCallback? parseSliderSemanticFormatter(
  Evaluator evaluator,
  Object? value,
) {
  if (value is SemanticFormatterCallback) {
    return value;
  }
  if (value is String) {
    final resolved = resolveGenericCallback1(evaluator, value);
    if (resolved != null) {
      return (double rawValue) {
        final result = resolved(rawValue);
        return result?.toString() ?? '';
      };
    }
    final template = value;
    return (double rawValue) {
      return template.replaceAll('{value}', rawValue.toString());
    };
  }
  final resolved = resolveGenericCallback1(evaluator, value);
  if (resolved == null) {
    return null;
  }
  return (double rawValue) {
    final result = resolved(rawValue);
    return result?.toString() ?? '';
  };
}

Object? Function(Object?, Object?)? resolveGenericCallback2(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}
) {
  if (value is Object? Function(Object?, Object?)) {
    return value;
  }
  if (value is Function) {
    return (a, b) => Function.apply(value, [a, b]);
  }
  if (value is! String || value.isEmpty) {
    return null;
  }
  final actions = _resolveActions(evaluator);
  if (actions is Map) {
    final entry = actions[value];
    if (entry is Object? Function(Object?, Object?)) {
      return entry;
    }
    if (entry is Function) {
      return (a, b) => Function.apply(entry, [a, b]);
    }
    if (entry != null) {
      return (_, __) => entry;
    }
  }
  if (actions is Drop) {
    return (a, b) {
      Object? resolved;
      _withEvent(evaluator, event, () {
        resolved = actions.exec(Symbol(value));
      });
      return resolved;
    };
  }
  if (actions is Function) {
    return (a, b) => Function.apply(actions, [value, a, b]);
  }
  return null;
}

void Function(Object?, Object?)? resolveGenericActionCallback2(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}
) {
  if (value is void Function(Object?, Object?)) {
    return value;
  }
  if (value is Function) {
    return (a, b) => Function.apply(value, [a, b]);
  }
  if (value is! String || value.isEmpty) {
    return null;
  }
  final actions = _resolveActions(evaluator);
  if (actions is Drop) {
    return (a, b) => _withEvent(evaluator, event, () {
          _invokeDropAction(
            actions,
            [value, 'changed'],
            event: event,
            actionValue: value,
          );
        });
  }
  if (actions is Map) {
    final entry = actions[value];
    if (entry is void Function(Object?, Object?)) {
      return entry;
    }
    if (entry is Function) {
      return (a, b) => Function.apply(entry, [a, b]);
    }
    if (entry is Drop) {
      return (a, b) => _withEvent(evaluator, event, () {
            _invokeDropAction(
              entry,
              const ['changed'],
              event: event,
              actionValue: value,
            );
          });
    }
  }
  if (actions is Function) {
    return (a, b) => Function.apply(actions, [value, a, b]);
  }
  return null;
}

Future<bool> Function()? resolveFutureBoolCallback0(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}
) {
  if (value is Future<bool> Function()) {
    return value;
  }
  if (value is Function) {
    return () async {
      final result = Function.apply(value, const []);
      if (result is Future<bool>) {
        return result;
      }
      if (result is Future<bool?>) {
        return (await result) ?? true;
      }
      if (result is bool) {
        return result;
      }
      if (result is bool?) {
        return result ?? true;
      }
      return true;
    };
  }
  if (value is! String || value.isEmpty) {
    return null;
  }
  final actions = _resolveActions(evaluator);
  if (actions is Map) {
    final entry = actions[value];
    if (entry is Future<bool> Function()) {
      return entry;
    }
    if (entry is Function) {
      return () async {
        final result = Function.apply(entry, const []);
        if (result is Future<bool>) {
          return result;
        }
        if (result is Future<bool?>) {
          return (await result) ?? true;
        }
        if (result is bool) {
          return result;
        }
        if (result is bool?) {
          return result ?? true;
        }
        return true;
      };
    }
  }
  if (actions is Drop) {
    return () async {
      Object? resolved;
      _withEvent(evaluator, event, () {
        resolved = actions.exec(Symbol(value));
      });
      if (resolved is Future<bool>) {
        return resolved as Future<bool>;
      }
      if (resolved is Future<bool?>) {
        return (await (resolved as Future<bool?>)) ?? true;
      }
      if (resolved is bool) {
        return resolved as bool;
      }
      if (resolved is bool?) {
        return (resolved as bool?) ?? true;
      }
      return true;
    };
  }
  if (actions is Function) {
    return () async {
      final result = Function.apply(actions, [value]);
      if (result is Future<bool>) {
        return result;
      }
      if (result is Future<bool?>) {
        return (await result) ?? true;
      }
      if (result is bool) {
        return result;
      }
      if (result is bool?) {
        return result ?? true;
      }
      return true;
    };
  }
  return null;
}

Future<bool?> Function(Object?)? resolveFutureBoolCallback1(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}
) {
  if (value is Future<bool?> Function(Object?)) {
    return value;
  }
  if (value is Function) {
    return (payload) async {
      final result = Function.apply(value, [payload]);
      if (result is Future<bool?>) {
        return result;
      }
      if (result is Future<bool>) {
        return await result;
      }
      if (result is bool) {
        return result;
      }
      if (result is bool?) {
        return result;
      }
      return true;
    };
  }
  if (value is! String || value.isEmpty) {
    return null;
  }
  final actions = _resolveActions(evaluator);
  if (actions is Map) {
    final entry = actions[value];
    if (entry is Future<bool?> Function(Object?)) {
      return entry;
    }
    if (entry is Function) {
      return (payload) async {
        final result = Function.apply(entry, [payload]);
        if (result is Future<bool?>) {
          return result;
        }
        if (result is Future<bool>) {
          return await result;
        }
        if (result is bool) {
          return result;
        }
        if (result is bool?) {
          return result;
        }
        return true;
      };
    }
  }
  if (actions is Drop) {
    return (payload) async {
      Object? resolved;
      _withEvent(evaluator, event, () {
        resolved = actions.exec(Symbol(value));
      });
      if (resolved is Future<bool?>) {
        return resolved as Future<bool?>;
      }
      if (resolved is Future<bool>) {
        return await (resolved as Future<bool>);
      }
      if (resolved is bool) {
        return resolved as bool;
      }
      if (resolved is bool?) {
        return resolved as bool?;
      }
      return true;
    };
  }
  if (actions is Function) {
    return (payload) async {
      final result = Function.apply(actions, [value, payload]);
      if (result is Future<bool?>) {
        return result;
      }
      if (result is Future<bool>) {
        return await result;
      }
      if (result is bool) {
        return result;
      }
      if (result is bool?) {
        return result;
      }
      return true;
    };
  }
  return null;
}

ValueChanged<dynamic>? resolveGenericValueChanged(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}
) {
  if (value is Drop) {
    return (payload) => _withEvent(evaluator, event, () {
          _invokeDropAction(
            value,
            const ['changed'],
            event: event,
            actionValue: actionValue,
          );
        });
  }
  if (value is Function) {
    return (payload) => _withEvent(evaluator, event, () {
          try {
            Function.apply(value, [payload]);
          } on NoSuchMethodError {
            Function.apply(value, const []);
          }
        });
  }
  if (value is! String || value.isEmpty) {
    return null;
  }
  final actions = _resolveActions(evaluator);
  if (actions is Drop) {
    return (payload) => _withEvent(evaluator, event, () {
          _invokeDropAction(
            actions,
            [value, 'changed'],
            event: event,
            actionValue: value,
          );
        });
  }
  if (actions is Map) {
    final entry = actions[value];
    if (entry is Drop) {
      return (payload) => _withEvent(evaluator, event, () {
            _invokeDropAction(
              entry,
              const ['changed'],
              event: event,
              actionValue: value,
            );
          });
    }
    if (entry is Function) {
      return (payload) {
        try {
          Function.apply(entry, [payload]);
        } on NoSuchMethodError {
          Function.apply(entry, const []);
        }
      };
    }
  }
  if (actions is Function) {
    return (payload) => Function.apply(actions, [value, payload]);
  }
  return null;
}

ValueChanged<String>? resolveStringActionCallback(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}
) {
  final direct = toStringCallback(value);
  if (direct != null) {
    return direct;
  }
  if (value is! String || value.isEmpty) {
    return null;
  }
  final actions = _resolveActions(evaluator);
  if (actions is Drop) {
    return (text) => _withEvent(evaluator, event, () {
          _invokeDropAction(
            actions,
            [value, 'changed'],
            event: event,
            actionValue: value,
          );
        });
  }
  if (actions is Map) {
    final entry = actions[value];
    final resolved = toStringCallback(entry);
    if (resolved != null) {
      return resolved;
    }
    if (entry is Drop) {
      return (text) => _withEvent(evaluator, event, () {
            _invokeDropAction(
              entry,
              const ['changed'],
              event: event,
              actionValue: value,
            );
          });
    }
    if (entry is ValueChanged<String>) {
      return entry;
    }
    if (entry is Function) {
      return (text) => entry(text);
    }
  }
  if (actions is Function) {
    return (text) => actions(value, text);
  }
  return null;
}

ReorderActionCallback? resolveReorderActionCallback(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}
) {
  if (value is ReorderActionCallback) {
    return value;
  }
  if (value is! String || value.isEmpty) {
    return null;
  }
  final actions = _resolveActions(evaluator);
  if (actions is Drop) {
    return (oldIndex, newIndex) {
      final payload =
          event == null ? <String, dynamic>{} : Map<String, dynamic>.from(event);
      payload['oldIndex'] = oldIndex;
      payload['newIndex'] = newIndex;
      _withEvent(evaluator, payload, () {
        _invokeDropAction(
          actions,
          [value, 'reorder'],
          event: payload,
          actionValue: value,
        );
      });
    };
  }
  if (actions is Map) {
    final entry = actions[value];
    if (entry is ReorderActionCallback) {
      return entry;
    }
    if (entry is Function) {
      return (oldIndex, newIndex) =>
          _withEvent(evaluator, event, () => entry(oldIndex, newIndex));
    }
    if (entry is Drop) {
      return (oldIndex, newIndex) {
        final payload = event == null
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(event);
        payload['oldIndex'] = oldIndex;
        payload['newIndex'] = newIndex;
        _withEvent(evaluator, payload, () {
          _invokeDropAction(
            entry,
            [value, 'reorder'],
            event: payload,
            actionValue: value,
          );
        });
      };
    }
  }
  if (actions is Function) {
    return (oldIndex, newIndex) =>
        _withEvent(evaluator, event, () => actions(value, oldIndex, newIndex));
  }
  return null;
}

SortCallback? resolveSortActionCallback(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}
) {
  if (value is SortCallback) {
    return value;
  }
  if (value is! String || value.isEmpty) {
    return null;
  }
  final actions = _resolveActions(evaluator);
  if (actions is Drop) {
    return (columnIndex, ascending) {
      final payload =
          event == null ? <String, dynamic>{} : Map<String, dynamic>.from(event);
      payload['columnIndex'] = columnIndex;
      payload['ascending'] = ascending;
      _withEvent(evaluator, payload, () {
        _invokeDropAction(
          actions,
          [value, 'sort'],
          event: payload,
          actionValue: value,
        );
      });
    };
  }
  if (actions is Map) {
    final entry = actions[value];
    if (entry is SortCallback) {
      return entry;
    }
    if (entry is Function) {
      return (columnIndex, ascending) =>
          _withEvent(evaluator, event, () => entry(columnIndex, ascending));
    }
    if (entry is Drop) {
      return (columnIndex, ascending) {
        final payload = event == null
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(event);
        payload['columnIndex'] = columnIndex;
        payload['ascending'] = ascending;
        _withEvent(evaluator, payload, () {
          _invokeDropAction(
            entry,
            [value, 'sort'],
            event: payload,
            actionValue: value,
          );
        });
      };
    }
  }
  if (actions is Function) {
    return (columnIndex, ascending) =>
        _withEvent(evaluator, event, () => actions(value, columnIndex, ascending));
  }
  return null;
}

FontWeight? _fontWeightFromInt(int value) {
  switch (value) {
    case 100:
      return FontWeight.w100;
    case 200:
      return FontWeight.w200;
    case 300:
      return FontWeight.w300;
    case 400:
      return FontWeight.w400;
    case 500:
      return FontWeight.w500;
    case 600:
      return FontWeight.w600;
    case 700:
      return FontWeight.w700;
    case 800:
      return FontWeight.w800;
    case 900:
      return FontWeight.w900;
  }
  return null;
}

ValueChanged<bool>? toBoolCallback(Object? value) {
  if (value is ValueChanged<bool>) {
    return value;
  }
  if (value is Function) {
    return (bool state) => value(state);
  }
  return null;
}

ValueChanged<double>? toDoubleCallback(Object? value) {
  if (value is ValueChanged<double>) {
    return value;
  }
  if (value is Function) {
    return (double number) => value(number);
  }
  return null;
}

ValueChanged<int>? toIntCallback(Object? value) {
  if (value is ValueChanged<int>) {
    return value;
  }
  if (value is Function) {
    return (int number) => value(number);
  }
  return null;
}

ValueChanged<String>? toStringCallback(Object? value) {
  if (value is ValueChanged<String>) {
    return value;
  }
  if (value is Function) {
    return (String text) => value(text);
  }
  return null;
}

ValueChanged<double>? resolveDoubleActionCallback(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}
) {
  final direct = toDoubleCallback(value);
  if (direct != null) {
    return (number) => _withEvent(evaluator, event, () => direct(number));
  }
  if (value is! String || value.isEmpty) {
    return null;
  }
  final actions = _resolveActions(evaluator);
  if (actions is Drop) {
    return (number) => _withEvent(evaluator, event, () {
          _invokeDropAction(
            actions,
            [value, 'changed'],
            event: event,
            actionValue: value,
          );
        });
  }
  if (actions is Map) {
    final entry = actions[value];
    final resolved = toDoubleCallback(entry);
    if (resolved != null) {
      return (number) => _withEvent(evaluator, event, () => resolved(number));
    }
    if (entry is Drop) {
      return (number) => _withEvent(evaluator, event, () {
            _invokeDropAction(
              entry,
              const ['changed'],
              event: event,
              actionValue: value,
            );
          });
    }
    if (entry is ValueChanged<double>) {
      return (number) => _withEvent(evaluator, event, () => entry(number));
    }
    if (entry is Function) {
      return (number) => _withEvent(evaluator, event, () => entry(number));
    }
  }
  if (actions is Function) {
    return (number) => _withEvent(evaluator, event, () => actions(value, number));
  }
  return null;
}

ValueChanged<int>? resolveIntActionCallback(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}
) {
  final direct = toIntCallback(value);
  if (direct != null) {
    return (number) => _withEvent(evaluator, event, () => direct(number));
  }
  if (value is! String || value.isEmpty) {
    return null;
  }
  final actions = _resolveActions(evaluator);
  if (actions is Drop) {
    return (number) => _withEvent(evaluator, event, () {
          _invokeDropAction(
            actions,
            [value, 'changed'],
            event: event,
            actionValue: value,
          );
        });
  }
  if (actions is Map) {
    final entry = actions[value];
    final resolved = toIntCallback(entry);
    if (resolved != null) {
      return (number) => _withEvent(evaluator, event, () => resolved(number));
    }
    if (entry is Drop) {
      return (number) => _withEvent(evaluator, event, () {
            _invokeDropAction(
              entry,
              const ['changed'],
              event: event,
              actionValue: value,
            );
          });
    }
    if (entry is ValueChanged<int>) {
      return (number) => _withEvent(evaluator, event, () => entry(number));
    }
    if (entry is Function) {
      return (number) => _withEvent(evaluator, event, () => entry(number));
    }
  }
  if (actions is Function) {
    return (number) => _withEvent(evaluator, event, () => actions(value, number));
  }
  return null;
}

ValueChanged<Set<int>>? toIntSetCallback(Object? value) {
  if (value is ValueChanged<Set<int>>) {
    return value;
  }
  if (value is Function) {
    return (Set<int> selection) => value(selection);
  }
  return null;
}

ValueChanged<Set<int>>? resolveIntSetActionCallback(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}
) {
  final direct = toIntSetCallback(value);
  if (direct != null) {
    return (selection) => _withEvent(evaluator, event, () => direct(selection));
  }
  if (value is! String || value.isEmpty) {
    return null;
  }
  final actions = _resolveActions(evaluator);
  if (actions is Drop) {
    return (selection) => _withEvent(evaluator, event, () {
          _invokeDropAction(
            actions,
            [value, 'changed'],
            event: event,
            actionValue: value,
          );
        });
  }
  if (actions is Map) {
    final entry = actions[value];
    final resolved = toIntSetCallback(entry);
    if (resolved != null) {
      return (selection) => _withEvent(evaluator, event, () => resolved(selection));
    }
    if (entry is Drop) {
      return (selection) => _withEvent(evaluator, event, () {
            _invokeDropAction(
              entry,
              const ['changed'],
              event: event,
              actionValue: value,
            );
          });
    }
    if (entry is ValueChanged<Set<int>>) {
      return (selection) => _withEvent(evaluator, event, () => entry(selection));
    }
    if (entry is Function) {
      return (selection) => _withEvent(evaluator, event, () => entry(selection));
    }
  }
  if (actions is Function) {
    return (selection) =>
        _withEvent(evaluator, event, () => actions(value, selection));
  }
  return null;
}

void _invokeDropAction(
  Drop drop,
  List<String> events, {
  Map<String, dynamic>? event,
  String? actionValue,
}) {
  final prevEvent = event == null ? null : drop.attrs['event'];
  final prevAction = event == null ? null : drop.attrs['action'];
  if (event != null) {
    drop.attrs['event'] = event;
  }
  if (actionValue != null) {
    drop.attrs['action'] = actionValue;
  }
  for (final eventName in events) {
    final symbol = Symbol(eventName);
    if (drop.invokable.contains(symbol) || drop.attrs.containsKey(eventName)) {
      final result = drop.exec(symbol);
      if (result is VoidCallback) {
        result();
      }
      if (event != null) {
        _restoreDropAttrs(drop, prevEvent, prevAction);
      }
      return;
    }
  }
  if (events.isNotEmpty) {
    final result = drop.exec(Symbol(events.first));
    if (result is VoidCallback) {
      result();
    }
  }
  if (event != null) {
    _restoreDropAttrs(drop, prevEvent, prevAction);
  }
}

Object? _resolveActions(Evaluator evaluator) {
  return evaluator.context.getVariable('actions') ??
      evaluator.context.getRegister('_liquify_flutter_actions') ??
      evaluator.context.getRegister('actions');
}

void _withEvent(
  Evaluator evaluator,
  Map<String, dynamic>? event,
  void Function() action,
) {
  if (event == null) {
    action();
    return;
  }
  final env = evaluator.context;
  final previous = env.getRegister('_liquify_flutter_event');
  env.setRegister('_liquify_flutter_event', event);
  try {
    action();
  } finally {
    if (previous == null) {
      env.removeRegister('_liquify_flutter_event');
    } else {
      env.setRegister('_liquify_flutter_event', previous);
    }
  }
}

void _restoreDropAttrs(
  Drop drop,
  Object? previousEvent,
  Object? previousAction,
) {
  if (previousEvent == null) {
    drop.attrs.remove('event');
  } else {
    drop.attrs['event'] = previousEvent;
  }
  if (previousAction == null) {
    drop.attrs.remove('action');
  } else {
    drop.attrs['action'] = previousAction;
  }
}

dynamic evaluatePositionalValue(
  Evaluator evaluator,
  List<ASTNode> content,
) {
  final positional = content.where((node) => node is! NamedArgument).toList();
  if (positional.isEmpty) {
    return null;
  }
  if (positional.length == 1) {
    return evaluator.evaluate(positional.first);
  }
  final buffer = StringBuffer();
  for (final node in positional) {
    buffer.write(evaluator.evaluate(node));
  }
  return buffer.toString();
}

const Map<String, IconData> iconByName = {
  'add': Icons.add,
  'close': Icons.close,
  'check': Icons.check,
  'menu': Icons.menu,
  'more_horiz': Icons.more_horiz,
  'more_vert': Icons.more_vert,
  'star': Icons.star,
  'favorite': Icons.favorite,
  'search': Icons.search,
  'settings': Icons.settings,
  'home': Icons.home,
  'person': Icons.person,
};
