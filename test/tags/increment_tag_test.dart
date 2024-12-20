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

  group('IncrementTag', () {
    test('increments variable', () {
      fixture.expectTemplateOutput(
          '{% increment my_counter %}{% increment my_counter %}{% increment my_counter %}',
          '012');
    });

    test('global variables are not affected by increment', () {
      fixture.expectTemplateOutput(
          '{% assign var = 10 %}{% increment var %}{% increment var %}{% increment var %}{{ var }}',
          '01210');
    });
  });
}
