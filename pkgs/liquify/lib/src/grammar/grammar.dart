import 'package:liquify/src/grammar/shared.dart';

class LiquidGrammar extends GrammarDefinition {
  @override
  Parser start() => ref0(document).end();
}
