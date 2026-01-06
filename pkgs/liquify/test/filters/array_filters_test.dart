import 'dart:async';

import 'package:liquify/src/filter_registry.dart';
import 'package:liquify/src/filters/array.dart';

import 'package:test/test.dart';

void main() {
  group('Array Filters', () {
    group('Async Filters', () {
      setUp(() {
        FilterRegistry.register('fetchData', (value, args, namedArgs) async {
          await Future.delayed(Duration(milliseconds: 100));
          return 'data-$value';
        });

        FilterRegistry.register('slowMultiply', (value, args, namedArgs) async {
          await Future.delayed(Duration(milliseconds: 50));
          final multiplier = args.isNotEmpty ? args[0] : 2;
          return value * multiplier;
        });
      });

      test('handles single async filter', () async {
        final result = await FilterRegistry.getFilter('fetchData')!(
          '123',
          [],
          {},
        );
        expect(result, equals('data-123'));
      });

      test('handles async filter with arguments', () async {
        final result = await FilterRegistry.getFilter('slowMultiply')!(5, [
          3,
        ], {});
        expect(result, equals(15));
      });

      test('registered async filter preserves Future return type', () {
        final filter = FilterRegistry.getFilter('fetchData')!;
        final result = filter('test', [], {});
        expect(result, isA<Future>());
      });
    });

    test('upper', () {
      expect(upper('Hello World', [], {}), equals('HELLO WORLD'));
      expect(upper('already upper', [], {}), equals('ALREADY UPPER'));
    });

    test('lower', () {
      expect(lower('Hello World', [], {}), equals('hello world'));
      expect(lower('ALREADY LOWER', [], {}), equals('already lower'));
    });

    test('join', () {
      expect(join([1, 2, 3], [', '], {}), equals('1, 2, 3'));
      expect(join(['a', 'b', 'c'], [], {}), equals('a b c'));
      expect(join('not a list', [', '], {}), equals('not a list'));
    });

    test('first', () {
      expect(first([1, 2, 3], [], {}), equals(1));
      expect(first([], [], {}), equals(''));
      expect(first('not a list', [], {}), equals(''));
    });

    test('last', () {
      expect(last([1, 2, 3], [], {}), equals(3));
      expect(last([], [], {}), equals(''));
      expect(last('not a list', [], {}), equals(''));
    });

    test('reverse', () {
      expect(reverse([1, 2, 3], [], {}), equals([3, 2, 1]));
      expect(reverse([], [], {}), equals([]));
      expect(reverse('not a list', [], {}), equals('not a list'));
    });

    test('size', () {
      expect(size([1, 2, 3], [], {}), equals(3));
      expect(size([], [], {}), equals(0));
      expect(size('string', [], {}), equals(6));
      expect(size(123, [], {}), equals(0));
    });

    test('sort', () {
      expect(sort([3, 1, 2], [], {}), equals([1, 2, 3]));
      expect(sort(['c', 'a', 'b'], [], {}), equals(['a', 'b', 'c']));
      expect(sort([], [], {}), equals([]));
      expect(sort('not a list', [], {}), equals('not a list'));
    });

    test('map', () {
      var input = [
        {'name': 'Alice'},
        {'name': 'Bob'},
      ];
      expect(map(input, ['name'], {}), equals(['Alice', 'Bob']));
      expect(map([], ['name'], {}), equals([]));
      expect(map('not a list', ['name'], {}), equals('not a list'));
      expect(map([1, 2, 3], ['nonexistent'], {}), equals([null, null, null]));
    });

    test('map without property returns input', () {
      final input = [
        {'name': 'Alice'},
      ];
      expect(map(input, [], {}), equals(input));
    });

    test('map returns null for non-map items', () {
      expect(
        map(
          [
            {'name': 'Alice'},
            'Bob',
          ],
          ['name'],
          {},
        ),
        equals(['Alice', null]),
      );
    });

    test('where', () {
      var input = [
        {'name': 'Alice', 'age': 30},
        {'name': 'Bob', 'age': 25},
        {'name': 'Charlie', 'age': 30},
      ];
      expect(
        where(input, ['age', 30], {}),
        equals([
          {'name': 'Alice', 'age': 30},
          {'name': 'Charlie', 'age': 30},
        ]),
      );
      expect(where(input, ['age'], {}), equals(input));
      expect(where([], ['age', 30], {}), equals([]));
      expect(where('not a list', ['age', 30], {}), equals('not a list'));
    });

    test('where excludes null properties', () {
      final input = [
        {'name': 'Alice', 'age': null},
        {'name': 'Bob', 'age': 25},
      ];
      expect(
        where(input, ['age'], {}),
        equals([
          {'name': 'Bob', 'age': 25},
        ]),
      );
    });

    test('uniq', () {
      expect(uniq([1, 2, 2, 3, 3, 3], [], {}), equals([1, 2, 3]));
      expect(uniq(['a', 'b', 'b', 'c'], [], {}), equals(['a', 'b', 'c']));
      expect(uniq([], [], {}), equals([]));
      expect(uniq('not a list', [], {}), equals('not a list'));
    });

    test('slice', () {
      expect(slice([1, 2, 3, 4, 5], [1, 2], {}), equals([2, 3]));
      expect(slice([1, 2, 3], [1], {}), equals([2]));
      expect(slice('abcde', [1, 2], {}), equals('bc'));
      expect(slice([], [1, 2], {}), equals([]));
      expect(slice('', [1, 2], {}), equals(''));
      expect(slice(123, [1, 2], {}), equals(123));
      expect(slice([1, 2, 3], [10, 2], {}), equals([]));
      expect(slice([1, 2, 3], [-1, 2], {}), equals([3]));
      expect(slice([1, 2, 3], [-2, 2], {}), equals([2, 3]));
      expect(slice([1, 2, 3], [0, 10], {}), equals([1, 2, 3]));
      expect(slice('abcde', [3, 5], {}), equals('de'));
      expect(slice([1], [0, 0], {}), equals([]));
      expect(slice([1, 2, 3], [1, -1], {}), equals([]));
      expect(slice([1, 2, 3], [-5, 2], {}), equals([1, 2]));
    });

    test('compact', () {
      expect(compact([1, null, 2, null, 3], [], {}), equals([1, 2, 3]));
      expect(compact([null, null], [], {}), equals([]));
      expect(compact([1, 2, 3], [], {}), equals([1, 2, 3]));
      expect(compact([], [], {}), equals([]));
      expect(compact('not a list', [], {}), equals('not a list'));
      expect(
        compact([1, '', false, 0, null], [], {}),
        equals([1, '', false, 0]),
      );
    });

    test('concat', () {
      expect(
        concat(
          [1, 2],
          [
            [3, 4],
          ],
          {},
        ),
        equals([1, 2, 3, 4]),
      );
      expect(
        concat(
          ['a', 'b'],
          [
            ['c', 'd'],
          ],
          {},
        ),
        equals(['a', 'b', 'c', 'd']),
      );
      expect(
        concat([], [
          [1, 2],
        ], {}),
        equals([1, 2]),
      );
      expect(concat([1, 2], [[]], {}), equals([1, 2]));
      expect(concat([1, 2], [], {}), equals([1, 2]));
      expect(
        concat('not a list', [
          [1, 2],
        ], {}),
        equals('not a list'),
      );
      expect(concat([1, 2], ['not a list'], {}), equals([1, 2]));
    });

    test('reject', () {
      var input = [
        {'type': 'kitchen', 'name': 'Spatula'},
        {'type': 'living', 'name': 'Couch'},
        {'type': 'kitchen', 'name': 'Fork'},
        {'type': 'bedroom', 'name': 'Bed'},
      ];
      expect(
        reject(input, ['type', 'kitchen'], {}),
        equals([
          {'type': 'living', 'name': 'Couch'},
          {'type': 'bedroom', 'name': 'Bed'},
        ]),
      );

      var truthyInput = [
        {'available': true, 'name': 'Item1'},
        {'available': false, 'name': 'Item2'},
        {'available': null, 'name': 'Item3'},
        {'available': '', 'name': 'Item4'},
        {'available': 0, 'name': 'Item5'},
      ];
      expect(
        reject(truthyInput, ['available'], {}),
        equals([
          {'available': false, 'name': 'Item2'},
          {'available': null, 'name': 'Item3'},
          {'available': '', 'name': 'Item4'},
          {'available': 0, 'name': 'Item5'},
        ]),
      );

      expect(reject([], ['type', 'kitchen'], {}), equals([]));
      expect(
        reject('not a list', ['type', 'kitchen'], {}),
        equals('not a list'),
      );
      expect(reject(input, [], {}), equals(input));
    });

    test('reject keeps non-map items', () {
      final input = [
        {'type': 'kitchen', 'name': 'Spatula'},
        'Loose',
      ];
      expect(reject(input, ['type', 'kitchen'], {}), equals(['Loose']));
    });

    test('push', () {
      expect(push([1, 2], [3], {}), equals([1, 2, 3]));
      expect(push([], ['item'], {}), equals(['item']));
      expect(push(['a', 'b'], ['c'], {}), equals(['a', 'b', 'c']));
      expect(push([1, 2], [], {}), equals([1, 2]));
      expect(push('not a list', [3], {}), equals('not a list'));
    });

    test('pop', () {
      expect(pop([1, 2, 3], [], {}), equals([1, 2]));
      expect(pop([1], [], {}), equals([]));
      expect(pop([], [], {}), equals([]));
      expect(pop('not a list', [], {}), equals('not a list'));
    });

    test('shift', () {
      expect(shift([1, 2, 3], [], {}), equals([2, 3]));
      expect(shift([1], [], {}), equals([]));
      expect(shift([], [], {}), equals([]));
      expect(shift('not a list', [], {}), equals('not a list'));
    });

    test('unshift', () {
      expect(unshift([2, 3], [1], {}), equals([1, 2, 3]));
      expect(unshift([], ['item'], {}), equals(['item']));
      expect(unshift(['b', 'c'], ['a'], {}), equals(['a', 'b', 'c']));
      expect(unshift([1, 2], [], {}), equals([1, 2]));
      expect(unshift('not a list', [1], {}), equals('not a list'));
    });

    test('find', () {
      var input = [
        {'name': 'Alice', 'age': 30, 'active': true},
        {'name': 'Bob', 'age': 25, 'active': false},
        {'name': 'Charlie', 'age': 35, 'active': true},
      ];

      expect(
        find(input, ['name', 'Bob'], {}),
        equals({'name': 'Bob', 'age': 25, 'active': false}),
      );
      expect(
        find(input, ['age', 30], {}),
        equals({'name': 'Alice', 'age': 30, 'active': true}),
      );
      expect(find(input, ['name', 'David'], {}), equals(null));

      expect(
        find(input, ['active'], {}),
        equals({'name': 'Alice', 'age': 30, 'active': true}),
      );

      expect(find([], ['name', 'Bob'], {}), equals(null));
      expect(find('not a list', ['name', 'Bob'], {}), equals(null));
      expect(find(input, [], {}), equals(null));
    });

    test('find ignores non-map items', () {
      expect(find(['Alice', 'Bob'], ['name', 'Bob'], {}), equals(null));
    });

    test('findIndex', () {
      var input = [
        {'name': 'Alice', 'age': 30, 'active': true},
        {'name': 'Bob', 'age': 25, 'active': false},
        {'name': 'Charlie', 'age': 35, 'active': true},
      ];

      expect(findIndex(input, ['name', 'Bob'], {}), equals(1));
      expect(findIndex(input, ['age', 30], {}), equals(0));
      expect(findIndex(input, ['name', 'David'], {}), equals(-1));

      expect(findIndex(input, ['active'], {}), equals(0));

      expect(findIndex([], ['name', 'Bob'], {}), equals(-1));
      expect(findIndex('not a list', ['name', 'Bob'], {}), equals(-1));
      expect(findIndex(input, [], {}), equals(-1));
    });

    test('findIndex ignores non-map items', () {
      expect(findIndex(['Alice', 'Bob'], ['name', 'Bob'], {}), equals(-1));
    });

    test('sum', () {
      expect(sum([1, 2, 3, 4], [], {}), equals(10));
      expect(sum([1.5, 2.5, 3.0], [], {}), equals(7.0));
      expect(sum([], [], {}), equals(0));
      expect(sum([1, 'not a number', 3], [], {}), equals(4));

      var input = [
        {'price': 10, 'name': 'Item1'},
        {'price': 20, 'name': 'Item2'},
        {'price': 15, 'name': 'Item3'},
      ];
      expect(sum(input, ['price'], {}), equals(45));

      var mixedInput = [
        {'price': 10, 'name': 'Item1'},
        {'price': 'invalid', 'name': 'Item2'},
        {'price': 15, 'name': 'Item3'},
      ];
      expect(sum(mixedInput, ['price'], {}), equals(25));

      expect(sum('not a list', [], {}), equals(0));
      expect(sum(input, ['nonexistent'], {}), equals(0));
    });

    test('sum ignores non-map entries', () {
      expect(
        sum(
          [
            {'price': 2},
            'skip',
          ],
          ['price'],
          {},
        ),
        equals(2),
      );
    });

    test('sortNatural', () {
      expect(
        sortNatural(['item10', 'item2', 'item1'], [], {}),
        equals(['item1', 'item2', 'item10']),
      );
      expect(
        sortNatural(['file1.txt', 'file10.txt', 'file2.txt'], [], {}),
        equals(['file1.txt', 'file2.txt', 'file10.txt']),
      );

      expect(
        sortNatural(['apple', 'banana', 'cherry'], [], {}),
        equals(['apple', 'banana', 'cherry']),
      );
      expect(
        sortNatural(['zebra', 'apple', 'banana'], [], {}),
        equals(['apple', 'banana', 'zebra']),
      );

      expect(
        sortNatural(['test', 'test1', 'test10', 'test2'], [], {}),
        equals(['test', 'test1', 'test2', 'test10']),
      );

      expect(sortNatural([3, 1, 2], [], {}), equals([1, 2, 3]));

      expect(sortNatural([], [], {}), equals([]));
      expect(sortNatural('not a list', [], {}), equals('not a list'));
    });

    test('groupBy', () {
      var input = [
        {'position': 'Accountant', 'name': 'Ann'},
        {'position': 'Salesman', 'name': 'Adam'},
        {'position': 'Accountant', 'name': 'Angela'},
      ];

      var expected = [
        {
          'name': 'Accountant',
          'items': [
            {'position': 'Accountant', 'name': 'Ann'},
            {'position': 'Accountant', 'name': 'Angela'},
          ],
        },
        {
          'name': 'Salesman',
          'items': [
            {'position': 'Salesman', 'name': 'Adam'},
          ],
        },
      ];

      expect(groupBy(input, ['position'], {}), equals(expected));
      expect(groupBy([], ['position'], {}), equals([]));
      expect(groupBy('not a list', ['position'], {}), equals('not a list'));
      expect(groupBy(input, [], {}), equals(input));
    });

    test('groupBy groups missing properties under empty key', () {
      final input = [
        {'type': 'A', 'name': 'Item1'},
        {'name': 'Item2'},
      ];
      final result = groupBy(input, ['type'], {});
      expect(
        result,
        equals([
          {
            'name': 'A',
            'items': [
              {'type': 'A', 'name': 'Item1'},
            ],
          },
          {
            'name': '',
            'items': [
              {'name': 'Item2'},
            ],
          },
        ]),
      );
    });

    test('has', () {
      var input = [
        {'active': true, 'name': 'Item1'},
        {'active': false, 'name': 'Item2'},
        {'inactive': true, 'name': 'Item3'},
      ];

      expect(has(input, ['active', true], {}), equals(true));
      expect(has(input, ['active', false], {}), equals(true));
      expect(has(input, ['active', 'missing'], {}), equals(false));
      expect(has(input, ['missing', true], {}), equals(false));

      expect(has(input, ['active'], {}), equals(true));
      expect(has(input, ['inactive'], {}), equals(true));

      var emptyInput = [
        {'active': null, 'name': 'Item1'},
        {'active': '', 'name': 'Item2'},
        {'active': 0, 'name': 'Item3'},
      ];
      expect(has(emptyInput, ['active'], {}), equals(false));

      expect(has([], ['active', true], {}), equals(false));
      expect(has('not a list', ['active', true], {}), equals(false));
      expect(has(input, [], {}), equals(false));
    });

    test('has ignores non-map items', () {
      expect(has([1, 2, 3], ['active'], {}), equals(false));
    });

    test('length', () {
      expect(length('hello', [], {}), equals(5));
      expect(length('', [], {}), equals(0));

      expect(length([1, 2, 3], [], {}), equals(3));
      expect(length([], [], {}), equals(0));

      expect(length(123, [], {}), equals(0));
      expect(length(null, [], {}), equals(0));
    });

    test('whereExp', () {
      var input = [
        {'type': 'kitchen', 'name': 'Spatula', 'price': 10},
        {'type': 'living', 'name': 'Couch', 'price': 500},
        {'type': 'kitchen', 'name': 'Fork', 'price': 5},
        {'type': 'bedroom', 'name': 'Bed', 'price': 800},
      ];

      expect(
        whereExp(input, ['item', 'item.type == "kitchen"'], {}),
        equals([
          {'type': 'kitchen', 'name': 'Spatula', 'price': 10},
          {'type': 'kitchen', 'name': 'Fork', 'price': 5},
        ]),
      );

      expect(
        whereExp(input, ['item', 'item.price > 100'], {}),
        equals([
          {'type': 'living', 'name': 'Couch', 'price': 500},
          {'type': 'bedroom', 'name': 'Bed', 'price': 800},
        ]),
      );

      expect(whereExp(input, ['item', 'item.type'], {}), equals(input));

      expect(whereExp([], ['item', 'item.type == "kitchen"'], {}), equals([]));
      expect(
        whereExp('not a list', ['item', 'item.type == "kitchen"'], {}),
        equals('not a list'),
      );
      expect(whereExp(input, ['item'], {}), equals(input));
    });

    test('findExp', () {
      var input = [
        {'type': 'kitchen', 'name': 'Spatula', 'active': true},
        {'type': 'living', 'name': 'Couch', 'active': false},
        {'type': 'kitchen', 'name': 'Fork', 'active': true},
      ];

      expect(
        findExp(input, ['item', 'item.type == "living"'], {}),
        equals({'type': 'living', 'name': 'Couch', 'active': false}),
      );

      expect(
        findExp(input, ['item', 'item.active == true'], {}),
        equals({'type': 'kitchen', 'name': 'Spatula', 'active': true}),
      );

      expect(
        findExp(input, ['item', 'item.type == "bathroom"'], {}),
        equals(null),
      );

      expect(
        findExp(input, ['item', 'item.active'], {}),
        equals({'type': 'kitchen', 'name': 'Spatula', 'active': true}),
      );

      expect(findExp([], ['item', 'item.type == "kitchen"'], {}), equals(null));
      expect(
        findExp('not a list', ['item', 'item.type == "kitchen"'], {}),
        equals(null),
      );
      expect(findExp(input, ['item'], {}), equals(null));
    });

    test('findIndexExp', () {
      var input = [
        {'type': 'kitchen', 'name': 'Spatula'},
        {'type': 'living', 'name': 'Couch'},
        {'type': 'kitchen', 'name': 'Fork'},
      ];

      expect(
        findIndexExp(input, ['item', 'item.type == "living"'], {}),
        equals(1),
      );
      expect(
        findIndexExp(input, ['item', 'item.name == "Fork"'], {}),
        equals(2),
      );

      expect(
        findIndexExp(input, ['item', 'item.type == "bathroom"'], {}),
        equals(-1),
      );

      expect(findIndexExp(input, ['item', 'item.type'], {}), equals(0));

      expect(
        findIndexExp([], ['item', 'item.type == "kitchen"'], {}),
        equals(-1),
      );
      expect(
        findIndexExp('not a list', ['item', 'item.type == "kitchen"'], {}),
        equals(-1),
      );
      expect(findIndexExp(input, ['item'], {}), equals(-1));
    });

    test('groupByExp', () {
      var input = [
        {'graduation_year': 2013, 'name': 'Jay'},
        {'graduation_year': 2014, 'name': 'John'},
        {'graduation_year': 2009, 'name': 'Jack'},
        {'graduation_year': 2013, 'name': 'Jane'},
      ];

      var result = groupByExp(input, ['item', 'item.graduation_year'], {});
      expect(result, isA<List>());
      expect(result.length, equals(3));

      var groups = <String, List>{};
      for (var group in result) {
        if (group is Map) {
          groups[group['name'].toString()] = group['items'] as List;
        }
      }

      expect(groups['2013']?.length, equals(2));
      expect(groups['2014']?.length, equals(1));
      expect(groups['2009']?.length, equals(1));

      expect(groupByExp([], ['item', 'item.graduation_year'], {}), equals([]));
      expect(
        groupByExp('not a list', ['item', 'item.graduation_year'], {}),
        equals('not a list'),
      );
      expect(groupByExp(input, ['item'], {}), equals(input));
    });

    test('hasExp', () {
      var input = [
        {'active': true, 'name': 'Item1', 'price': 10},
        {'active': false, 'name': 'Item2', 'price': 20},
        {'inactive': true, 'name': 'Item3', 'price': 30},
      ];

      expect(hasExp(input, ['item', 'item.active == true'], {}), equals(true));
      expect(hasExp(input, ['item', 'item.active == false'], {}), equals(true));
      expect(
        hasExp(input, ['item', 'item.active == "missing"'], {}),
        equals(false),
      );

      expect(hasExp(input, ['item', 'item.price > 15'], {}), equals(true));
      expect(hasExp(input, ['item', 'item.price > 50'], {}), equals(false));

      expect(hasExp(input, ['item', 'item.active'], {}), equals(true));
      expect(hasExp(input, ['item', 'item.missing'], {}), equals(false));

      expect(hasExp([], ['item', 'item.active == true'], {}), equals(false));
      expect(
        hasExp('not a list', ['item', 'item.active == true'], {}),
        equals(false),
      );
      expect(hasExp(input, ['item'], {}), equals(false));
    });

    test('rejectExp', () {
      var input = [
        {'type': 'kitchen', 'name': 'Spatula', 'taxable': true},
        {'type': 'living', 'name': 'Couch', 'taxable': false},
        {'type': 'kitchen', 'name': 'Fork', 'taxable': true},
        {'type': 'bedroom', 'name': 'Bed', 'taxable': false},
      ];

      expect(
        rejectExp(input, ['item', 'item.type == "kitchen"'], {}),
        equals([
          {'type': 'living', 'name': 'Couch', 'taxable': false},
          {'type': 'bedroom', 'name': 'Bed', 'taxable': false},
        ]),
      );

      expect(
        rejectExp(input, ['item', 'item.taxable == true'], {}),
        equals([
          {'type': 'living', 'name': 'Couch', 'taxable': false},
          {'type': 'bedroom', 'name': 'Bed', 'taxable': false},
        ]),
      );

      expect(
        rejectExp(input, ['item', 'item.taxable'], {}),
        equals([
          {'type': 'living', 'name': 'Couch', 'taxable': false},
          {'type': 'bedroom', 'name': 'Bed', 'taxable': false},
        ]),
      );

      expect(rejectExp([], ['item', 'item.type == "kitchen"'], {}), equals([]));
      expect(
        rejectExp('not a list', ['item', 'item.type == "kitchen"'], {}),
        equals('not a list'),
      );
      expect(rejectExp(input, ['item'], {}), equals(input));
    });
  });
}
