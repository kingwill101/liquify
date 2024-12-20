import 'package:test/test.dart';
import '../shared.dart';
import 'shared.dart';

void main() {
  late TagTestCase fixture;

  setUp(() {
    fixture = TagTestCase()..setUp();
  });

  tearDown(() {
    fixture.tearDown();
  });

  group('RawTag', () {
    test('shows raw text', () async {
      testParser('''{% raw %}{% liquid
assign my_variable = "string"
%}{% endraw %}''', (document) async {
        await fixture.evaluator.evaluate(document);
        expect(fixture.evaluator.buffer.toString(), '''{% liquid
assign my_variable = "string"
%}''');
      });
    });

    test('preserves multiple lines', () async {
      testParser('''{% raw %}
first line
second line
third line
{% endraw %}''', (document) async {
        await fixture.evaluator.evaluate(document);
        expect(fixture.evaluator.buffer.toString(), '''
first line
second line
third line
''');
      });
    });

    test('preserves liquid syntax inside', () async {
      testParser('''{% raw %}
{% if user %}
  Hello {{ user.name }}!
{% endif %}
{% endraw %}''', (document) async {
        await fixture.evaluator.evaluate(document);
        expect(fixture.evaluator.buffer.toString(), '''
{% if user %}
  Hello {{ user.name }}!
{% endif %}
''');
      });
    });

    test('preserves special characters', () async {
      testParser('''{% raw %}
<script>
  var x = { foo: "bar" };
  if (x["foo"] === "bar") {
    alert("Hello!");
  }
</script>
{% endraw %}''', (document) async {
        await fixture.evaluator.evaluate(document);
        expect(fixture.evaluator.buffer.toString(), '''
<script>
  var x = { foo: "bar" };
  if (x["foo"] === "bar") {
    alert("Hello!");
  }
</script>
''');
      });
    });

    test('handles empty content', () async {
      testParser('''{% raw %}{% endraw %}''', (document) async {
        await fixture.evaluator.evaluate(document);
        expect(fixture.evaluator.buffer.toString(), '');
      });
    });

    test('preserves whitespace', () async {
      testParser('''{% raw %}    spaces    and    tabs    {% endraw %}''',
          (document) async {
        await fixture.evaluator.evaluate(document);
        expect(fixture.evaluator.buffer.toString(),
            '''    spaces    and    tabs    ''');
      });
    });

    test('handles nested raw-like syntax', () async {
      testParser('''{% raw %}{% raw %}nested raw{% endraw %}trert{% endraw %}''',
          (document) async {
        await fixture.evaluator.evaluate(document);
        print(fixture.evaluator.buffer.toString());
        expect(fixture.evaluator.buffer.toString(),
            '''{% raw %}nested raw{% endraw %}''');
      });
    });
  });
}
