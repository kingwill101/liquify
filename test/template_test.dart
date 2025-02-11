import 'package:liquify/src/template.dart';
import 'package:test/test.dart';

void main() {
  group('Template', () {
    test('sync render', () {
      final template =
          Template.parse('Hello {{ name }}!', data: {'name': 'World'});
      expect(template.render(), equals('Hello World!'));
    });

    test('async render', () async {
      final template =
          Template.parse('Hello {{ name }}!', data: {'name': 'World'});
      expect(await template.renderAsync(), equals('Hello World!'));
    });

    test('async render with complex template', () async {
      final template = Template.parse('''
        {% for item in items %}
          {% if item > 2 %}
            {{ item }}
          {% endif %}
        {% endfor %}
      ''', data: {
        'items': [1, 2, 3, 4, 5]
      });

      final result = await template.renderAsync();
      expect(result.replaceAll(RegExp(r'\s+'), ' ').trim(), '3 4 5');
    });

    test('buffer clearing', () async {
      final template = Template.parse('{{ value }}', data: {'value': 'test'});

      // First render
      expect(await template.renderAsync(clearBuffer: false), equals('test'));

      // Second render should append to buffer if not cleared
      expect(
          await template.renderAsync(clearBuffer: false), equals('testtest'));

      // Third render should start fresh with cleared buffer
      expect(await template.renderAsync(clearBuffer: true), equals('test'));
    });

    test('context updates between renders', () async {
      final template = Template.parse('{{ greeting }} {{ name }}!');

      template.updateContext({'greeting': 'Hello', 'name': 'World'});
      expect(await template.renderAsync(), equals('Hello World!'));

      template.updateContext({'greeting': 'Goodbye'});
      expect(await template.renderAsync(), equals('Goodbye World!'));
    });
  });
}
