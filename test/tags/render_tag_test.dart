import 'package:file/memory.dart';
import 'package:liquify/src/fs.dart';
import 'package:test/test.dart';
import 'shared.dart';

void main() {
  late TagTestCase fixture;
  late MemoryFileSystem fileSystem;
  late FileSystemRoot root;

  setUp(() {
    fixture = TagTestCase()..setUp();
    fileSystem = MemoryFileSystem();
    root = FileSystemRoot('/templates', fileSystem: fileSystem);
    fixture.evaluator.context.setRoot(root);

    // Set up mock templates
    fileSystem.file('/templates/simple.liquid')
      ..createSync(recursive: true)
      ..writeAsStringSync('Hello, {{ name }}!');
    // Add remaining template setup...
  });

  tearDown(() {
    fixture.tearDown();
  });

  group('RenderTag', () {
    test('renders a simple template', () {
      fixture.expectTemplateOutput(
          '{% render "simple.liquid" name: "World" %}', 'Hello, World!');
    });

    // Add remaining render tag tests...
  });
}

