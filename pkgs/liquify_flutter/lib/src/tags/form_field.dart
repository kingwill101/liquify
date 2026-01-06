import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class FormFieldTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  FormFieldTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildFormField(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildFormField(config, children));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('form_field').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endform_field').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'form_field',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _FormFieldConfig _parseConfig(Evaluator evaluator) {
    final config = _FormFieldConfig();
    Object? actionValue;
    Object? onSavedValue;
    String? widgetIdValue;
    String? widgetKeyValue;

    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'initialValue':
          config.initialValue = value?.toString();
          break;
        case 'enabled':
          config.enabled = toBool(value);
          break;
        case 'autovalidateMode':
          config.autovalidateMode = parseAutovalidateMode(value);
          break;
        case 'validator':
          config.validator = _resolveValidator(value);
          break;
        case 'onSaved':
          onSavedValue = value;
          break;
        case 'action':
          actionValue = value;
          break;
        case 'errorTextStyle':
          config.errorTextStyle = parseTextStyle(value);
          break;
        case 'id':
          widgetIdValue = value?.toString();
          break;
        case 'key':
          widgetKeyValue = value?.toString();
          break;
        default:
          handleUnknownArg('form_field', name);
          break;
      }
    }

    final ids = resolveIds(
      evaluator,
      'form_field',
      id: widgetIdValue,
      key: widgetKeyValue,
    );
    config.widgetKey = ids.key;
    final actionName = actionValue is String ? actionValue : null;
    final baseEvent = buildWidgetEvent(
      tag: 'form_field',
      id: ids.id,
      key: ids.keyValue,
      action: actionName,
      event: 'saved',
    );
    final onSaved =
        resolveStringActionCallback(
          evaluator,
          onSavedValue,
          event: baseEvent,
          actionValue: actionName,
        ) ??
        resolveStringActionCallback(
          evaluator,
          actionValue,
          event: baseEvent,
          actionValue: actionName,
        );
    if (onSaved != null) {
      config.onSaved = (value) {
        baseEvent['value'] = value;
        onSaved(value ?? '');
      };
    }
    if (onSavedValue is FormFieldSetter<String>) {
      config.onSaved = onSavedValue;
    }
    return config;
  }
}

class _FormFieldConfig {
  String? initialValue;
  bool? enabled;
  AutovalidateMode? autovalidateMode;
  FormFieldValidator<String>? validator;
  FormFieldSetter<String>? onSaved;
  TextStyle? errorTextStyle;
  Key? widgetKey;
}

FormField<String> _buildFormField(
  _FormFieldConfig config,
  List<Widget> children,
) {
  return FormField<String>(
    key: config.widgetKey,
    initialValue: config.initialValue,
    enabled: config.enabled ?? true,
    autovalidateMode: config.autovalidateMode,
    validator: config.validator,
    onSaved: config.onSaved,
    builder: (state) {
      final output = <Widget>[];
      if (children.isNotEmpty) {
        output.addAll(children);
      }
      if (state.hasError && state.errorText != null) {
        final theme = Theme.of(state.context);
        final style =
            config.errorTextStyle ??
            theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error);
        output.add(
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(state.errorText!, style: style),
          ),
        );
      }
      if (output.isEmpty) {
        return const SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: output,
      );
    },
  );
}

FormFieldValidator<String>? _resolveValidator(Object? value) {
  if (value is FormFieldValidator<String>) {
    return value;
  }
  if (value is String) {
    final message = value;
    if (message.trim().isEmpty) {
      return null;
    }
    return (input) {
      final trimmed = input?.trim() ?? '';
      if (trimmed.isEmpty) {
        return message;
      }
      return null;
    };
  }
  return null;
}
