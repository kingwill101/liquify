import 'package:liquify/src/context.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:test/test.dart';

import '../shared.dart';

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
        });
      });

      test('captures with filters', () async {
        await testParser(
            '{% capture my_variable %}Hello {{ "World" | upcase }}{% endcapture %}{{ my_variable }}',
            (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), 'Hello WORLD');
        });
      });
    });

    group('async evaluation', () {
      test('outputs captured data', () async {
        await testParser(
            '{% capture my_variable %}I am being captured.{% endcapture %}{{ my_variable }}',
            (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), 'I am being captured.');
        });
      });

      test('captures with filters', () async {
        await testParser(
            '{% capture my_variable %}Hello {{ "World" | upcase }}{% endcapture %}{{ my_variable }}',
            (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), 'Hello WORLD');
        });
      });
    });
  });
}
