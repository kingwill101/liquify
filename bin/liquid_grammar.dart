
import 'package:liquid_grammar/grammar.dart';
import 'package:petitparser/core.dart';

void main() {
  final parser = LiquidGrammar().build();

  final result = parser.parse(r'''
 {% assign raw_content = "raw content" %}
{{ user.name.first.something | upper }}
{{ raw_content | date }}
''');

  if (result is Success) {

    print(result.value);
  } else {
    print('Parsing failed: ${result.message}');
  }
}
