// Example demonstrating custom delimiters in Liquify.
//
// This example shows how to use the [Liquid] class with custom delimiters
// for parsing and rendering Liquid templates.
import 'package:liquify/liquify.dart';

void main() {
  // Basic usage with default delimiters
  defaultDelimitersExample();

  // Custom delimiters
  customDelimitersExample();

  // ERB-style delimiters
  erbDelimitersExample();

  // Whitespace control
  whitespaceControlExample();

  // Multiple Liquid instances
  multipleInstancesExample();

  // One-shot rendering
  oneShotRenderingExample();
}

/// Using default Liquid delimiters ({% %} and {{ }})
void defaultDelimitersExample() {
  print('\n--- Default Delimiters ---');

  final liquid = Liquid();
  final template = liquid.parse('Hello {{ name }}!');
  final result = template.render({'name': 'World'});

  print(result);
  // Output: Hello World!
}

/// Using custom delimiters ([% %] and [[ ]])
void customDelimitersExample() {
  print('\n--- Custom Delimiters ---');

  final liquid = Liquid(
    config: LiquidConfig(
      tagStart: '[%',
      tagEnd: '%]',
      varStart: '[[',
      varEnd: ']]',
    ),
  );

  // Block tags work with custom delimiters
  final template = liquid.parse('''
[% if show %]
  Hello [[ name ]]!
[% endif %]
''');

  final result = template.render({'show': true, 'name': 'Alice'});
  print(result);
  // Output:
  //   Hello Alice!

  // For loops also work
  final forTemplate = liquid.parse('''
[% for item in items %]
  - [[ item ]]
[% endfor %]
''');

  final forResult = forTemplate.render({
    'items': ['apple', 'banana', 'cherry'],
  });
  print(forResult);
  // Output:
  //   - apple
  //   - banana
  //   - cherry
}

/// Using ERB-style delimiters (<% %> and <%= %>)
void erbDelimitersExample() {
  print('\n--- ERB-Style Delimiters ---');

  // Using the ERB preset
  final liquid = Liquid(config: LiquidConfig.erb);

  final template = liquid.parse('''
<% if user %>
  Hello <%= user.name %>!
<% else %>
  Hello Guest!
<% endif %>
''');

  final result = template.render({
    'user': {'name': 'Bob'},
  });
  print(result);
  // Output:
  //   Hello Bob!

  // Alternative: use the convenience constructor
  final liquid2 = Liquid.withDelimiters(
    tagStart: '<%',
    tagEnd: '%>',
    varStart: '<%=',
    varEnd: '%>',
  );
  print(liquid2.renderString('<%= greeting %>', {'greeting': 'Hi there!'}));
  // Output: Hi there!
}

/// Whitespace control with custom delimiters
void whitespaceControlExample() {
  print('\n--- Whitespace Control ---');

  final liquid = Liquid(
    config: LiquidConfig(
      tagStart: '[%',
      tagEnd: '%]',
      varStart: '[[',
      varEnd: ']]',
      stripMarker: '-', // default
    ),
  );

  // Using strip markers to control whitespace
  final template = liquid.parse('''
Items:
[%- for item in items -%]
[[ item ]]
[%- endfor -%]
Done!''');

  final result = template.render({
    'items': ['a', 'b', 'c'],
  });
  print(result);
  // Output: Items:
  // a
  // b
  // c
  // Done!
}

/// Using multiple Liquid instances with different configurations
void multipleInstancesExample() {
  print('\n--- Multiple Instances ---');

  // Standard Liquid
  final standard = Liquid();

  // ERB-style
  final erb = Liquid(config: LiquidConfig.erb);

  // Custom brackets
  final brackets = Liquid.withDelimiters(
    tagStart: '<<',
    tagEnd: '>>',
    varStart: '<<<',
    varEnd: '>>>',
  );

  // Parse with different syntaxes
  final t1 = standard.parse('Hello {{ name }}!');
  final t2 = erb.parse('Hello <%= name %>!');
  final t3 = brackets.parse('Hello <<< name >>>!');

  final data = {'name': 'World'};

  print('Standard: ${t1.render(data)}');
  print('ERB:      ${t2.render(data)}');
  print('Brackets: ${t3.render(data)}');
  // Output:
  // Standard: Hello World!
  // ERB:      Hello World!
  // Brackets: Hello World!
}

/// One-shot rendering without storing the template
void oneShotRenderingExample() {
  print('\n--- One-Shot Rendering ---');

  final liquid = Liquid(
    config: LiquidConfig(
      tagStart: '[%',
      tagEnd: '%]',
      varStart: '[[',
      varEnd: ']]',
    ),
  );

  // For templates used only once, use renderString
  final result = liquid.renderString(
    '[% if active %]Status: [[ status ]][% endif %]',
    {'active': true, 'status': 'Online'},
  );

  print(result);
  // Output: Status: Online
}
