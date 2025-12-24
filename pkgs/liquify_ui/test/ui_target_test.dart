import 'package:liquify/liquify.dart';
import 'package:liquify_ui/liquify_ui.dart';
import 'package:test/test.dart';

void main() {
  test('renders UiDocument via renderWith', () {
    final template = Template.parse(
      'Hello {{ name }}!',
      data: {'name': 'World'},
    );

    final ui = template.renderWith(const UiRenderTarget());
    expect(ui.toJson(), {
      'version': UiDocument.schemaVersion,
      'nodes': [
        {'type': 'text', 'text': 'Hello World!'},
      ],
    });
  });

  test('UiTemplate renders directly', () {
    final template = UiTemplate.parse('Hi {{ name }}', data: {'name': 'Ada'});

    final ui = template.render();
    expect(ui.toJson(), {
      'version': UiDocument.schemaVersion,
      'nodes': [
        {'type': 'text', 'text': 'Hi Ada'},
      ],
    });
  });
}
