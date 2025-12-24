import 'package:petitparser/petitparser.dart';

mixin CustomTagParser {
  Parser parser() {
    return epsilon();
  }
}
