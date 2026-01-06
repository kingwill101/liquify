import 'package:liquify/liquify.dart';
import 'support/golden_harness.dart';

class TokenTarget extends RenderTarget<List<String>> {
  const TokenTarget();

  @override
  RenderSink createSink() => TokenSink();

  @override
  List<String> finalize(RenderSink sink) {
    return List<String>.from((sink as TokenSink).tokens);
  }
}

class TokenSink extends RenderSink {
  final List<String> tokens = [];

  @override
  void write(Object? value) {
    tokens.add(value?.toString() ?? '');
  }

  @override
  void writeln([Object? value]) {
    write(value);
    write('\n');
  }

  @override
  void clear() {
    tokens.clear();
  }

  @override
  RenderSink spawn() => TokenSink();

  @override
  void merge(RenderSink other) {
    if (other is TokenSink) {
      tokens.addAll(other.tokens);
    } else {
      tokens.add(other.debugString());
    }
  }

  @override
  Object? result() => List<String>.from(tokens);

  @override
  String debugString() => tokens.join();
}

void main() {
  group('RenderTarget', () {
    test('renders with custom target without breaking string render', () {
      final template = Template.parse(
        'Hello {{ name }}!',
        data: {'name': 'World'},
      );

      final tokens = template.renderWith(const TokenTarget());
      expect(tokens.join(), 'Hello World!');
      expect(template.render(), 'Hello World!');
    });

    test('renders with custom target asynchronously', () async {
      final template = Template.parse('Hi {{ name }}', data: {'name': 'Ada'});

      final tokens = await template.renderWithAsync(const TokenTarget());
      expect(tokens.join(), 'Hi Ada');
    });
  });
}
