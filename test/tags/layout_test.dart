import 'package:file/memory.dart';
import 'package:liquify/src/context.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/fs.dart';
import 'package:test/test.dart';

import '../shared.dart';

void main() {
  late Evaluator evaluator;
  late MemoryFileSystem fileSystem;
  late FileSystemRoot root;

  setUp(() {
    evaluator = Evaluator(Environment());
    fileSystem = MemoryFileSystem();
    root = FileSystemRoot('/templates', fileSystem: fileSystem);
    evaluator.context.setRoot(root);

    // Set up default layout template
    fileSystem.file('/templates/default-layout.liquid')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
Header
{% block content %}Default content{% endblock %}
Footer''');

    // Set up multi-block layout template
    fileSystem.file('/templates/multi-block-layout.liquid')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
{% block header %}Default Header{% endblock %}
{% block content %}Default Content{% endblock %}
{% block footer %}Default Footer{% endblock %}''');
  });

  tearDown(() {
    evaluator.context.clear();
  });

  group('Layout Tag', () {
    group('sync evaluation', () {
      test('basic layout usage', () async {
        await testParser('''
          {% layout "default-layout.liquid" %}
          {% block content %}My page content{% endblock %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(
              evaluator.buffer.toString().trim(),
              '''
Header
My page content
Footer'''
                  .trim());
        });
      });

      test('multiple named blocks', () async {
        await testParser('''
          {% layout "multi-block-layout.liquid" %}
          {% block header %}Custom Header{% endblock %}
          {% block content %}Custom Content{% endblock %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(
              evaluator.buffer.toString().trim(),
              '''
Custom Header
Custom Content
Default Footer'''
                  .trim());
        });
      });

      test('default block contents', () async {
        await testParser('''
          {% layout "default-layout.liquid" %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(
              evaluator.buffer.toString().trim(),
              '''
Header
Default content
Footer'''
                  .trim());
        });
      });

      test('passing variables to layout', () async {
        await testParser('''
          {% assign title = "My Page" %}
          {% layout "default-layout.liquid", my_variable: title %}
          {% block content %}
            {{ my_variable }}
          {% endblock %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          final output = evaluator.buffer.toString();
          expect(output, contains('My Page'));
          expect(output, contains('Header'));
          expect(output, contains('Footer'));
        });
      });

      test('multiple variables with literal values', () async {
        await testParser('''
          {% layout "default-layout.liquid", title: "Page Title", subtitle: "Welcome" %}
          {% block content %}
            {{ title }} - {{ subtitle }}
          {% endblock %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          final output = evaluator.buffer.toString();
          expect(output, contains('Page Title'));
          expect(output, contains('Welcome'));
        });
      });

      test('nested layouts with multiple blocks and variables', () async {
        // Set up nested layout template
        fileSystem.file('/templates/layouts/nested.liquid')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
{% layout "default-layout.liquid" %}
{% block header %}{{ page_title | upcase }}{% endblock %}
{% block content %}
  <h1>{{ page_title }}</h1>
  {% block subcontent %}Default subcontent{% endblock %}
{% endblock %}''');

        await testParser('''
      {% layout "layouts/nested.liquid", page_title: "Welcome" %}
      {% block subcontent %}
        <p>Custom subcontent</p>
        <span>{{ page_title }}</span>
      {% endblock %}
    ''', (document) {
          evaluator.evaluateNodes(document.children);
          final output = evaluator.buffer.toString();
          expect(output, contains('<h1>Welcome</h1>'));
          expect(output, contains('<p>Custom subcontent</p>'));
          expect(output, contains('<span>Welcome</span>'));
        });
      });
    });

    group('async evaluation', () {
      test('basic layout usage', () async {
        await testParser('''
          {% layout "default-layout.liquid" %}
          {% block content %}My page content{% endblock %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(
              evaluator.buffer.toString().trim(),
              '''
Header
My page content
Footer'''
                  .trim());
        });
      });

      test('multiple named blocks', () async {
        await testParser('''
          {% layout "multi-block-layout.liquid" %}
          {% block header %}Custom Header{% endblock %}
          {% block content %}Custom Content{% endblock %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(
              evaluator.buffer.toString().trim(),
              '''
Custom Header
Custom Content
Default Footer'''
                  .trim());
        });
      });

      test('default block contents', () async {
        await testParser('''
          {% layout "default-layout.liquid" %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(
              evaluator.buffer.toString().trim(),
              '''
Header
Default content
Footer'''
                  .trim());
        });
      });

      test('passing variables to layout', () async {
        await testParser('''
          {% assign title = "My Page" %}
          {% layout "default-layout.liquid", my_variable: title %}
          {% block content %}
            {{ my_variable }}
          {% endblock %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          final output = evaluator.buffer.toString();
          expect(output, contains('My Page'));
          expect(output, contains('Header'));
          expect(output, contains('Footer'));
        });
      });

      test('multiple variables with literal values', () async {
        await testParser('''
          {% layout "default-layout.liquid", title: "Page Title", subtitle: "Welcome" %}
          {% block content %}
            {{ title }} - {{ subtitle }}
          {% endblock %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          final output = evaluator.buffer.toString();
          expect(output, contains('Page Title'));
          expect(output, contains('Welcome'));
        });
      });

      test('nested layouts with multiple blocks and variables', () async {
        // Set up nested layout template
        fileSystem.file('/templates/layouts/nested.liquid')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
{% layout "default-layout.liquid" %}
{% block header %}{{ page_title | upcase }}{% endblock %}
{% block content %}
  <h1>{{ page_title }}</h1>
  {% block subcontent %}Default subcontent{% endblock %}
{% endblock %}''');

        await testParser('''
      {% layout "layouts/nested.liquid", page_title: "Welcome" %}
      {% block subcontent %}
        <p>Custom subcontent</p>
        <span>{{ page_title }}</span>
      {% endblock %}
    ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          final output = evaluator.buffer.toString();
          expect(output, contains('<h1>Welcome</h1>'));
          expect(output, contains('<p>Custom subcontent</p>'));
          expect(output, contains('<span>Welcome</span>'));
        });
      });
    });
  });
}
