import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class AppBarTag extends WidgetTagBase with AsyncTag {
  AppBarTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final resolvedTitle = resolvePropertyValue<Widget?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'title',
      parser: (value) => value is Widget ? value : null,
    );
    final title = resolvedTitle ?? config.titleWidget;
    final appBar = _buildAppBar(
      config,
      title: title ?? _resolveTitleWidget(config.title),
    );
    final hasScope = currentPropertyScope(evaluator.context) != null;
    setPropertyValue(evaluator.context, 'appBar', appBar);
    if (!hasScope) {
      buffer.write(appBar);
    }
    return null;
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final resolvedTitle = resolvePropertyValue<Widget?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'title',
      parser: (value) => value is Widget ? value : null,
    );
    final title = resolvedTitle ?? config.titleWidget;
    final appBar = _buildAppBar(
      config,
      title: title ?? _resolveTitleWidget(config.title),
    );
    final hasScope = currentPropertyScope(evaluator.context) != null;
    setPropertyValue(evaluator.context, 'appBar', appBar);
    if (!hasScope) {
      buffer.write(appBar);
    }
    return null;
  }

  _AppBarConfig _parseConfig(
    Evaluator evaluator,
    Map<String, Object?> namedValues,
  ) {
    final config = _AppBarConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'title':
        case 'label':
          if (value is Widget) {
            config.titleWidget = value;
            namedValues['title'] = value;
          } else {
            config.title = value?.toString();
          }
          break;
        case 'centerTitle':
          config.centerTitle = toBool(value);
          break;
        case 'backgroundColor':
        case 'background':
          config.backgroundColor = parseColor(value);
          break;
        case 'foregroundColor':
        case 'foreground':
          config.foregroundColor = parseColor(value);
          break;
        case 'elevation':
          config.elevation = toDouble(value);
          break;
        case 'shadowColor':
          config.shadowColor = parseColor(value);
          break;
        case 'surfaceTintColor':
          config.surfaceTintColor = parseColor(value);
          break;
        case 'automaticallyImplyLeading':
          config.automaticallyImplyLeading = toBool(value);
          break;
        case 'leading':
          config.leading = _resolveIconOrWidget(value);
          break;
        case 'leadingWidth':
          config.leadingWidth = toDouble(value);
          break;
        case 'actions':
          config.actions = _resolveActions(value);
          break;
        case 'toolbarHeight':
          config.toolbarHeight = toDouble(value);
          break;
        case 'titleSpacing':
          config.titleSpacing = toDouble(value);
          break;
        case 'bottom':
          if (value is PreferredSizeWidget) {
            config.bottom = value;
          }
          break;
        default:
          handleUnknownArg('app_bar', name);
          break;
      }
    }
    return config;
  }
}

class _AppBarConfig {
  String? title;
  Widget? titleWidget;
  bool? centerTitle;
  Color? backgroundColor;
  Color? foregroundColor;
  double? elevation;
  Color? shadowColor;
  Color? surfaceTintColor;
  bool? automaticallyImplyLeading;
  Widget? leading;
  double? leadingWidth;
  List<Widget>? actions;
  double? toolbarHeight;
  double? titleSpacing;
  PreferredSizeWidget? bottom;
}

PreferredSizeWidget _buildAppBar(_AppBarConfig config, {Widget? title}) {
  return AppBar(
    title: title,
    centerTitle: config.centerTitle,
    backgroundColor: config.backgroundColor,
    foregroundColor: config.foregroundColor,
    elevation: config.elevation,
    shadowColor: config.shadowColor,
    surfaceTintColor: config.surfaceTintColor,
    automaticallyImplyLeading: config.automaticallyImplyLeading ?? true,
    leading: config.leading,
    leadingWidth: config.leadingWidth,
    actions: config.actions,
    toolbarHeight: config.toolbarHeight,
    titleSpacing: config.titleSpacing,
    bottom: config.bottom,
  );
}

Widget? _resolveTitleWidget(String? title) {
  if (title != null && title.trim().isNotEmpty) {
    return Text(title.trim());
  }
  return null;
}

Widget? _resolveIconOrWidget(Object? value) {
  if (value is Widget) {
    return value;
  }
  final icon = resolveIconWidget(value);
  if (icon != null) {
    return icon;
  }
  return null;
}

List<Widget>? _resolveActions(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is Iterable) {
    final resolved = <Widget>[];
    for (final entry in value) {
      final widget = _resolveIconOrWidget(entry);
      if (widget != null) {
        resolved.add(widget);
      }
    }
    return resolved.isEmpty ? null : resolved;
  }
  final single = _resolveIconOrWidget(value);
  return single == null ? null : [single];
}
