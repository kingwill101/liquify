import 'package:liquify/src/context.dart';
import 'package:liquify/src/evaluator.dart';
import '../support/shared.dart';
import '../support/golden_harness.dart';

void main() {
  late Evaluator evaluator;

  setUp(() {
    evaluator = Evaluator(Environment());
  });

  tearDown(() {
    evaluator.context.clear();
  });
  group('Capture Tag', () {
    group('sync evaluation', () {
      test('outputs captured data', () async {
        await testParser(
          '{% capture my_variable %}I am being captured.{% endcapture %}{{ my_variable }}',
          (document) {
            evaluator.evaluateNodes(document.children);
            expect(evaluator.buffer.toString(), 'I am being captured.');
          },
        );
      });

      test('captures with filters', () async {
        await testParser(
          '{% capture my_variable %}Hello {{ "World" | upcase }}{% endcapture %}{{ my_variable }}',
          (document) {
            evaluator.evaluateNodes(document.children);
            expect(evaluator.buffer.toString(), 'Hello WORLD');
          },
        );
      });

      test('captures tag output', () async {
        await testParser(
          '{% capture my_variable %}{% echo "Hello" %}{% endcapture %}{{ my_variable }}',
          (document) {
            evaluator.evaluateNodes(document.children);
            expect(evaluator.buffer.toString(), 'Hello');
          },
        );
      });

      test('routes liquid tag output through active buffer', () async {
        await testParser(
          '{% liquid echo "Hello" %}',
          (document) {
            evaluator.startBlockCapture();
            evaluator.evaluateNodes(document.children);
            final captured = evaluator.endBlockCapture();
            expect(captured, 'Hello');
            expect(evaluator.buffer.toString(), '');
          },
        );
      });
    });

    group('async evaluation', () {
      test('outputs captured data', () async {
        await testParser(
          '{% capture my_variable %}I am being captured.{% endcapture %}{{ my_variable }}',
          (document) async {
            await evaluator.evaluateNodesAsync(document.children);
            expect(evaluator.buffer.toString(), 'I am being captured.');
          },
        );
      });

      test('captures with filters', () async {
        await testParser(
          '{% capture my_variable %}Hello {{ "World" | upcase }}{% endcapture %}{{ my_variable }}',
          (document) async {
            await evaluator.evaluateNodesAsync(document.children);
            expect(evaluator.buffer.toString(), 'Hello WORLD');
          },
        );
      });

      test('captures tag output', () async {
        await testParser(
          '{% capture my_variable %}{% echo "Hello" %}{% endcapture %}{{ my_variable }}',
          (document) async {
            await evaluator.evaluateNodesAsync(document.children);
            expect(evaluator.buffer.toString(), 'Hello');
          },
        );
      });

      test('routes liquid tag output through active buffer', () async {
        await testParser(
          '{% liquid echo "Hello" %}',
          (document) async {
            evaluator.startBlockCapture();
            await evaluator.evaluateNodesAsync(document.children);
            final captured = evaluator.endBlockCapture();
            expect(captured, 'Hello');
            expect(evaluator.buffer.toString(), '');
          },
        );
      });
    });
  });
}
