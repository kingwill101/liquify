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

  group('CaseTag', () {
    test('case tag with single match', () {
      fixture.expectTemplateOutput(
          '{% assign handle = "cake" %}'
              '{% case handle %}'
              '{% when "cake" %}'
              'This is a cake'
              '{% when "cookie" %}'
              'This is a cookie'
              '{% else %}'
              'This is not a cake nor a cookie'
              '{% endcase %}',
          'This is a cake');
    });

    test('case tag with multiple values in when', () {
      fixture.expectTemplateOutput(
          '{% assign handle = "biscuit" %}'
              '{% case handle %}'
              '{% when "cake" %}'
              'This is a cake'
              '{% when "cookie", "biscuit" %}'
              'This is a cookie or biscuit'
              '{% else %}'
              'This is something else'
              '{% endcase %}',
          'This is a cookie or biscuit');
    });

    test('case tag with else condition', () {
      fixture.expectTemplateOutput(
          '{% assign handle = "pie" %}'
              '{% case handle %}'
              '{% when "cake" %}'
              'This is a cake'
              '{% when "cookie" %}'
              'This is a cookie'
              '{% else %}'
              'This is neither a cake nor a cookie'
              '{% endcase %}',
          'This is neither a cake nor a cookie');
    });

    test('case tag with no matching condition and no else', () {
      fixture.expectTemplateOutput(
          '{% assign handle = "pie" %}'
              '{% case handle %}'
              '{% when "cake" %}'
              'This is a cake'
              '{% when "cookie" %}'
              'This is a cookie'
              '{% endcase %}',
          '');
    });
  });
}
