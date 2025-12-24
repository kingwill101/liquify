import 'package:liquify/parser.dart';

class RepeatTag extends AbstractTag with AsyncTag, CustomTagParser {
  RepeatTag(super.content, super.filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    final count = evaluator.evaluate(content.first);
    final times = count is int ? count : int.parse(count.toString());

    final buffers = List.generate(times, (_) {
      Buffer currentBuffer = Buffer();
      final inner = evaluator.createInnerEvaluatorWithBuffer(currentBuffer);

      for (final node in body) {
        final value = inner.evaluate(node);
        if (value != null) currentBuffer.write(value);
      }
      return currentBuffer.toString().trim();
    });

    // Join with single space and apply filters
    final value = buffers.join(' ');
    buffer.write(applyFilters(value, evaluator));
  }

  @override
  Future<dynamic> evaluateAsync(Evaluator evaluator, Buffer buffer) async {
    final times =
        int.parse((await evaluator.evaluateAsync(content.first)).toString());
    final contentNodes = List<ASTNode>.from(body);

    final buffers = await Future.wait(List.generate(times, (_) async {
      Buffer currentBuffer = Buffer();
      final inner = evaluator.createInnerEvaluatorWithBuffer(currentBuffer);

      for (final node in contentNodes) {
        final value = await inner.evaluateAsync(node);
        if (value != null) currentBuffer.write(value);
      }
      return currentBuffer.toString().trim();
    }));

    final repeatedContent = buffers.join(' ');
    final filtered = await applyFiltersAsync(repeatedContent, evaluator);
    buffer.write(filtered);
  }

  Parser repeatTag() => someTag("repeat");

  Parser repeatBlock() => seq3(
        ref0(repeatTag),
        ref0(element).starLazy(endRepeatTag()),
        ref0(endRepeatTag),
      ).map((values) {
        return values.$1.copyWith(body: values.$2.cast<ASTNode>());
      });

  Parser endRepeatTag() =>
      (tagStart() & string('endrepeat').trim() & tagEnd()).map((values) {
        return Tag('endrepeat', []);
      });

  @override
  Parser parser() => repeatBlock();
}
