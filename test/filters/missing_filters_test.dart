import 'package:liquify/src/filters/array.dart';
import 'package:liquify/src/filters/misc.dart';

import 'package:test/test.dart';

void main() {
  group('Missing Filter Tests', () {
    test('jsonify (alias for json)', () {
      final map = {'name': 'John', 'age': 30};
      final result = json(map, [], {});
      expect(result, equals('{"name":"John","age":30}'));

      final indentedResult = json(map, [2], {});
      expect(indentedResult, contains('{\n  "name"'));
    });

    test('lower (alias for downcase)', () {
      expect(lower('HELLO WORLD', [], {}), equals('hello world'));
      expect(lower('MiXeD cAsE', [], {}), equals('mixed case'));
      expect(lower('', [], {}), equals(''));
      expect(lower('already lowercase', [], {}), equals('already lowercase'));
      expect(lower(123, [], {}), equals('123'));
    });

    test('upper (alias for upcase)', () {
      expect(upper('hello world', [], {}), equals('HELLO WORLD'));
      expect(upper('MiXeD cAsE', [], {}), equals('MIXED CASE'));
      expect(upper('', [], {}), equals(''));
      expect(upper('ALREADY UPPERCASE', [], {}), equals('ALREADY UPPERCASE'));
      expect(upper(123, [], {}), equals('123'));
    });
  });
}
