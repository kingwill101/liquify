import 'package:liquify/src/tag.dart';
import 'package:liquify/src/tags/if.dart';

class UnlessTag extends IfTag {
  UnlessTag(super.content, super.filters);

  @override
  bool get negateCondition => true;
}

Parser unlessTag([LiquidConfig? config]) =>
    someTag('unless', config: config, content: ref0(conditionTagContent));

Parser endUnlessTag([LiquidConfig? config]) =>
    someTag('endunless', config: config, hasContent: false);
