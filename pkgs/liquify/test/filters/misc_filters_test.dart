import 'package:liquify/src/filters/misc.dart';

import 'package:test/test.dart';

void main() {
  group('Misc Filters', () {
    test('defaultFilter', () {
      expect(defaultFilter(null, ['default'], {}), equals('default'));
      expect(defaultFilter('', ['default'], {}), equals('default'));
      expect(defaultFilter([], ['default'], {}), equals('default'));
      expect(defaultFilter(false, ['default'], {}), equals('default'));
      expect(defaultFilter(false, ['default', true], {}), equals(false));
      expect(defaultFilter('value', ['default'], {}), equals('value'));
      expect(defaultFilter(42, ['default'], {}), equals(42));
      expect(() => defaultFilter('value', [], {}), throwsArgumentError);
    });

    test('defaultFilter does not treat empty maps as falsy', () {
      final input = <String, dynamic>{};
      expect(defaultFilter(input, ['default'], {}), equals(input));
    });

    test('defaultFilter still treats 0 as falsy', () {
      expect(defaultFilter(0, ['default', true], {}), equals('default'));
    });

    test('json', () {
      expect(json({'a': 1, 'b': 2}, [], {}), equals('{"a":1,"b":2}'));
      expect(json({'a': 1, 'b': 2}, [2], {}),
          equals('{\n  "a": 1,\n  "b": 2\n}'));
      expect(json([1, 2, 3], [], {}), equals('[1,2,3]'));
      expect(json('string', [], {}), equals('"string"'));
      expect(json(42, [], {}), equals('42'));
    });

    test('json ignores non-positive indentation', () {
      expect(json({'a': 1}, [0], {}), equals('{"a":1}'));
      expect(json({'a': 1}, [-2], {}), equals('{"a":1}'));
    });

    test('parse_json', () {
      expect(parseJson('{"a":1,"b":2}', [], {}), equals({'a': 1, 'b': 2}));

      expect(parseJson('[1,2,3]', [], {}), equals([1, 2, 3]));

      expect(parseJson('"hello"', [], {}), equals('hello'));

      expect(parseJson('42', [], {}), equals(42));
      expect(parseJson('3.14', [], {}), equals(3.14));

      expect(parseJson('true', [], {}), equals(true));
      expect(parseJson('false', [], {}), equals(false));

      expect(parseJson('null', [], {}), equals(null));

      expect(
          parseJson(
              '{"users":[{"name":"John","age":30},{"name":"Jane","age":25}]}',
              [],
              {}),
          equals({
            'users': [
              {'name': 'John', 'age': 30},
              {'name': 'Jane', 'age': 25}
            ]
          }));

      expect(parseJson('  { "key" : "value" }  ', [], {}),
          equals({'key': 'value'}));

      expect(() => parseJson(null, [], {}), throwsArgumentError);
      expect(() => parseJson('invalid json', [], {}), throwsFormatException);
      expect(() => parseJson('{invalid}', [], {}), throwsFormatException);
      expect(() => parseJson('{"incomplete":', [], {}), throwsFormatException);
    });

    test('inspect with circular references', () {
      var nestedCircular = <String, dynamic>{
        'a': <String, dynamic>{'b': <String, dynamic>{}}
      };

      var aMap = nestedCircular['a'] as Map<String, dynamic>;
      var bMap = aMap['b'] as Map<String, dynamic>;
      bMap['c'] = aMap;

      expect(inspect(nestedCircular, [], {}),
          equals('{"a":{"b":{"c":"[Circular]"}}}'));
    });

    test('inspect handles list cycles', () {
      final list = [];
      list.add(list);
      expect(inspect(list, [], {}), equals('["[Circular]"]'));
    });

    test('inspect with indentation', () {
      final result = inspect({'a': 1}, [2], {});
      expect(result, contains('\n  "a": 1'));
    });

    test('toInteger', () {
      expect(toInteger('42', [], {}), equals(42));
      expect(toInteger(42.5, [], {}), equals(43));
      expect(toInteger('-10', [], {}), equals(-10));
      expect(() => toInteger('not a number', [], {}), throwsFormatException);
    });

    test('toInteger throws on non-integer strings', () {
      expect(() => toInteger('3.14', [], {}), throwsFormatException);
    });

    test('raw', () {
      expect(raw('string', [], {}), equals('string'));
      expect(raw(42, [], {}), equals(42));
      expect(raw({'a': 1}, [], {}), equals({'a': 1}));
      expect(raw([1, 2, 3], [], {}), equals([1, 2, 3]));
      expect(raw(null, [], {}), equals(null));
    });
  });
}
