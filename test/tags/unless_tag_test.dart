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

  group('Unless Tag', () {
    group('sync evaluation', () {
      test('renders when false', () async {
        await testParser(
            '{% unless product.title == "Awesome Shoes" %}These shoes are not awesome.{% endunless %}',
            (document) {
          evaluator.context.setVariable('product', {'title': 'Terrible Shoes'});
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), 'These shoes are not awesome.');
        });
      });

      test('doesnt render when true', () async {
        await testParser(
            '{% unless product.title == "Awesome Shoes" %}These shoes are not awesome.{% endunless %}',
            (document) {
          evaluator.context.setVariable('product', {'title': 'Awesome Shoes'});
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), '');
        });
      });

      test('handles nested unless', () async {
        await testParser('''
          {% unless product.title == "Awesome Shoes" %}
            {% unless product.price > 100 %}
              Affordable non-awesome shoes!
            {% endunless %}
          {% endunless %}
        ''', (document) {
          evaluator.context
              .setVariable('product', {'title': 'Terrible Shoes', 'price': 50});
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().trim(),
              'Affordable non-awesome shoes!');
        });
      });
    });

    group('async evaluation', () {
      test('renders when false', () async {
        await testParser(
            '{% unless product.title == "Awesome Shoes" %}These shoes are not awesome.{% endunless %}',
            (document) async {
          evaluator.context.setVariable('product', {'title': 'Terrible Shoes'});
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), 'These shoes are not awesome.');
        });
      });

      test('doesnt render when true', () async {
        await testParser(
            '{% unless product.title == "Awesome Shoes" %}These shoes are not awesome.{% endunless %}',
            (document) async {
          evaluator.context.setVariable('product', {'title': 'Awesome Shoes'});
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), '');
        });
      });

      test('handles nested unless', () async {
        await testParser('''
          {% unless product.title == "Awesome Shoes" %}
            {% unless product.price > 100 %}
              Affordable non-awesome shoes!
            {% endunless %}
          {% endunless %}
        ''', (document) async {
          evaluator.context
              .setVariable('product', {'title': 'Terrible Shoes', 'price': 50});
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().trim(),
              'Affordable non-awesome shoes!');
        });
      });
    });
  });
}
