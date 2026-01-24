import 'package:liquify/liquify.dart';
import 'package:liquify/parser.dart';
import 'package:test/test.dart';

/// Custom tag that uses tag delimiters ({% %} or <% %> etc.)
class ShoutTag extends AbstractTag with CustomTagParser {
  ShoutTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final text = content.isNotEmpty
        ? evaluator.evaluate(content.first)?.toString() ?? ''
        : '';
    buffer.write(text.toUpperCase());
  }

  @override
  Parser parser([LiquidConfig? config]) {
    return (createTagStart(config) &
            string('shout').trim() &
            ref0(expression).optional().trim() &
            createTagEnd(config))
        .map((values) {
          final expr = values[2];
          return Tag('shout', expr != null ? [expr as ASTNode] : []);
        });
  }
}

void main() {
  group('Custom Tags with Custom Delimiters', () {
    setUpAll(() {
      // Register custom tag
      TagRegistry.register(
        'shout',
        (content, filters) => ShoutTag(content, filters),
      );
    });

    group('Standard delimiters', () {
      late Liquid liquid;

      setUp(() {
        liquid = Liquid();
      });

      test('tag-style custom tag works', () {
        final result = liquid.renderString('{% shout "hello" %}', {});
        expect(result, equals('HELLO'));
      });

      test('custom tags work with variables', () {
        final result = liquid.renderString(
          '{% assign msg = "test" %}{% shout msg %}',
          {},
        );
        expect(result, equals('TEST'));
      });
    });

    group('ERB-style delimiters', () {
      late Liquid liquid;

      setUp(() {
        liquid = Liquid(config: LiquidConfig.erb);
      });

      test('tag-style custom tag works with ERB delimiters', () {
        final result = liquid.renderString('<% shout "hello" %>', {});
        expect(result, equals('HELLO'));
      });

      test('custom tags work with variables using ERB delimiters', () {
        final result = liquid.renderString(
          '<% assign msg = "test" %><% shout msg %>',
          {},
        );
        expect(result, equals('TEST'));
      });

      test('custom tags mix with standard Liquid tags (ERB)', () {
        final result = liquid.renderString(
          '<% if true %><% shout "yes" %><% endif %>',
          {},
        );
        expect(result, equals('YES'));
      });

      test('custom tags in for loop (ERB)', () {
        final result = liquid.renderString(
          '<% for item in items %><% shout item %> <% endfor %>',
          {
            'items': ['a', 'b', 'c'],
          },
        );
        expect(result, contains('A'));
        expect(result, contains('B'));
        expect(result, contains('C'));
      });
    });

    group('Bracket-style delimiters', () {
      late Liquid liquid;

      setUp(() {
        liquid = Liquid(
          config: const LiquidConfig(
            tagStart: '[%',
            tagEnd: '%]',
            varStart: '[[',
            varEnd: ']]',
          ),
        );
      });

      test('tag-style custom tag works with bracket delimiters', () {
        final result = liquid.renderString('[% shout "hello" %]', {});
        expect(result, equals('HELLO'));
      });

      test('custom tags work with standard tags using bracket delimiters', () {
        final result = liquid.renderString(
          '[% for i in (1..3) %][% shout i %][% endfor %]',
          {},
        );
        expect(result, contains('1'));
        expect(result, contains('2'));
        expect(result, contains('3'));
      });
    });

    group('Multiple Liquid instances with different delimiters', () {
      test('custom tags work correctly in each instance', () {
        final liquidStd = Liquid();
        final liquidErb = Liquid(config: LiquidConfig.erb);
        final liquidBracket = Liquid(
          config: const LiquidConfig(
            tagStart: '[%',
            tagEnd: '%]',
            varStart: '[[',
            varEnd: ']]',
          ),
        );

        // Standard
        expect(liquidStd.renderString('{% shout "std" %}', {}), equals('STD'));

        // ERB
        expect(liquidErb.renderString('<% shout "erb" %>', {}), equals('ERB'));

        // Bracket
        expect(
          liquidBracket.renderString('[% shout "bracket" %]', {}),
          equals('BRACKET'),
        );

        // Verify they don't cross-pollinate
        expect(
          liquidErb.renderString('{% shout "should not work" %}', {}),
          equals('{% shout "should not work" %}'), // Treated as text
        );
      });
    });

    group('Edge cases', () {
      test('whitespace stripping works with custom tags (ERB)', () {
        final liquid = Liquid(config: LiquidConfig.erb);
        final result = liquid.renderString(
          'before <%- shout "test" %> after',
          {},
        );
        expect(result, equals('beforeTEST after'));
      });

      test('nested custom tags in control flow', () {
        final liquid = Liquid(config: LiquidConfig.erb);
        final result = liquid.renderString(
          '''
<% if show %>
<% shout greeting %>
<% endif %>
''',
          {'show': true, 'greeting': 'welcome'},
        );
        expect(result, contains('WELCOME'));
      });
    });
  });
}
