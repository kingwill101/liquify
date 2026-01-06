import 'package:flutter/widgets.dart';
import 'package:liquify/liquify.dart';

import 'widget_render_target.dart';

class FlutterTemplate {
  FlutterTemplate._(this._template, {WidgetRenderTarget? target})
    : _target = target ?? const WidgetRenderTarget();

  factory FlutterTemplate.parse(
    String input, {
    Map<String, dynamic> data = const {},
    Root? root,
    Environment? environment,
    void Function(Environment)? environmentSetup,
    WidgetRenderTarget? target,
  }) {
    return FlutterTemplate._(
      Template.parse(
        input,
        data: data,
        root: root,
        environment: environment,
        environmentSetup: environmentSetup,
      ),
      target: target,
    );
  }

  factory FlutterTemplate.fromFile(
    String templateName,
    Root root, {
    Map<String, dynamic> data = const {},
    Environment? environment,
    void Function(Environment)? environmentSetup,
    WidgetRenderTarget? target,
  }) {
    return FlutterTemplate._(
      Template.fromFile(
        templateName,
        root,
        data: data,
        environment: environment,
        environmentSetup: environmentSetup,
      ),
      target: target,
    );
  }

  final Template _template;
  final WidgetRenderTarget _target;

  Widget render({bool clearBuffer = true}) {
    return _template.renderWith(_target, clearBuffer: clearBuffer);
  }

  Future<Widget> renderAsync({bool clearBuffer = true}) {
    return _template.renderWithAsync(_target, clearBuffer: clearBuffer);
  }

  void updateContext(Map<String, dynamic> newData) {
    _template.updateContext(newData);
  }

  Environment get environment => _template.environment;
}
