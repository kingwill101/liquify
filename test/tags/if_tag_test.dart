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

  group('IfTag', () {
    test('basic if statement', () {
      fixture.expectTemplateOutput('{% if true %}True{% endif %}', 'True');
    });

    // Add remaining if tag tests...
  });
}

