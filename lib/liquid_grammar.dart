import 'package:petitparser/petitparser.dart';

class LiquidGrammarDefinition extends GrammarDefinition {
  @override
  Parser start() => ref0(template).trim().end();

  Parser template() => ref0(content).star();

  Parser content() => ref0(liquidTag) | ref0(liquidOutput) | ref0(rawContent);

  Parser rawContent() => pattern('^{%{{').plus().flatten();

  Parser liquidTag() => (string('{%') &
          ref0(spaces) &
          ref0(tagContent) &
          ref0(spaces) &
          string('%}'))
      .map((values) => {'type': 'tag', 'content': values[2]});

  Parser liquidOutput() => (string('{{') &
          ref0(spaces) &
          ref0(outputContent) &
          ref0(spaces) &
          string('}}'))
      .map((values) => {'type': 'output', 'content': values[2]});

  Parser tagContent() =>
      (ref0(identifier) & ref0(spaces) & ref0(tagArguments).optional())
          .map((values) => {'name': values[0], 'arguments': values[2] ?? []});

  Parser tagArguments() => (ref0(keyValueArgument) | ref0(simpleArgument))
      .separatedBy(ref0(spaces), includeSeparators: false)
      .map((values) => values);

  Parser keyValueArgument() =>
      (ref0(identifier) & ref0(spaces) & char(':') & ref0(spaces) & ref0(expression))
          .map((values) => {
                'type': 'assignment',
                'variable': values[0],
                'value': values[4]
              });

  Parser simpleArgument() => ref0(expression);

  Parser outputContent() => ref0(expression);

  Parser expression() => ref0(comparison) | ref0(assignment) | ref0(filteredTerm) | ref0(term);

  Parser comparison() => (
        ref0(term) &
        ref0(spaces) &
        ref0(comparisonOperator) &
        ref0(spaces) &
        ref0(term)
      ).map((values) => {
            'type': 'comparison',
            'left': values[0],
            'operator': values[2],
            'right': values[4]
          });

  Parser comparisonOperator() =>
      string('==') | string('!=') | string('>=') | string('<=') | char('>') | char('<');

  Parser assignment() => (ref0(identifier) &
          ref0(spaces) &
          char('=') &
          ref0(spaces) &
          ref0(expression))
      .map((values) =>
          {'type': 'assignment', 'variable': values[0], 'value': values[4]});

  Parser filteredTerm() =>
      (ref0(term) & (char('|') & ref0(filter).trim()).plus()).map((values) => {
            'type': 'filterChain',
            'base': values[0],
            'filters': values[1].map((f) => f[1]).toList()
          });

  Parser filter() =>
      (ref0(identifier) & (char(':') & ref0(term).trim()).optional()).map(
          (values) => {
                'name': values[0],
                'argument': values[1] != null ? values[1][1] : null
              });

  Parser term() => ref0(literal) | ref0(variable);

  Parser literal() => ref0(stringLiteral) | ref0(numberLiteral);

  Parser variable() => ref0(identifier)
      .separatedBy(char('.'), includeSeparators: false)
      .map((values) => {'type': 'variable', 'path': values.join('.')});

  Parser identifier() =>
      ((letter() | char('_')) & (word() | char('_')).star()).flatten().trim();

  Parser stringLiteral() =>
      (char('"') & pattern('^"').star().flatten() & char('"') |
              char("'") & pattern("^'").star().flatten() & char("'"))
          .map((values) => {'type': 'string', 'value': values[1]});

  Parser numberLiteral() => digit()
      .plus()
      .flatten()
      .map((value) => {'type': 'number', 'value': num.parse(value)});

  Parser spaces() => whitespace().star();
}
