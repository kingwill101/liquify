import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class SizeTag extends WidgetTagBase with AsyncTag {
  SizeTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final size = _parseSize(evaluator);
    if (size.$1 != null) {
      setPropertyValue(evaluator.context, 'width', size.$1);
    }
    if (size.$2 != null) {
      setPropertyValue(evaluator.context, 'height', size.$2);
    }
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final size = _parseSize(evaluator);
    if (size.$1 != null) {
      setPropertyValue(evaluator.context, 'width', size.$1);
    }
    if (size.$2 != null) {
      setPropertyValue(evaluator.context, 'height', size.$2);
    }
  }

  (double?, double?) _parseSize(Evaluator evaluator) {
    double? width;
    double? height;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'width':
          width = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'height':
          height = toDouble(evaluator.evaluate(arg.value));
          break;
        default:
          handleUnknownArg('size', name);
          break;
      }
    }
    return (width, height);
  }
}
