import 'package:file/memory.dart';
import 'package:liquify/src/context.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/fs.dart';
import 'package:test/test.dart';

import 'shared.dart';

void main() {
  late Evaluator evaluator;
  late MemoryFileSystem fileSystem;
  late FileSystemRoot root;

  setUp(() {
    evaluator = Evaluator(Environment());
    fileSystem = MemoryFileSystem();
    root = FileSystemRoot('/templates', fileSystem: fileSystem);
    evaluator.context.setRoot(root);

    // Set up base layout template
    fileSystem.file('/templates/layouts/base.liquid')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
<!DOCTYPE html>
<html>
<head>
  <title>{% block title %}Default Title{% endblock %}</title>
  <link rel="stylesheet" href="/styles.css">
</head>
<body>
  <header>
    {% block header %}Default Header{% endblock %}
  </header>
  <main>
    {% block content %}Default Content{% endblock %}
  </main>
  <footer>
    {% block footer %}Default Footer{% endblock %}
  </footer>
  <script src="/main.js"></script>
</body>
</html>''');

    // Set up post layout template
    fileSystem.file('/templates/layouts/post.liquid')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
{% layout "layouts/base.liquid" %}
{% block title %}Post Title{% endblock %}
{% block content %}Post Content{% endblock %}
''');

    // Set up actual post template
    fileSystem.file('/templates/posts/hello-world.liquid')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
{% layout "layouts/post.liquid" %}
{% block content %}Hello, World!{% endblock %}
''');
  });

  tearDown(() {
    evaluator.context.clear();
  });

  group('Nested Layouts', () {
    group('sync evaluation', () {
      test('nested layout inheritance', () async {
        await testParser('''
          {% layout "posts/hello-world.liquid" %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(
              evaluator.buffer.toString().trim(),
              '''
<!DOCTYPE html>
<html>
<head>
  <title>Post Title</title>
  <link rel="stylesheet" href="/styles.css">
</head>
<body>
  <header>
    Default Header
  </header>
  <main>
    Hello, World!
  </main>
  <footer>
    Default Footer
  </footer>
  <script src="/main.js"></script>
</body>
</html>'''
                  .trim());
        });
      });
    });

//     group('async evaluation', () {
//       test('nested layout inheritance', () async {
//         await testParser('''
//           {% layout "posts/hello-world.liquid" %}
//         ''', (document) async {
//           await evaluator.evaluateNodesAsync(document.children);
//           expect(evaluator.buffer.toString().trim(), '''
// <!DOCTYPE html>
// <html>
// <head>
//   <title>Post Title</title>
//   <link rel="stylesheet" href="/styles.css">
// </head>
// <body>
//   <header>
//     Default Header
//   </header>
//   <main>
//     Hello, World!
//   </main>
//   <footer>
//     Default Footer
//   </footer>
//   <script src="/main.js"></script>
// </body>
// </html>'''.trim());
//         });
//       });
//     });
  });
}
