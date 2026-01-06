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

  group('Comment Tag', () {
    group('sync evaluation', () {
      test('shows raw text', () async {
        await testParser(
          '''{% comment %}
  Navigation Component
  
  Usage:
    {% render 'components/navigation' %}
    {% render 'components/navigation', current_page: 'posts' %}
  
  Parameters:
    - current_page: Optional current page for highlighting active nav items
{% endcomment %}
''',
          (document) {
            evaluator.evaluateNodes(document.children);
            expect(evaluator.buffer.toString().trim(), isEmpty);
          },
        );
      });
    });

    group('async evaluation', () {
      test('shows raw text', () async {
        await testParser(
          '''{% comment %}
  Navigation Component
  
  Usage:
    {% render 'components/navigation' %}
    {% render 'components/navigation', current_page: 'posts' %}
  
  Parameters:
    - current_page: Optional current page for highlighting active nav items
{% endcomment %}
''',
          (document) async {
            await evaluator.evaluateNodesAsync(document.children);
            expect(evaluator.buffer.toString().trim(), isEmpty);
          },
        );
      });
    });
  });
}
