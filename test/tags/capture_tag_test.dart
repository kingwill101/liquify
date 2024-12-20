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

  group('CaptureTag', () {
    test('outputs captured data', () {
      fixture.expectTemplateOutput(
          '{% capture my_variable %}I am being captured.{% endcapture %}{{ my_variable }}',
          'I am being captured.');
    });
  });
}
