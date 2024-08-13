import 'package:liquid_grammar/liquid_grammar.dart';

void main() {
  final parser = LiquidGrammarDefinition().build();

  final result = parser.parse(r'''
 {% assign raw_content = "raw content" %}
{{ user.name.first.something | upper }}
{{ raw_content | date }}
''');

  if (result.isSuccess) {

    print(result.value);
  } else {
    print('Parsing failed: ${result.message}');
  }
}
