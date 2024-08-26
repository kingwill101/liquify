import 'package:liquify/liquify.dart';
import 'package:liquify/parser.dart';
import 'package:test/test.dart';

void main() {
  late Evaluator evaluator;

  setUp(() {
    registerBuiltIns();
    evaluator = Evaluator(Environment());
    evaluator.context
        .setVariable('name', PersonDrop(firstName: "John", lastName: "Jones"));
  });

  tearDown(() {
    evaluator.context.clear();
  });

  group('Drop', () {
    test('properties', () async {
      expect(
          Template.parse('{{ name.lastName }}', evaluator: evaluator).render(),
          equals('Jones'));
    });

    test('nesting', () async {
      var template =
          Template.parse('{{ name.address.country }}', evaluator: evaluator)
              .render();
      expect(template, equals('U.S.A'));
    });

    test('invokable', () async {
      expect(
          Template.parse('{{ name.first }} {{ name.last }}',
                  evaluator: evaluator)
              .render(),
          equals('John Jones'));
    });
  });
}

class AddressDrop extends Drop {
  @override
  Map<String, dynamic> get attrs => {"country": "U.S.A"};
}

class PersonDrop extends Drop {
  String firstName;
  String lastName;

  PersonDrop({required this.firstName, required this.lastName});

  String fullName() {
    return '$firstName $lastName';
  }

  @override
  Map<String, dynamic> get attrs => {
        "firstName": firstName,
        "lastName": lastName,
        "fullName": fullName(),
        "address": AddressDrop(),
      };

  @override
  List<Symbol> get invokable => [
        ...super.invokable,
        #first,
        #last,
      ];

  @override
  invoke(Symbol symbol) {
    switch (symbol) {
      case #first:
        return firstName;
      case #last:
        return lastName;
      default:
        return liquidMethodMissing(symbol);
    }
  }
}
