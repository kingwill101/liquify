import 'package:liquify/liquify.dart';
import 'package:test/test.dart';

class _NumberTarget extends RenderTarget<Object?> {
  const _NumberTarget();

  @override
  RenderSink createSink() => _NumberSink();

  @override
  Object? finalize(RenderSink sink) => sink.result();
}

class _NumberSink extends RenderSink {
  Object? _value;

  @override
  void write(Object? value) => _value = value;

  @override
  void writeln([Object? value]) => write(value);

  @override
  void clear() => _value = null;

  @override
  RenderSink spawn() => _NumberSink();

  @override
  void merge(RenderSink other) => write(other.result());

  @override
  Object? result() => _value;

  @override
  String debugString() => _value?.toString() ?? '';
}

void main() {
  final cases = <String, String>{
    '{{ 20 | divided_by: 7 }}': '2',
    '{{ 20 | divided_by: 7.0 }}': '2.857142857142857',
    '{{ 20.0 | divided_by: 7 }}': '2.857142857142857',
    '{{ 20 | divided_by: "7.0" }}': '2.857142857142857',
    '{% assign divisor = 7.0 %}{{ 20 | divided_by: divisor }}':
        '2.857142857142857',
    '{% assign divisor = 14 | divided_by: 2.0 %}{{ 20 | divided_by: divisor }}':
        '2.857142857142857',
    '{{ 20 | divided_by: 10.0 }}': '2.0',
    '{{ 20 | divided_by: (6.0 + 1) }}': '2.857142857142857',
    '{{ 6.0 | plus: 1 | divided_by: 2 }}': '3.5',
    '{% echo 20 | divided_by: 7.0 %}': '2.857142857142857',
  };

  group('divided_by numeric operand types', () {
    test('custom filters receive ordinary Dart numbers', () async {
      Template template() => Template.parse(
        '{{ 7.0 | check: 2.0, operand: 3.0 }}',
        environmentSetup: (environment) {
          environment.registerLocalFilter('check', (value, arguments, named) {
            return value is num &&
                arguments.single is num &&
                named['operand'] is num;
          });
        },
      );

      expect(template().render(), 'true');
      expect(await template().renderAsync(), 'true');
    });

    test('structured render targets receive ordinary Dart numbers', () async {
      final template = Template.parse('{{ 20 | divided_by: 10.0 }}');

      expect(template.renderWith(const _NumberTarget()), 2.0);
      expect(await template.renderWithAsync(const _NumberTarget()), 2.0);
    });

    test('sum keeps an integral decimal result for the next filter', () async {
      final template = Template.parse(
        '{{ values | sum | divided_by: 2 }}',
        data: {
          'values': [1.5, 5.5],
        },
      );

      expect(template.render(), '3.5');
      expect(await template.renderAsync(), '3.5');
    });

    for (final entry in cases.entries) {
      test(entry.key, () async {
        expect(Template.parse(entry.key).render(), entry.value);
        expect(await Template.parse(entry.key).renderAsync(), entry.value);
      });
    }
  });
}
