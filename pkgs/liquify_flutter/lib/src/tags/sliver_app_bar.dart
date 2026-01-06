import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class SliverAppBarTag extends WidgetTagBase with AsyncTag {
  SliverAppBarTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    buffer.write(_buildAppBar(config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    buffer.write(_buildAppBar(config));
  }

  _SliverAppBarConfig _parseConfig(Evaluator evaluator) {
    final config = _SliverAppBarConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'title':
        case 'label':
          config.title = resolveTextWidget(value);
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
        case 'leading':
          config.leading = _resolveActionWidget(value);
          break;
        case 'actions':
          config.actions = _resolveActions(value);
          break;
        case 'pinned':
          config.pinned = toBool(value);
          break;
        case 'floating':
          config.floating = toBool(value);
          break;
        case 'snap':
          config.snap = toBool(value);
          break;
        case 'stretch':
          config.stretch = toBool(value);
          break;
        case 'expandedHeight':
          config.expandedHeight = toDouble(value);
          break;
        case 'collapsedHeight':
          config.collapsedHeight = toDouble(value);
          break;
        case 'toolbarHeight':
          config.toolbarHeight = toDouble(value);
          break;
        case 'forceElevated':
          config.forceElevated = toBool(value);
          break;
        case 'automaticallyImplyLeading':
          config.automaticallyImplyLeading = toBool(value);
          break;
        case 'flexibleSpace':
          if (value is Widget) {
            config.flexibleSpace = value;
          }
          break;
        case 'bottom':
          if (value is PreferredSizeWidget) {
            config.bottom = value;
          }
          break;
        default:
          handleUnknownArg('sliver_app_bar', name);
          break;
      }
    }
    return config;
  }
}

class _SliverAppBarConfig {
  Widget? title;
  bool? centerTitle;
  Color? backgroundColor;
  Color? foregroundColor;
  double? elevation;
  Color? shadowColor;
  Color? surfaceTintColor;
  Widget? leading;
  List<Widget>? actions;
  bool? pinned;
  bool? floating;
  bool? snap;
  bool? stretch;
  double? expandedHeight;
  double? collapsedHeight;
  double? toolbarHeight;
  bool? forceElevated;
  bool? automaticallyImplyLeading;
  Widget? flexibleSpace;
  PreferredSizeWidget? bottom;
}

SliverAppBar _buildAppBar(_SliverAppBarConfig config) {
  return SliverAppBar(
    title: config.title,
    centerTitle: config.centerTitle,
    backgroundColor: config.backgroundColor,
    foregroundColor: config.foregroundColor,
    elevation: config.elevation,
    shadowColor: config.shadowColor,
    surfaceTintColor: config.surfaceTintColor,
    leading: config.leading,
    actions: config.actions,
    pinned: config.pinned ?? false,
    floating: config.floating ?? false,
    snap: config.snap ?? false,
    stretch: config.stretch ?? false,
    expandedHeight: config.expandedHeight,
    collapsedHeight: config.collapsedHeight,
    toolbarHeight: config.toolbarHeight ?? kToolbarHeight,
    forceElevated: config.forceElevated ?? false,
    automaticallyImplyLeading: config.automaticallyImplyLeading ?? true,
    flexibleSpace: config.flexibleSpace,
    bottom: config.bottom,
  );
}

List<Widget>? _resolveActions(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is Iterable) {
    final resolved = <Widget>[];
    for (final entry in value) {
      final widget = _resolveActionWidget(entry);
      if (widget != null) {
        resolved.add(widget);
      }
    }
    return resolved.isEmpty ? null : resolved;
  }
  final single = _resolveActionWidget(value);
  return single == null ? null : [single];
}

Widget? _resolveActionWidget(Object? value) {
  if (value is Widget) {
    return value;
  }
  final icon = resolveIconWidget(value);
  if (icon != null) {
    return icon;
  }
  return resolveTextWidget(value);
}
