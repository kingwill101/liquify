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

  group('CycleTag', () {
    test('basic cycle', () {
      fixture.expectTemplateOutput(
          '{% cycle "one", "two", "three" %}'
              '{% cycle "one", "two", "three" %}'
              '{% cycle "one", "two", "three" %}'
              '{% cycle "one", "two", "three" %}',
          'onetwothreeone');
    });

    test('cycle with groups', () {
      fixture.expectTemplateOutput(
          '{% cycle "first": "one", "two", "three" %}'
              '{% cycle "second": "one", "two", "three" %}'
              '{% cycle "second": "one", "two", "three" %}'
              '{% cycle "first": "one", "two", "three" %}',
          'oneonetwotwo');
    });
  });
}
