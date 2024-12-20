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

  group('truthy evaluations', () {
    test('variable', () {
      fixture.evaluator.context.setVariable('variable', true);
      fixture.expectTemplateContains('''
{% assign name = "Tobi" %}
{% if name %}
  truthy.
{% endif %}
        ''', 'truthy');
    });

    test('falsy evaluation', () {
      fixture.expectTemplateContains('''
{% if false %}
  falsy.
{% else %}
  not truthy
{% endif %}
        ''', 'not truthy');
    });

    test('empty string', () {
      fixture.expectTemplateContains('''
{% assign name = "" %}
{% if name %}
  truthy.
{% endif %}
        ''', 'truthy');
    });

    test('null', () {
      fixture.expectTemplateNotContains('''
{% assign name = null %}
{% if name %}
  truthy.
{% endif %}
        ''', 'truthy');
    });

    test('binary operator and', () {
      fixture.expectTemplateNotContains('''
{% assign name = null %}
{% if name and "" %}
  truthy.
{% endif %}
        ''', 'truthy');
    });

    test('binary operator or', () {
      fixture.expectTemplateContains('''
{% assign name = null %}
{% if name or "" %}
  truthy.
{% endif %}
        ''', 'truthy');
    });
  });
}
