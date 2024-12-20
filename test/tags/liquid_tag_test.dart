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

  group('LiquidTag', () {
    test('assigns variable', () async {
      testParser('''
{% liquid
 assign my_variable = "string"
%}
''', (document) async {
        await fixture.evaluator.evaluate(document);
        expect(fixture.evaluator.context.getVariable('my_variable'), 'string');
      });
    });
  });
}
