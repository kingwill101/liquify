import 'package:liquify/src/context.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:test/test.dart';
import '../shared.dart' show testParser;

class TagTestCase {
  late Evaluator evaluator;

  setUp() {
    evaluator = Evaluator(Environment());
  }

  tearDown() {
    evaluator.context.clear();
  }

  void expectTemplateOutput(String template, String expected) async {
    testParser(template, (document) async {
      await evaluator.evaluate(document);
      expect(evaluator.buffer.toString(), expected);
    });
  }

  void expectTemplateContains(String template, String substring) async {
    testParser(template, (document) async {
      await evaluator.evaluate(document);
      expect(evaluator.buffer.toString(), contains(substring));
    });
  }

  void expectTemplateNotContains(String template, String substring) async {
    testParser(template, (document) async {
      await evaluator.evaluate(document);
      expect(evaluator.buffer.toString(), isNot(contains(substring)));
    });
  }
}
