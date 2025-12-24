import 'package:liquify/liquify.dart';
import 'package:liquify_ui/src/ui_nodes.dart';
import 'package:liquify_ui/src/ui_target.dart';

class UiTemplate {
  UiTemplate._(this._template, {UiRenderTarget? target})
    : _target = target ?? const UiRenderTarget();

  factory UiTemplate.parse(
    String input, {
    Map<String, dynamic> data = const {},
    Root? root,
    Environment? environment,
    void Function(Environment)? environmentSetup,
    UiRenderTarget? target,
  }) {
    return UiTemplate._(
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

  factory UiTemplate.fromFile(
    String templateName,
    Root root, {
    Map<String, dynamic> data = const {},
    Environment? environment,
    void Function(Environment)? environmentSetup,
    UiRenderTarget? target,
  }) {
    return UiTemplate._(
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
  final UiRenderTarget _target;

  UiDocument render({bool clearBuffer = true}) {
    return _template.renderWith(_target, clearBuffer: clearBuffer);
  }

  Future<UiDocument> renderAsync({bool clearBuffer = true}) {
    return _template.renderWithAsync(_target, clearBuffer: clearBuffer);
  }

  void updateContext(Map<String, dynamic> newData) {
    _template.updateContext(newData);
  }

  Environment get environment => _template.environment;
}
