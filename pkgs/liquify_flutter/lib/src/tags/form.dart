// ignore_for_file: deprecated_member_use
import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class FormTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  FormTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildForm(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildForm(config, children));
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('form').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endform').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'form',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _FormConfig _parseConfig(Evaluator evaluator) {
    final config = _FormConfig();
    final namedValues = <String, Object?>{};
    Object? actionValue;
    Object? onChangedValue;
    Object? onWillPopValue;
    String? widgetIdValue;
    String? widgetKeyValue;

    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'autovalidateMode':
          config.autovalidateMode = parseAutovalidateMode(value);
          break;
        case 'onChanged':
          onChangedValue = value;
          break;
        case 'onWillPop':
          onWillPopValue = value;
          break;
        case 'action':
          actionValue = value;
          break;
        case 'child':
          namedValues[name] = value;
          break;
        case 'id':
          widgetIdValue = value?.toString();
          break;
        case 'key':
          widgetKeyValue = value?.toString();
          break;
        default:
          handleUnknownArg('form', name);
          break;
      }
    }

    final ids = resolveIds(
      evaluator,
      'form',
      id: widgetIdValue,
      key: widgetKeyValue,
    );
    config.widgetKey = ids.key;
    final actionName = actionValue is String ? actionValue : null;
    final baseEvent = buildWidgetEvent(
      tag: 'form',
      id: ids.id,
      key: ids.keyValue,
      action: actionName,
      event: 'changed',
    );
    config.onChanged =
        resolveActionCallback(
              evaluator,
              onChangedValue,
              event: baseEvent,
              actionValue: actionName,
            ) ??
            resolveActionCallback(
              evaluator,
              actionValue,
              event: baseEvent,
              actionValue: actionName,
            );
    if (onWillPopValue is WillPopCallback) {
      config.onWillPop = onWillPopValue;
    }
    config.childOverride = resolvePropertyValue<Widget?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'child',
      parser: resolveTextWidget,
    );
    return config;
  }
}

class _FormConfig {
  AutovalidateMode? autovalidateMode;
  VoidCallback? onChanged;
  WillPopCallback? onWillPop;
  Widget? childOverride;
  Key? widgetKey;
}

Widget _buildForm(_FormConfig config, List<Widget> children) {
  final child = config.childOverride ?? wrapChildren(children);
  return Form(
    key: config.widgetKey,
    autovalidateMode: config.autovalidateMode,
    onChanged: config.onChanged,
    onWillPop: config.onWillPop,
    child: child,
  );
}
