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
    test('renders when false', () {
      testParser(
          '{% unless product.title == "Awesome Shoes" %}These shoes are not awesome.{% endunless %}',
          (document) {
        evaluator.context.setVariable('product', {'title': 'Terrible Shoes'});
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'These shoes are not awesome.');
      });
    });

    test('doesnt render when true', () {
      testParser(
          '{% unless product.title == "Awesome Shoes" %}These shoes are not awesome.{% endunless %}',
          (document) {
        evaluator.context
            .setVariable('product', {'title': 'These shoes are not awesome.'});
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'These shoes are not awesome.');
      });
    });
  });
}