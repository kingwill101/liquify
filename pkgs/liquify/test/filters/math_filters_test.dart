import 'package:liquify/src/filters/math.dart';

import 'package:test/test.dart';

void main() {
  group('Math Filters', () {
    test('abs', () {
      expect(abs(-5, [], {}), equals(5));
      expect(abs(5, [], {}), equals(5));
      expect(abs(0, [], {}), equals(0));
      expect(abs(-2.5, [], {}), equals(2.5));
    });

    test('at_least', () {
      expect(atLeast(5, [10], {}), equals(10));
      expect(atLeast(15, [10], {}), equals(15));
      expect(() => atLeast(5, [], {}), throwsArgumentError);
    });

    test('at_most', () {
      expect(atMost(5, [10], {}), equals(5));
      expect(atMost(15, [10], {}), equals(10));
      expect(() => atMost(5, [], {}), throwsArgumentError);
    });

    test('ceil', () {
      expect(ceil(5.1, [], {}), equals(6));
      expect(ceil(5.9, [], {}), equals(6));
      expect(ceil(5.0, [], {}), equals(5));
      expect(ceil(-2.1, [], {}), equals(-2));
    });

    test('divided_by', () {
      expect(dividedBy(10, [2], {}), equals(5));
      expect(dividedBy(10, [3], {}), equals(10 / 3));
      expect(dividedBy(10, [3, true], {}), equals(3));
      expect(() => dividedBy(10, [], {}), throwsArgumentError);
    });

    test('floor', () {
      expect(floor(5.1, [], {}), equals(5));
      expect(floor(5.9, [], {}), equals(5));
      expect(floor(5.0, [], {}), equals(5));
      expect(floor(-2.1, [], {}), equals(-3));
    });

    test('minus', () {
      expect(minus(10, [3], {}), equals(7));
      expect(minus(3, [10], {}), equals(-7));
      expect(() => minus(10, [], {}), throwsArgumentError);
    });

    test('modulo', () {
      expect(modulo(10, [3], {}), equals(1));
      expect(modulo(-10, [3], {}), equals(2));
      expect(modulo(10, [-3], {}), equals(1));
      expect(modulo(-10, [-3], {}), equals(2));
      expect(() => modulo(10, [], {}), throwsArgumentError);
    });

    test('times', () {
      expect(times(5, [3], {}), equals(15));
      expect(times(-5, [3], {}), equals(-15));
      expect(() => times(5, [], {}), throwsArgumentError);
    });

    test('round', () {
      expect(round(5.5, [], {}), equals(6));
      expect(round(5.4, [], {}), equals(5));
      expect(round(5.1234, [2], {}), equals(5.12));
      expect(round(5.1254, [2], {}), equals(5.13));
      expect(round(-2.5, [], {}), equals(-3));
    });

    test('plus', () {
      expect(plus(5, [3], {}), equals(8));
      expect(plus(-5, [3], {}), equals(-2));
      expect(() => plus(5, [], {}), throwsArgumentError);
    });

    group('null handling', () {
      test('abs handles null values', () {
        expect(abs(null, [], {}), equals(0));
      });

      test('at_least handles null values', () {
        expect(atLeast(null, [10], {}), equals(10));
        expect(atLeast(5, [null], {}), equals(5));
        expect(atLeast(null, [null], {}), equals(0));
      });

      test('at_most handles null values', () {
        expect(atMost(null, [10], {}), equals(0));
        expect(atMost(15, [null], {}), equals(0));
        expect(atMost(null, [null], {}), equals(0));
      });

      test('ceil handles null values', () {
        expect(ceil(null, [], {}), equals(0));
      });

      test('divided_by handles null values and division by zero', () {
        expect(dividedBy(null, [2], {}), equals(0));
        expect(dividedBy(10, [null], {}), equals(10));
        expect(dividedBy(null, [null], {}), equals(0));
        expect(dividedBy(10, [0], {}), equals(0));
      });

      test('floor handles null values', () {
        expect(floor(null, [], {}), equals(0));
      });

      test('minus handles null values', () {
        expect(minus(null, [3], {}), equals(-3));
        expect(minus(10, [null], {}), equals(10));
        expect(minus(null, [null], {}), equals(0));
      });

      test('modulo handles null values and modulo by zero', () {
        expect(modulo(null, [3], {}), equals(0));
        expect(modulo(10, [null], {}), equals(0));
        expect(modulo(null, [null], {}), equals(0));
        expect(modulo(10, [0], {}), equals(0));
      });

      test('times handles null values', () {
        expect(times(null, [3], {}), equals(0));
        expect(times(5, [null], {}), equals(0));
        expect(times(null, [null], {}), equals(0));
      });

      test('round handles null values', () {
        expect(round(null, [], {}), equals(0));
        expect(round(null, [2], {}), equals(0));
      });

      test('plus handles null values', () {
        expect(plus(null, [3], {}), equals(3));
        expect(plus(5, [null], {}), equals(5));
        expect(plus(null, [null], {}), equals(0));
      });
    });
  });
}
