library;

import 'dart:async';

import 'package:liquify_ui/liquify_ui.dart';
import 'package:flutter/widgets.dart';
export 'src/asset_bundle_root.dart';
export 'src/filters/responsive.dart';
export 'src/flutter_template.dart';
export 'src/tag_registry.dart';
export 'src/tags/tags.dart';
export 'src/widget_render_target.dart';

typedef UiElementBuilder =
    Widget Function(
      BuildContext context,
      UiElement element,
      UiNodeRenderer renderer,
    );

typedef UiActionHandler =
    FutureOr<void> Function(BuildContext context, Map<String, dynamic> action);

class UiWidgetRegistry {
  final Map<String, UiElementBuilder> _builders = {};

  void register(String type, UiElementBuilder builder) {
    _builders[type] = builder;
  }

  UiElementBuilder? resolve(String type) => _builders[type];
}

class UiActionRegistry {
  final Map<String, UiActionHandler> _handlers = {};

  void register(String type, UiActionHandler handler) {
    _handlers[type] = handler;
  }

  UiActionHandler? resolve(String type) => _handlers[type];
}

class UiNodeRenderer {
  UiNodeRenderer({UiWidgetRegistry? widgets, UiActionRegistry? actions})
    : widgets = widgets ?? UiWidgetRegistry(),
      actions = actions ?? UiActionRegistry();

  final UiWidgetRegistry widgets;
  final UiActionRegistry actions;

  Widget build(BuildContext context, UiDocument document) {
    return _wrapChildren(
      document.nodes.map((node) => buildNode(context, node)).toList(),
    );
  }

  Widget buildNode(BuildContext context, UiNode node) {
    if (node is UiText) {
      return Text(node.text);
    }
    if (node is UiElement) {
      return buildElement(context, node);
    }
    return _unknownNode('Unsupported node: ${node.runtimeType}');
  }

  Widget buildElement(BuildContext context, UiElement element) {
    final builder = widgets.resolve(element.type);
    if (builder != null) {
      return builder(context, element, this);
    }
    return _unknownNode('Unknown element: ${element.type}');
  }

  Future<void> handleAction(
    BuildContext context,
    Map<String, dynamic> action,
  ) async {
    final type = action['type'];
    if (type is! String) {
      return;
    }
    final handler = actions.resolve(type);
    if (handler == null) {
      _reportDiagnostic('Unknown action: $type');
      return;
    }
    await handler(context, action);
  }

  List<Widget> buildChildren(BuildContext context, List<UiNode> nodes) {
    return nodes.map((node) => buildNode(context, node)).toList();
  }

  Widget _unknownNode(String message) {
    _reportDiagnostic(message);
    return const SizedBox.shrink();
  }

  void _reportDiagnostic(String message) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: Exception(message),
        library: 'liquify_flutter',
      ),
    );
  }

  Widget _wrapChildren(List<Widget> children) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    if (children.length == 1) {
      return children.first;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
