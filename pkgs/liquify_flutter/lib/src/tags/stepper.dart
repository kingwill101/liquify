import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class StepperTag extends WidgetTagBase with AsyncTag {
  StepperTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    buffer.write(_buildStepper(config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    buffer.write(_buildStepper(config));
  }

  _StepperConfig _parseConfig(Evaluator evaluator) {
    final config = _StepperConfig();
    Object? actionValue;
    Object? onStepTappedValue;
    Object? onContinueValue;
    Object? onCancelValue;
    String? widgetIdValue;
    String? widgetKeyValue;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'steps':
        case 'items':
          config.steps = _parseSteps(value);
          break;
        case 'currentStep':
        case 'selectedIndex':
        case 'value':
          config.currentStep = toInt(value);
          break;
        case 'type':
          config.type = _parseStepperType(value);
          break;
        case 'showControls':
        case 'controls':
          config.showControls = toBool(value);
          break;
        case 'action':
          actionValue = value;
          break;
        case 'onStepTapped':
          onStepTappedValue = value;
          break;
        case 'continueAction':
        case 'onStepContinue':
          onContinueValue = value;
          break;
        case 'cancelAction':
        case 'onStepCancel':
          onCancelValue = value;
          break;
        case 'id':
          widgetIdValue = value?.toString();
          break;
        case 'key':
          widgetKeyValue = value?.toString();
          break;
        default:
          handleUnknownArg('stepper', name);
          break;
      }
    }

    config.steps ??= const [];
    if (config.steps!.isEmpty) {
      config.steps = [
        _StepItem(title: 'Step 1', content: const Text('Step 1')),
        _StepItem(title: 'Step 2', content: const Text('Step 2')),
      ];
    }
    final resolvedId = resolveWidgetId(
      evaluator,
      'stepper',
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
      tag: 'stepper',
      id: resolvedId,
      key: resolvedKeyValue,
      action: actionName,
      event: 'changed',
      props: {
        'count': config.steps!.length,
      },
    );
    final tappedCallback =
        resolveIntActionCallback(
              evaluator,
              onStepTappedValue,
              event: baseEvent,
              actionValue: actionName,
            ) ??
            resolveIntActionCallback(
              evaluator,
              actionValue,
              event: baseEvent,
              actionValue: actionName,
            );
    config.onStepTapped = tappedCallback == null
        ? null
        : (index) {
            baseEvent['index'] = index;
            if (index >= 0 && index < config.steps!.length) {
              baseEvent['value'] = config.steps![index].title;
            }
            tappedCallback(index);
          };
    config.onStepContinue = resolveActionCallback(
      evaluator,
      onContinueValue,
      event: {...baseEvent, 'event': 'continue'},
      actionValue: onContinueValue is String ? onContinueValue : actionName,
    );
    config.onStepCancel = resolveActionCallback(
      evaluator,
      onCancelValue,
      event: {...baseEvent, 'event': 'cancel'},
      actionValue: onCancelValue is String ? onCancelValue : actionName,
    );
    return config;
  }
}

class _StepperConfig {
  List<_StepItem>? steps;
  int? currentStep;
  StepperType? type;
  bool? showControls;
  ValueChanged<int>? onStepTapped;
  VoidCallback? onStepContinue;
  VoidCallback? onStepCancel;
  Key? widgetKey;
}

class _StepItem {
  _StepItem({
    required this.title,
    this.subtitle,
    this.content,
    this.isActive,
    this.state,
  });

  final String title;
  final String? subtitle;
  final Widget? content;
  final bool? isActive;
  final StepState? state;
}

Widget _buildStepper(_StepperConfig config) {
  final steps = config.steps ?? const [];
  if (steps.isEmpty) {
    return const SizedBox.shrink();
  }
  final current = config.currentStep ?? 0;
  return Stepper(
    key: config.widgetKey,
    type: config.type ?? StepperType.vertical,
    currentStep: current.clamp(0, steps.length - 1),
    onStepTapped: config.onStepTapped,
    onStepContinue: config.onStepContinue,
    onStepCancel: config.onStepCancel,
    controlsBuilder: (context, details) {
      if (config.showControls == false) {
        return const SizedBox.shrink();
      }
      return Row(
        children: [
          TextButton(
            onPressed: details.onStepContinue,
            child: const Text('Continue'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: details.onStepCancel,
            child: const Text('Back'),
          ),
        ],
      );
    },
    steps: steps
        .map(
          (step) => Step(
            title: Text(step.title),
            subtitle:
                step.subtitle == null ? null : Text(step.subtitle!.trim()),
            content: step.content ?? const SizedBox.shrink(),
            isActive: step.isActive ?? true,
            state: step.state ?? StepState.indexed,
          ),
        )
        .toList(),
  );
}

List<_StepItem> _parseSteps(Object? value) {
  final steps = <_StepItem>[];
  if (value is Iterable) {
    for (final entry in value) {
      if (entry is Map) {
        final map = Map<String, dynamic>.from(entry);
        final title =
            map['title'] ?? map['label'] ?? map['text'] ?? map['value'];
        final subtitle = map['subtitle'] ?? map['caption'];
        final contentValue = map['content'];
        steps.add(
          _StepItem(
            title: title?.toString() ?? '',
            subtitle: subtitle?.toString(),
            content: _resolveStepContent(contentValue),
            isActive: toBool(map['active']),
            state: _parseStepState(map['state']),
          ),
        );
        continue;
      }
      steps.add(
        _StepItem(
          title: entry?.toString() ?? '',
          content: const SizedBox.shrink(),
        ),
      );
    }
  }
  return steps;
}

Widget _resolveStepContent(Object? value) {
  if (value is Widget) {
    return value;
  }
  if (value == null) {
    return const SizedBox.shrink();
  }
  return Text(value.toString());
}

StepperType? _parseStepperType(Object? value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().toLowerCase().trim();
  switch (text) {
    case 'horizontal':
      return StepperType.horizontal;
    case 'vertical':
      return StepperType.vertical;
    default:
      return null;
  }
}

StepState? _parseStepState(Object? value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().toLowerCase().trim();
  switch (text) {
    case 'complete':
    case 'completed':
      return StepState.complete;
    case 'disabled':
      return StepState.disabled;
    case 'editing':
      return StepState.editing;
    case 'error':
      return StepState.error;
    default:
      return StepState.indexed;
  }
}
