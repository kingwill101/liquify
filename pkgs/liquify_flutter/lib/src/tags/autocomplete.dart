import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class AutocompleteTag extends WidgetTagBase with AsyncTag {
  AutocompleteTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    buffer.write(_buildAutocomplete(evaluator, config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    buffer.write(_buildAutocomplete(evaluator, config));
  }

  _AutocompleteConfig _parseConfig(Evaluator evaluator) {
    final config = _AutocompleteConfig();
    Object? actionValue;
    Object? onSelectedValue;
    String? widgetIdValue;
    String? widgetKeyValue;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'options':
          config.options = parseListOfString(value) ?? const [];
          break;
        case 'initialValue':
          config.initialValue = value?.toString();
          break;
        case 'onSelected':
          onSelectedValue = value;
          break;
        case 'action':
          actionValue = value;
          break;
        case 'id':
          widgetIdValue = value?.toString();
          break;
        case 'key':
          widgetKeyValue = value?.toString();
          break;
        default:
          handleUnknownArg('autocomplete', name);
          break;
      }
    }

    final resolvedId = resolveWidgetId(
      evaluator,
      'autocomplete',
      id: widgetIdValue,
      key: widgetKeyValue,
    );
    final resolvedKeyValue =
        (widgetKeyValue != null && widgetKeyValue.trim().isNotEmpty)
        ? widgetKeyValue.trim()
        : resolvedId;
    config.widgetKey = resolveWidgetKey(resolvedId, widgetKeyValue);
    final actionName = actionValue is String ? actionValue : null;
    final baseEvent = buildWidgetEvent(
      tag: 'autocomplete',
      id: resolvedId,
      key: resolvedKeyValue,
      action: actionName,
      event: 'selected',
      props: {'count': config.options.length},
    );
    final callback =
        resolveStringActionCallback(
          evaluator,
          onSelectedValue,
          event: baseEvent,
          actionValue: actionName,
        ) ??
        resolveStringActionCallback(
          evaluator,
          actionValue,
          event: baseEvent,
          actionValue: actionName,
        );
    config.onSelected = callback == null
        ? null
        : (value) {
            baseEvent['value'] = value;
            callback(value);
          };
    return config;
  }

  Widget _buildAutocomplete(Evaluator evaluator, _AutocompleteConfig config) {
    final options = config.options;
    final initialValue = config.initialValue;
    return Autocomplete<Object>(
      key: config.widgetKey,
      initialValue: initialValue == null
          ? null
          : TextEditingValue(text: initialValue),
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim();
        if (query.isEmpty) {
          return options;
        }
        final lowered = query.toLowerCase();
        return options.where(
          (option) => option.toLowerCase().contains(lowered),
        );
      },
      displayStringForOption: (option) => option.toString(),
      onSelected: (value) {
        final handler = config.onSelected;
        if (handler != null) {
          handler(value.toString());
        }
      },
    );
  }
}

class _AutocompleteConfig {
  List<String> options = const [];
  String? initialValue;
  ValueChanged<String>? onSelected;
  Key? widgetKey;
}
