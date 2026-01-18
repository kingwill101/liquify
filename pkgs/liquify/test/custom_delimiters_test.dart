import 'package:liquify/liquify.dart';
import 'package:test/test.dart';

void main() {
  group('Custom Delimiters', () {
    group('LiquidConfig', () {
      test('creates default config with standard delimiters', () {
        const config = LiquidConfig();
        expect(config.tagStart, equals('{%'));
        expect(config.tagEnd, equals('%}'));
        expect(config.varStart, equals('{{'));
        expect(config.varEnd, equals('}}'));
        expect(config.stripMarker, equals('-'));
      });

      test('creates config with custom delimiters', () {
        const config = LiquidConfig(
          tagStart: '[%',
          tagEnd: '%]',
          varStart: '[[',
          varEnd: ']]',
        );
        expect(config.tagStart, equals('[%'));
        expect(config.tagEnd, equals('%]'));
        expect(config.varStart, equals('[['));
        expect(config.varEnd, equals(']]'));
      });

      test('computes strip variants correctly', () {
        const config = LiquidConfig(
          tagStart: '[%',
          tagEnd: '%]',
          varStart: '[[',
          varEnd: ']]',
        );
        expect(config.tagStartStrip, equals('[%-'));
        expect(config.tagEndStrip, equals('-%]'));
        expect(config.varStartStrip, equals('[[-'));
        expect(config.varEndStrip, equals('-]]'));
      });

      test('standard preset uses default delimiters', () {
        expect(LiquidConfig.standard.tagStart, equals('{%'));
        expect(LiquidConfig.standard.varStart, equals('{{'));
      });

      test('erb preset uses ERB-style delimiters', () {
        expect(LiquidConfig.erb.tagStart, equals('<%'));
        expect(LiquidConfig.erb.tagEnd, equals('%>'));
        expect(LiquidConfig.erb.varStart, equals('<%='));
        expect(LiquidConfig.erb.varEnd, equals('%>'));
      });

      test('copyWith creates modified copy', () {
        const config = LiquidConfig();
        final modified = config.copyWith(tagStart: '<%');
        expect(modified.tagStart, equals('<%'));
        expect(modified.tagEnd, equals('%}')); // unchanged
        expect(modified.varStart, equals('{{')); // unchanged
      });

      test('equality works correctly', () {
        const config1 = LiquidConfig(tagStart: '[%');
        const config2 = LiquidConfig(tagStart: '[%');
        const config3 = LiquidConfig(tagStart: '<%');

        expect(config1, equals(config2));
        expect(config1, isNot(equals(config3)));
      });
    });

    group('Liquid with default delimiters', () {
      late Liquid liquid;

      setUp(() {
        liquid = Liquid();
      });

      test('parses simple variable', () {
        final template = liquid.parse('Hello {{ name }}!');
        final result = template.render({'name': 'World'});
        expect(result, equals('Hello World!'));
      });

      test('parses simple tag', () {
        final template = liquid.parse('{% if show %}visible{% endif %}');
        final result = template.render({'show': true});
        expect(result, equals('visible'));
      });

      test('parses mixed content', () {
        final template = liquid.parse(
          '{% assign greeting = "Hello" %}{{ greeting }}, {{ name }}!',
        );
        final result = template.render({'name': 'World'});
        expect(result, equals('Hello, World!'));
      });
    });

    group('Liquid with custom delimiters', () {
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

      test('parses simple variable with custom delimiters', () {
        final template = liquid.parse('Hello [[ name ]]!');
        final result = template.render({'name': 'World'});
        expect(result, equals('Hello World!'));
      });

      test('parses simple tag with custom delimiters', () {
        final template = liquid.parse('[% if show %]visible[% endif %]');
        final result = template.render({'show': true});
        expect(result, equals('visible'));
      });

      test('parses mixed content with custom delimiters', () {
        final template = liquid.parse(
          '[% assign greeting = "Hello" %][[ greeting ]], [[ name ]]!',
        );
        final result = template.render({'name': 'World'});
        expect(result, equals('Hello, World!'));
      });

      test('parses for loop with custom delimiters', () {
        final template = liquid.parse(
          '[% for item in items %][[ item ]] [% endfor %]',
        );
        final result = template.render({
          'items': ['a', 'b', 'c'],
        });
        expect(result, equals('a b c '));
      });

      test('parses filters with custom delimiters', () {
        final template = liquid.parse('[[ name | upcase ]]');
        final result = template.render({'name': 'hello'});
        expect(result, equals('HELLO'));
      });

      test('standard delimiters do not work with custom config', () {
        // {{ }} should be treated as plain text
        final template = liquid.parse('Hello {{ name }}!');
        final result = template.render({'name': 'World'});
        // The {{ name }} should appear as literal text
        expect(result, equals('Hello {{ name }}!'));
      });
    });

    group('Liquid.withDelimiters convenience constructor', () {
      test('creates liquid with custom delimiters', () {
        final liquid = Liquid.withDelimiters(
          tagStart: '<%',
          tagEnd: '%>',
          varStart: '<%=',
          varEnd: '%>',
        );

        final template = liquid.parse('Hello <%= name %>!');
        final result = template.render({'name': 'World'});
        expect(result, equals('Hello World!'));
      });
    });

    group('Whitespace stripping with custom delimiters', () {
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

      test('[[-  strips preceding whitespace', () {
        final template = liquid.parse('before [[- "hello" ]] after');
        final result = template.render();
        expect(result, equals('beforehello after'));
      });

      test('-]] strips following whitespace', () {
        final template = liquid.parse('before [[ "hello" -]] after');
        final result = template.render();
        expect(result, equals('before helloafter'));
      });

      test('[%- strips preceding whitespace', () {
        final template = liquid.parse(
          'before [%- if true %]hello[% endif %] after',
        );
        final result = template.render();
        expect(result, equals('beforehello after'));
      });
    });

    group('ERB-style delimiters', () {
      late Liquid liquid;

      setUp(() {
        liquid = Liquid(config: LiquidConfig.erb);
      });

      test('parses ERB-style template', () {
        final template = liquid.parse('Hello <%= name %>!');
        final result = template.render({'name': 'World'});
        expect(result, equals('Hello World!'));
      });

      test('parses ERB-style control flow', () {
        final template = liquid.parse('<% if show %>visible<% endif %>');
        final result = template.render({'show': true});
        expect(result, equals('visible'));
      });
    });

    group('renderString convenience method', () {
      test('parses and renders in one call', () {
        final liquid = Liquid();
        final result = liquid.renderString('Hello {{ name }}!', {
          'name': 'World',
        });
        expect(result, equals('Hello World!'));
      });

      test('works with custom delimiters', () {
        final liquid = Liquid(
          config: const LiquidConfig(varStart: '[[', varEnd: ']]'),
        );
        final result = liquid.renderString('Hello [[ name ]]!', {
          'name': 'World',
        });
        expect(result, equals('Hello World!'));
      });
    });

    group('Multiple Liquid instances with different configs', () {
      test('can coexist without interference', () {
        final liquid1 = Liquid(); // default delimiters
        final liquid2 = Liquid(
          config: const LiquidConfig(varStart: '[[', varEnd: ']]'),
        );

        // Each should parse its own delimiter style
        final result1 = liquid1.renderString('{{ name }}', {'name': 'A'});
        final result2 = liquid2.renderString('[[ name ]]', {'name': 'B'});

        expect(result1, equals('A'));
        expect(result2, equals('B'));

        // And not parse the other style
        final result3 = liquid1.renderString('[[ name ]]', {'name': 'C'});
        final result4 = liquid2.renderString('{{ name }}', {'name': 'D'});

        expect(result3, equals('[[ name ]]')); // treated as text
        expect(result4, equals('{{ name }}')); // treated as text
      });
    });

    group('Edge cases', () {
      test('handles empty template', () {
        final liquid = Liquid();
        final template = liquid.parse('');
        final result = template.render();
        expect(result, equals(''));
      });

      test('handles template with no delimiters', () {
        final liquid = Liquid();
        final template = liquid.parse('Just plain text');
        final result = template.render();
        expect(result, equals('Just plain text'));
      });

      test('handles delimiter-like text that is not a delimiter', () {
        final liquid = Liquid(
          config: const LiquidConfig(
            tagStart: '[[',
            tagEnd: ']]',
            varStart: '[[[',
            varEnd: ']]]',
          ),
        );
        // A single [ or [[ should not trigger variable parsing
        final template = liquid.parse('array[0] or [[tag]]');
        final result = template.render();
        // [[tag]] is a tag, but [0] is plain text
        expect(result, contains('array[0]'));
      });
    });

    group('Comprehensive ERB-style template', () {
      late Liquid liquid;

      setUp(() {
        liquid = Liquid(config: LiquidConfig.erb);
      });

      test('variables and filters with ERB delimiters', () {
        const template = '''
=== VARIABLES AND FILTERS ===
Name: <%= user.name | upcase %>
Email: <%= user.email | downcase | strip %>
Greeting: <%= "hello world" | capitalize | append: "!" %>
''';

        final result = liquid.renderString(template, {
          'user': {'name': 'John Doe', 'email': '  JOHN@EXAMPLE.COM  '},
        });

        expect(result, contains('Name: JOHN DOE'));
        expect(result, contains('Email: john@example.com'));
        expect(result, contains('Greeting: Hello world!'));
      });

      test('assign and capture with ERB delimiters', () {
        const template = '''
<% assign title = "Dashboard" %>
Title: <%= title %>
<% capture full_greeting %>Hello from <%= title %><% endcapture %>
<%= full_greeting %>
''';

        final result = liquid.renderString(template, {});

        expect(result, contains('Title: Dashboard'));
        expect(result, contains('Hello from Dashboard'));
      });

      test('if/elsif/else with ERB delimiters', () {
        const template = '''
<% if user.role == "admin" %>
User is an admin
<% elsif user.role == "moderator" %>
User is a moderator
<% else %>
User is a regular member
<% endif %>
''';

        final adminResult = liquid.renderString(template, {
          'user': {'role': 'admin'},
        });
        expect(adminResult, contains('User is an admin'));

        final modResult = liquid.renderString(template, {
          'user': {'role': 'moderator'},
        });
        expect(modResult, contains('User is a moderator'));

        final userResult = liquid.renderString(template, {
          'user': {'role': 'user'},
        });
        expect(userResult, contains('User is a regular member'));
      });

      test('nested if blocks with ERB delimiters', () {
        const template = '''
<% if user.active %>
  <% if user.verified %>
Active and verified
  <% else %>
Active but not verified
  <% endif %>
<% endif %>
''';

        final result = liquid.renderString(template, {
          'user': {'active': true, 'verified': true},
        });
        expect(result, contains('Active and verified'));
      });

      test('unless with ERB delimiters', () {
        const template = '''
<% unless user.banned %>
User is not banned
<% endunless %>
''';

        final result = liquid.renderString(template, {
          'user': {'banned': false},
        });
        expect(result, contains('User is not banned'));
      });

      test('for loop with forloop object using ERB delimiters', () {
        const template = '''
<% for item in items %>
[<%= forloop.index %>/<%= forloop.length %>] <%= item %><% if forloop.first %> (FIRST)<% endif %><% if forloop.last %> (LAST)<% endif %>
<% endfor %>
''';

        final result = liquid.renderString(template, {
          'items': ['Apple', 'Banana', 'Cherry'],
        });

        expect(result, contains('[1/3] Apple (FIRST)'));
        expect(result, contains('[2/3] Banana'));
        expect(result, contains('[3/3] Cherry (LAST)'));
      });

      test('for loop with limit using ERB delimiters', () {
        const template =
            '<% for item in items limit:2 %><%= item %> <% endfor %>';

        final result = liquid.renderString(template, {
          'items': ['A', 'B', 'C', 'D'],
        });

        expect(result, contains('A'));
        expect(result, contains('B'));
        expect(result, isNot(contains('C')));
      });

      test('for loop with range using ERB delimiters', () {
        const template =
            '<% for i in (1..5) %><%= i %><% unless forloop.last %>,<% endunless %><% endfor %>';

        final result = liquid.renderString(template, {});

        expect(result, equals('1,2,3,4,5'));
      });

      test('for-else with ERB delimiters', () {
        const template = '''
<% for item in items %>
- <%= item %>
<% else %>
No items found!
<% endfor %>
''';

        final emptyResult = liquid.renderString(template, {'items': []});
        expect(emptyResult, contains('No items found!'));

        final withItemsResult = liquid.renderString(template, {
          'items': ['Apple'],
        });
        expect(withItemsResult, contains('- Apple'));
      });

      test('case/when/else with ERB delimiters', () {
        const template = '''
<% case status %>
<% when "online" %>
User is online
<% when "away" %>
User is away
<% else %>
Unknown status
<% endcase %>
''';

        final onlineResult = liquid.renderString(template, {
          'status': 'online',
        });
        expect(onlineResult, contains('User is online'));

        final awayResult = liquid.renderString(template, {'status': 'away'});
        expect(awayResult, contains('User is away'));

        final unknownResult = liquid.renderString(template, {
          'status': 'offline',
        });
        expect(unknownResult, contains('Unknown status'));
      });

      test('increment/decrement with ERB delimiters', () {
        const template =
            '<% increment counter %>,<% increment counter %>,<% increment counter %>';

        final result = liquid.renderString(template, {});
        expect(result, contains('0'));
        expect(result, contains('1'));
        expect(result, contains('2'));
      });

      test('complex expressions with ERB delimiters', () {
        const template = '''
<% if count > 0 and active == true %>
Count is positive and active
<% endif %>
<% if count >= 5 or role == "admin" %>
Count >= 5 or admin
<% endif %>
''';

        final result = liquid.renderString(template, {
          'count': 10,
          'active': true,
          'role': 'user',
        });

        expect(result, contains('Count is positive and active'));
        expect(result, contains('Count >= 5 or admin'));
      });

      test('array access with ERB delimiters', () {
        const template = '''
First: <%= items[0] %>
Second: <%= items[1] %>
''';

        final result = liquid.renderString(template, {
          'items': ['Apple', 'Banana', 'Cherry'],
        });

        expect(result, contains('First: Apple'));
        expect(result, contains('Second: Banana'));
      });

      test('contains operator with ERB delimiters', () {
        const template = '''
<% if name contains "John" %>
Name contains John
<% endif %>
<% assign colors = "red,green,blue" %>
<% if colors contains "green" %>
Has green
<% endif %>
''';

        final result = liquid.renderString(template, {'name': 'John Doe'});
        expect(result, contains('Name contains John'));
        expect(result, contains('Has green'));
      });

      test('multiple filters chained with ERB delimiters', () {
        const template =
            '<%= "  hello world  " | strip | upcase | prepend: ">>> " | append: " <<<" %>';

        final result = liquid.renderString(template, {});
        expect(result, contains('>>> HELLO WORLD <<<'));
      });

      test('whitespace control with ERB delimiters', () {
        // Test whitespace stripping with tag delimiters
        const template = 'Before <% if true -%> middle <% endif %> After';

        final result = liquid.renderString(template, {});
        expect(result, contains('Before'));
        expect(result, contains('middle'));
        expect(result, contains('After'));
      });

      test('cycle with ERB delimiters', () {
        const template =
            '<% for i in (1..4) %><% cycle "odd", "even" %><% endfor %>';

        final result = liquid.renderString(template, {});
        expect(result, contains('odd'));
        expect(result, contains('even'));
      });

      test('comment tag with ERB delimiters', () {
        const template =
            'Before<% comment %>This should not appear<% endcomment %>After';

        final result = liquid.renderString(template, {});
        expect(result, contains('BeforeAfter'));
        expect(result, isNot(contains('This should not appear')));
      });

      test('handles deeply nested control structures', () {
        const template = '''
<% for category in categories %>
Category: <%= category.name %>
  <% for product in category.products %>
    <% if product.in_stock %>
      <% case product.rating %>
      <% when 5 %>
        ★★★★★ <%= product.name %>
      <% when 4 %>
        ★★★★☆ <%= product.name %>
      <% when 3 %>
        ★★★☆☆ <%= product.name %>
      <% else %>
        ★★☆☆☆ <%= product.name %> (low rating)
      <% endcase %>
    <% else %>
      [OUT OF STOCK] <%= product.name %>
    <% endif %>
  <% endfor %>
<% endfor %>
''';

        final result = liquid.renderString(template, {
          'categories': [
            {
              'name': 'Electronics',
              'products': [
                {'name': 'Phone', 'in_stock': true, 'rating': 5},
                {'name': 'Tablet', 'in_stock': true, 'rating': 4},
                {'name': 'Laptop', 'in_stock': false, 'rating': 5},
              ],
            },
            {
              'name': 'Books',
              'products': [
                {'name': 'Fiction', 'in_stock': true, 'rating': 3},
                {'name': 'Non-fiction', 'in_stock': true, 'rating': 2},
              ],
            },
          ],
        });

        expect(result, contains('Category: Electronics'));
        expect(result, contains('★★★★★ Phone'));
        expect(result, contains('★★★★☆ Tablet'));
        expect(result, contains('[OUT OF STOCK] Laptop'));
        expect(result, contains('Category: Books'));
        expect(result, contains('★★★☆☆ Fiction'));
        expect(result, contains('(low rating)'));
      });

      test('handles complex filter chains', () {
        const template = '''
<%= items | map: "name" | join: ", " %>
<%= items | first | map: "name" %>
<%= items | last | map: "name" %>
<%= items | size %>
<%= "hello" | slice: 0, 3 | upcase %>
<%= 1234.5678 | round: 2 %>
<%= "hello world" | split: " " | first | capitalize %>
<%= "2024-01-15" | date: "%B %d, %Y" %>
''';

        final result = liquid.renderString(template, {
          'items': [
            {'name': 'Alpha'},
            {'name': 'Beta'},
            {'name': 'Gamma'},
          ],
        });

        expect(result, contains('Alpha, Beta, Gamma'));
        expect(result, contains('3'));
        expect(result, contains('HEL'));
        expect(result, contains('1234.57'));
        expect(result, contains('Hello'));
      });

      test('handles break and continue in loops', () {
        const template = '''
<% for i in (1..10) %>
<% if i == 3 %><% continue %><% endif %>
<% if i == 6 %><% break %><% endif %>
<%= i %>
<% endfor %>
''';

        final result = liquid.renderString(template, {});

        expect(result, contains('1'));
        expect(result, contains('2'));
        expect(result, isNot(contains('3'))); // skipped by continue
        expect(result, contains('4'));
        expect(result, contains('5'));
        expect(result, isNot(contains('6'))); // stopped by break
        expect(result, isNot(contains('7'))); // after break
      });

      test('handles arithmetic operations', () {
        const template = '''
<% assign a = 10 %>
<% assign b = 3 %>
<%= a | plus: b %>
<%= a | minus: b %>
<%= a | times: b %>
<%= a | divided_by: b %>
<%= a | modulo: b %>
''';

        final result = liquid.renderString(template, {});

        expect(result, contains('13')); // 10 + 3
        expect(result, contains('7')); // 10 - 3
        expect(result, contains('30')); // 10 * 3
        // divided_by with integers gives integer result
      });

      test('handles string filters', () {
        const template = '''
<%= "hello" | append: " world" %>
<%= "world" | prepend: "hello " %>
<%= "hello world" | remove: "world" %>
<%= "hello world" | remove_first: "l" %>
<%= "hello world" | replace: "world", "universe" %>
<%= "hello world" | replace_first: "l", "L" %>
<%= "hello world" | truncate: 8 %>
<%= "hello world" | truncatewords: 1 %>
<%= "Hello World" | downcase %>
<%= "hello world" | upcase %>
<%= "hello world" | capitalize %>
<%= "  hello  " | strip %>
<%= "  hello  " | lstrip %>
<%= "  hello  " | rstrip %>
<%= "hello\nworld" | newline_to_br %>
<%= "<p>hello</p>" | strip_html %>
<%= "hello world" | size %>
''';

        final result = liquid.renderString(template, {});

        expect(result, contains('hello world'));
        expect(result, contains('hello universe'));
        expect(result, contains('hello '));
        expect(result, contains('heLlo world'));
        expect(result, contains('hello...'));
        expect(result, contains('HELLO WORLD'));
        expect(result, contains('Hello world'));
        expect(result, contains('11')); // size
      });

      test('handles array filters', () {
        const template = '''
<%= items | join: "-" %>
<%= items | first %>
<%= items | last %>
<%= items | reverse | join: "-" %>
<%= items | sort | join: "-" %>
<%= items | uniq | join: "-" %>
<%= items | compact | join: "-" %>
<%= items | size %>
''';

        final result = liquid.renderString(template, {
          'items': ['c', 'a', 'b', 'a'],
        });

        expect(result, contains('c-a-b-a'));
        expect(result, contains('a-b-a-c')); // reverse
        expect(result, contains('a-a-b-c')); // sort
        expect(result, contains('c-a-b')); // uniq
        expect(result, contains('4')); // size
      });

      test('handles default filter', () {
        // Test default filter with missing value
        final result1 = liquid.renderString(
          '<%= missing | default: "not found" %>',
          {},
        );
        expect(result1, equals('not found'));

        // Test default filter with actual value
        final result2 = liquid.renderString(
          '<%= actual | default: "fallback" %>',
          {'actual': 'real'},
        );
        expect(result2, equals('real'));
      });
    });

    group('Template.parse with custom delimiters', () {
      test('parses simple variable with custom delimiters', () {
        final template = Template.parse(
          'Hello [[ name ]]!',
          config: const LiquidConfig(varStart: '[[', varEnd: ']]'),
          data: {'name': 'World'},
        );
        expect(template.render(), equals('Hello World!'));
      });

      test('parses simple tag with custom delimiters', () {
        final template = Template.parse(
          '[% if show %]visible[% endif %]',
          config: const LiquidConfig(tagStart: '[%', tagEnd: '%]'),
          data: {'show': true},
        );
        expect(template.render(), equals('visible'));
      });

      test('parses mixed content with custom delimiters', () {
        final template = Template.parse(
          '[% if user %]Hello [[ name ]]![% endif %]',
          config: const LiquidConfig(
            tagStart: '[%',
            tagEnd: '%]',
            varStart: '[[',
            varEnd: ']]',
          ),
          data: {'user': true, 'name': 'Alice'},
        );
        expect(template.render(), equals('Hello Alice!'));
      });

      test('parses for loop with custom delimiters', () {
        final template = Template.parse(
          '[% for item in items %][[ item ]][% endfor %]',
          config: const LiquidConfig(
            tagStart: '[%',
            tagEnd: '%]',
            varStart: '[[',
            varEnd: ']]',
          ),
          data: {
            'items': ['a', 'b', 'c'],
          },
        );
        expect(template.render(), equals('abc'));
      });

      test('standard delimiters do not work with custom config', () {
        final template = Template.parse(
          'Hello {{ name }}!',
          config: const LiquidConfig(varStart: '[[', varEnd: ']]'),
          data: {'name': 'World'},
        );
        // {{ name }} should be treated as plain text
        expect(template.render(), equals('Hello {{ name }}!'));
      });

      test('async rendering works with custom delimiters', () async {
        final template = Template.parse(
          'Hello [[ name ]]!',
          config: const LiquidConfig(varStart: '[[', varEnd: ']]'),
          data: {'name': 'World'},
        );
        final result = await template.renderAsync();
        expect(result, equals('Hello World!'));
      });
    });
  });
}
