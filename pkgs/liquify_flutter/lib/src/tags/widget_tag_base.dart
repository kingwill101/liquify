import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';

abstract class WidgetTagBase extends AbstractTag {
  WidgetTagBase(super.content, super.filters);

  static List<Widget> asWidgets(Object? value) {
    if (value is List<Widget>) {
      return value;
    }
    if (value is Widget) {
      return [value];
    }
    if (value is String) {
      if (value.trim().isEmpty) {
        return const [];
      }
      return [Text(value)];
    }
    if (value is Iterable) {
      final widgets = <Widget>[];
      for (final entry in value) {
        widgets.addAll(asWidgets(entry));
      }
      return widgets;
    }
    if (value == null) {
      return const [];
    }
    return [Text(value.toString())];
  }

  @protected
  List<Widget> captureChildrenSync(Evaluator evaluator) {
    evaluator.startBlockCapture();
    evaluator.evaluateNodes(body);
    return asWidgets(evaluator.popBufferValue());
  }

  @protected
  Future<List<Widget>> captureChildrenAsync(Evaluator evaluator) async {
    evaluator.startBlockCapture();
    await evaluator.evaluateNodesAsync(body);
    return asWidgets(evaluator.popBufferValue());
  }

  @protected
  ({String id, String keyValue, Key key}) resolveIds(
    Evaluator evaluator,
    String tagName, {
    String? id,
    String? key,
  }) {
    final resolvedId = resolveWidgetId(evaluator, tagName, id: id, key: key);
    final resolvedKeyValue = (key != null && key.trim().isNotEmpty)
        ? key.trim()
        : resolvedId;
    final widgetKey = resolveWidgetKey(resolvedId, key);
    return (id: resolvedId, keyValue: resolvedKeyValue, key: widgetKey);
  }

  @protected
  void handleUnknownArg(String tagName, String name) {
    handleUnknownTagArg(tagName, name);
  }
}
