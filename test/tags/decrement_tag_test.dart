import 'package:test/test.dart';
import 'shared.dart';

void main() {
  late TagTestCase fixture;

  setUp(() {
    fixture = TagTestCase()..setUp();
  });

  tearDown(() {
    fixture.tearDown();
  });

  group('DecrementTag', () {
    test('decrements variable', () {
      fixture.expectTemplateOutput(
          '{% decrement my_counter %}\n{% decrement my_counter %}\n{% decrement my_counter %}',
          '-1\n-2\n-3');
    });

    test('global variables are not affected by decrement', () {
      fixture.expectTemplateOutput(
          '{% assign var = 10 %}\n{% decrement var %}\n{% decrement var %}\n{% decrement var %}\n{{ var }}',
          '\n-1\n-2\n-3\n10');
    });
  });
}
