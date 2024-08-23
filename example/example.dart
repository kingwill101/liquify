import 'package:liquify/liquify.dart';

void main() {
  final result = Template.parse('''{% assign my_name = "Bob" %}
{{ user.name.first | upper }}
{{ my_name }}
''', data: {
    'user': {
      'name': {'first': 'Bob'}
    },
  });

  print(result);
}
