import 'package:liquify/liquify.dart';

void main() {
  // Create a simple file system structure using MapRoot
  final fs = MapRoot({
    'resume.liquid': '''
Name: {{ name }}
Skills: {{ skills | join: ", " }}
{% render 'greeting.liquid' with name: name, greeting: "Welcome" %}
Experience:
{% render 'list.liquid' with items: experience %}
''',
    'greeting.liquid': '{{ greeting }}, {{ name }}!',
    'list.liquid': '{% for item in items %}- {{ item }}\n{% endfor %}',
  });

  // Create a context with some variables
  final context = {
    'name': 'Alice Johnson',
    'skills': ['Dart', 'Flutter', 'Liquid'],
    'experience': [
      '5 years as a Software Developer',
      '3 years of Flutter development',
      '2 years of Dart programming',
    ],
  };

  // Example 1: Render resume (which includes greeting and list)
  print('Example 1: Render resume (including greeting and list)');
  final resumeTemplate = Template.fromFile('resume.liquid', fs, data: context);
  print(resumeTemplate.render());

  // Example 2: Render greeting directly
  print('\nExample 2: Render greeting directly');
  final greetingTemplate = Template.fromFile(
    'greeting.liquid',
    fs,
    data: {'name': 'Bob', 'greeting': 'Good morning'},
  );
  print(greetingTemplate.render());

  // Example 3: Render list directly
  print('\nExample 3: Render list directly');
  final listTemplate = Template.fromFile(
    'list.liquid',
    fs,
    data: {
      'items': ['Item 1', 'Item 2', 'Item 3'],
    },
  );
  print(listTemplate.render());

  // Example 4: Attempt to render non-existent file
  print('\nExample 4: Attempt to render non-existent file');
  try {
    Template.fromFile('nonexistent.liquid', fs, data: context);
  } catch (e) {
    print('Error: $e');
  }
}
