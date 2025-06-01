import 'dart:async';

import 'package:intl/intl.dart';
import 'package:liquify/src/filter_registry.dart';
import 'package:liquify/src/filters/array.dart';
import 'package:liquify/src/filters/date.dart';
import 'package:liquify/src/filters/html.dart' as html;
import 'package:liquify/src/filters/math.dart';
import 'package:liquify/src/filters/misc.dart';
import 'package:liquify/src/filters/string.dart';
import 'package:liquify/src/filters/url.dart';
import 'package:test/test.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUp(() {
    ensureTimezonesInitialized();
    tz.setLocalLocation(tz.getLocation('America/New_York'));
  });

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
        final result =
            await FilterRegistry.getFilter('fetchData')!('123', [], {});
        expect(result, equals('data-123'));
      });

      test('handles async filter with arguments', () async {
        final result =
            await FilterRegistry.getFilter('slowMultiply')!(5, [3], {});
        expect(result, equals(15));
      });

      test('registered async filter preserves Future return type', () {
        final filter = FilterRegistry.getFilter('fetchData')!;
        final result = filter('test', [], {});
        expect(result, isA<Future>());
      });
    });
    test('join', () {
      expect(join([1, 2, 3], [', '], {}), equals('1, 2, 3'));
      expect(
          join(['a', 'b', 'c'], [], {}), equals('a b c')); // default separator
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
      expect(size(123, [], {}), equals(0)); // non-string, non-list
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
        {'name': 'Bob'}
      ];
      expect(map(input, ['name'], {}), equals(['Alice', 'Bob']));
      expect(map([], ['name'], {}), equals([]));
      expect(map('not a list', ['name'], {}), equals('not a list'));
      expect(map([1, 2, 3], ['nonexistent'], {}), equals([null, null, null]));
    });

    test('where', () {
      var input = [
        {'name': 'Alice', 'age': 30},
        {'name': 'Bob', 'age': 25},
        {'name': 'Charlie', 'age': 30}
      ];
      expect(
          where(input, ['age', 30], {}),
          equals([
            {'name': 'Alice', 'age': 30},
            {'name': 'Charlie', 'age': 30}
          ]));
      expect(where(input, ['age'], {}), equals(input)); // all have 'age'
      expect(where([], ['age', 30], {}), equals([]));
      expect(where('not a list', ['age', 30], {}), equals('not a list'));
    });

    test('uniq', () {
      expect(uniq([1, 2, 2, 3, 3, 3], [], {}), equals([1, 2, 3]));
      expect(uniq(['a', 'b', 'b', 'c'], [], {}), equals(['a', 'b', 'c']));
      expect(uniq([], [], {}), equals([]));
      expect(uniq('not a list', [], {}), equals('not a list'));
    });

    test('slice', () {
      expect(slice([1, 2, 3, 4, 5], [1, 2], {}), equals([2, 3]));
      expect(slice([1, 2, 3], [1], {}), equals([2])); // default length 1
      expect(slice('abcde', [1, 2], {}), equals('bc'));
      expect(slice([], [1, 2], {}), equals([]));
      expect(slice('', [1, 2], {}), equals(''));
      expect(slice(123, [1, 2], {}), equals(123)); // non-string, non-list
      expect(slice([1, 2, 3], [10, 2], {}), equals([])); // start beyond end
      expect(slice([1, 2, 3], [-1, 2], {}),
          equals([3])); // negative index from end
      expect(slice([1, 2, 3], [-2, 2], {}),
          equals([2, 3])); // negative index from end
      expect(slice([1, 2, 3], [0, 10], {}),
          equals([1, 2, 3])); // length beyond end
      expect(slice('abcde', [3, 5], {}), equals('de')); // string slice
      expect(slice([1], [0, 0], {}), equals([])); // zero length
      expect(slice([1, 2, 3], [1, -1], {}), equals([])); // negative length
      expect(slice([1, 2, 3], [-5, 2], {}),
          equals([1, 2])); // negative index beyond start
    });

    test('compact', () {
      expect(compact([1, null, 2, null, 3], [], {}), equals([1, 2, 3]));
      expect(compact([null, null], [], {}), equals([]));
      expect(compact([1, 2, 3], [], {}), equals([1, 2, 3]));
      expect(compact([], [], {}), equals([]));
      expect(compact('not a list', [], {}), equals('not a list'));
      // Note: compact only removes null values, not empty strings or false
      expect(
          compact([1, '', false, 0, null], [], {}), equals([1, '', false, 0]));
    });

    test('concat', () {
      expect(
          concat([
            1,
            2
          ], [
            [3, 4]
          ], {}),
          equals([1, 2, 3, 4]));
      expect(
          concat([
            'a',
            'b'
          ], [
            ['c', 'd']
          ], {}),
          equals(['a', 'b', 'c', 'd']));
      expect(
          concat([], [
            [1, 2]
          ], {}),
          equals([1, 2]));
      expect(concat([1, 2], [[]], {}), equals([1, 2]));
      expect(concat([1, 2], [], {}), equals([1, 2])); // no argument
      expect(
          concat('not a list', [
            [1, 2]
          ], {}),
          equals('not a list'));
      expect(concat([1, 2], ['not a list'], {}),
          equals([1, 2])); // invalid argument
    });

    test('reject', () {
      var input = [
        {'type': 'kitchen', 'name': 'Spatula'},
        {'type': 'living', 'name': 'Couch'},
        {'type': 'kitchen', 'name': 'Fork'},
        {'type': 'bedroom', 'name': 'Bed'}
      ];
      expect(
          reject(input, ['type', 'kitchen'], {}),
          equals([
            {'type': 'living', 'name': 'Couch'},
            {'type': 'bedroom', 'name': 'Bed'}
          ]));

      // Test rejecting truthy values
      var truthyInput = [
        {'available': true, 'name': 'Item1'},
        {'available': false, 'name': 'Item2'},
        {'available': null, 'name': 'Item3'},
        {'available': '', 'name': 'Item4'},
        {'available': 0, 'name': 'Item5'}
      ];
      expect(
          reject(truthyInput, ['available'], {}),
          equals([
            {'available': false, 'name': 'Item2'},
            {'available': null, 'name': 'Item3'},
            {'available': '', 'name': 'Item4'},
            {'available': 0, 'name': 'Item5'}
          ]));

      expect(reject([], ['type', 'kitchen'], {}), equals([]));
      expect(
          reject('not a list', ['type', 'kitchen'], {}), equals('not a list'));
      expect(reject(input, [], {}), equals(input)); // no property specified
    });

    test('push', () {
      expect(push([1, 2], [3], {}), equals([1, 2, 3]));
      expect(push([], ['item'], {}), equals(['item']));
      expect(push(['a', 'b'], ['c'], {}), equals(['a', 'b', 'c']));
      expect(push([1, 2], [], {}), equals([1, 2])); // no argument
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
      expect(unshift([1, 2], [], {}), equals([1, 2])); // no argument
      expect(unshift('not a list', [1], {}), equals('not a list'));
    });

    test('find', () {
      var input = [
        {'name': 'Alice', 'age': 30, 'active': true},
        {'name': 'Bob', 'age': 25, 'active': false},
        {'name': 'Charlie', 'age': 35, 'active': true}
      ];

      expect(find(input, ['name', 'Bob'], {}),
          equals({'name': 'Bob', 'age': 25, 'active': false}));
      expect(find(input, ['age', 30], {}),
          equals({'name': 'Alice', 'age': 30, 'active': true}));
      expect(find(input, ['name', 'David'], {}), equals(null)); // not found

      // Test finding first truthy value
      expect(find(input, ['active'], {}),
          equals({'name': 'Alice', 'age': 30, 'active': true}));

      expect(find([], ['name', 'Bob'], {}), equals(null));
      expect(find('not a list', ['name', 'Bob'], {}), equals(null));
      expect(find(input, [], {}), equals(null)); // no property specified
    });

    test('findIndex', () {
      var input = [
        {'name': 'Alice', 'age': 30, 'active': true},
        {'name': 'Bob', 'age': 25, 'active': false},
        {'name': 'Charlie', 'age': 35, 'active': true}
      ];

      expect(findIndex(input, ['name', 'Bob'], {}), equals(1));
      expect(findIndex(input, ['age', 30], {}), equals(0));
      expect(findIndex(input, ['name', 'David'], {}), equals(-1)); // not found

      // Test finding first truthy value index
      expect(findIndex(input, ['active'], {}), equals(0));

      expect(findIndex([], ['name', 'Bob'], {}), equals(-1));
      expect(findIndex('not a list', ['name', 'Bob'], {}), equals(-1));
      expect(findIndex(input, [], {}), equals(-1)); // no property specified
    });

    test('sum', () {
      // Test summing array values
      expect(sum([1, 2, 3, 4], [], {}), equals(10));
      expect(sum([1.5, 2.5, 3.0], [], {}), equals(7.0));
      expect(sum([], [], {}), equals(0));
      expect(sum([1, 'not a number', 3], [], {}),
          equals(4)); // ignores non-numbers

      // Test summing property values
      var input = [
        {'price': 10, 'name': 'Item1'},
        {'price': 20, 'name': 'Item2'},
        {'price': 15, 'name': 'Item3'}
      ];
      expect(sum(input, ['price'], {}), equals(45));

      var mixedInput = [
        {'price': 10, 'name': 'Item1'},
        {'price': 'invalid', 'name': 'Item2'},
        {'price': 15, 'name': 'Item3'}
      ];
      expect(
          sum(mixedInput, ['price'], {}), equals(25)); // ignores invalid prices

      expect(sum('not a list', [], {}), equals(0));
      expect(
          sum(input, ['nonexistent'], {}), equals(0)); // property doesn't exist
    });

    test('sortNatural', () {
      // Test natural sorting with numbers
      expect(sortNatural(['item10', 'item2', 'item1'], [], {}),
          equals(['item1', 'item2', 'item10']));
      expect(sortNatural(['file1.txt', 'file10.txt', 'file2.txt'], [], {}),
          equals(['file1.txt', 'file2.txt', 'file10.txt']));

      // Test regular string sorting fallback
      expect(sortNatural(['apple', 'banana', 'cherry'], [], {}),
          equals(['apple', 'banana', 'cherry']));
      expect(sortNatural(['zebra', 'apple', 'banana'], [], {}),
          equals(['apple', 'banana', 'zebra']));

      // Test mixed content
      expect(sortNatural(['test', 'test1', 'test10', 'test2'], [], {}),
          equals(['test', 'test1', 'test2', 'test10']));

      // Test with numbers
      expect(sortNatural([3, 1, 2], [], {}), equals([1, 2, 3]));

      expect(sortNatural([], [], {}), equals([]));
      expect(sortNatural('not a list', [], {}), equals('not a list'));
    });

    test('groupBy', () {
      var input = [
        {'position': 'Accountant', 'name': 'Ann'},
        {'position': 'Salesman', 'name': 'Adam'},
        {'position': 'Accountant', 'name': 'Angela'}
      ];

      var expected = [
        {
          'name': 'Accountant',
          'items': [
            {'position': 'Accountant', 'name': 'Ann'},
            {'position': 'Accountant', 'name': 'Angela'}
          ]
        },
        {
          'name': 'Salesman',
          'items': [
            {'position': 'Salesman', 'name': 'Adam'}
          ]
        }
      ];

      expect(groupBy(input, ['position'], {}), equals(expected));
      expect(groupBy([], ['position'], {}), equals([]));
      expect(groupBy('not a list', ['position'], {}), equals('not a list'));
      expect(groupBy(input, [], {}), equals(input)); // no property specified
    });

    test('has', () {
      var input = [
        {'active': true, 'name': 'Item1'},
        {'active': false, 'name': 'Item2'},
        {'inactive': true, 'name': 'Item3'}
      ];

      expect(has(input, ['active', true], {}), equals(true));
      expect(has(input, ['active', false], {}), equals(true));
      expect(has(input, ['active', 'missing'], {}), equals(false));
      expect(has(input, ['missing', true], {}), equals(false));

      // Test checking for truthy values
      expect(has(input, ['active'], {}), equals(true));
      expect(has(input, ['inactive'], {}), equals(true));

      var emptyInput = [
        {'active': null, 'name': 'Item1'},
        {'active': '', 'name': 'Item2'},
        {'active': 0, 'name': 'Item3'}
      ];
      expect(has(emptyInput, ['active'], {}), equals(false)); // all falsy

      expect(has([], ['active', true], {}), equals(false));
      expect(has('not a list', ['active', true], {}), equals(false));
      expect(has(input, [], {}), equals(false)); // no property specified
    });

    test('length', () {
      // Test with strings
      expect(length('hello', [], {}), equals(5));
      expect(length('', [], {}), equals(0));

      // Test with arrays
      expect(length([1, 2, 3], [], {}), equals(3));
      expect(length([], [], {}), equals(0));

      // Test with other types
      expect(length(123, [], {}), equals(0));
      expect(length(null, [], {}), equals(0));
    });

    test('whereExp', () {
      var input = [
        {'type': 'kitchen', 'name': 'Spatula', 'price': 10},
        {'type': 'living', 'name': 'Couch', 'price': 500},
        {'type': 'kitchen', 'name': 'Fork', 'price': 5},
        {'type': 'bedroom', 'name': 'Bed', 'price': 800}
      ];

      // Test equality comparison
      expect(
          whereExp(input, ['item', 'item.type == "kitchen"'], {}),
          equals([
            {'type': 'kitchen', 'name': 'Spatula', 'price': 10},
            {'type': 'kitchen', 'name': 'Fork', 'price': 5}
          ]));

      // Test numeric comparison
      expect(
          whereExp(input, ['item', 'item.price > 100'], {}),
          equals([
            {'type': 'living', 'name': 'Couch', 'price': 500},
            {'type': 'bedroom', 'name': 'Bed', 'price': 800}
          ]));

      // Test simple property access (truthy)
      expect(whereExp(input, ['item', 'item.type'], {}),
          equals(input)); // all have truthy type

      expect(whereExp([], ['item', 'item.type == "kitchen"'], {}), equals([]));
      expect(whereExp('not a list', ['item', 'item.type == "kitchen"'], {}),
          equals('not a list'));
      expect(
          whereExp(input, ['item'], {}), equals(input)); // incomplete arguments
    });

    test('findExp', () {
      var input = [
        {'type': 'kitchen', 'name': 'Spatula', 'active': true},
        {'type': 'living', 'name': 'Couch', 'active': false},
        {'type': 'kitchen', 'name': 'Fork', 'active': true}
      ];

      // Test equality comparison
      expect(findExp(input, ['item', 'item.type == "living"'], {}),
          equals({'type': 'living', 'name': 'Couch', 'active': false}));

      // Test boolean comparison
      expect(findExp(input, ['item', 'item.active == true'], {}),
          equals({'type': 'kitchen', 'name': 'Spatula', 'active': true}));

      // Test not found
      expect(findExp(input, ['item', 'item.type == "bathroom"'], {}),
          equals(null));

      // Test simple property access
      expect(findExp(input, ['item', 'item.active'], {}),
          equals({'type': 'kitchen', 'name': 'Spatula', 'active': true}));

      expect(findExp([], ['item', 'item.type == "kitchen"'], {}), equals(null));
      expect(findExp('not a list', ['item', 'item.type == "kitchen"'], {}),
          equals(null));
      expect(
          findExp(input, ['item'], {}), equals(null)); // incomplete arguments
    });

    test('findIndexExp', () {
      var input = [
        {'type': 'kitchen', 'name': 'Spatula'},
        {'type': 'living', 'name': 'Couch'},
        {'type': 'kitchen', 'name': 'Fork'}
      ];

      // Test equality comparison
      expect(findIndexExp(input, ['item', 'item.type == "living"'], {}),
          equals(1));
      expect(
          findIndexExp(input, ['item', 'item.name == "Fork"'], {}), equals(2));

      // Test not found
      expect(findIndexExp(input, ['item', 'item.type == "bathroom"'], {}),
          equals(-1));

      // Test simple property access
      expect(findIndexExp(input, ['item', 'item.type'], {}),
          equals(0)); // first truthy

      expect(
          findIndexExp([], ['item', 'item.type == "kitchen"'], {}), equals(-1));
      expect(findIndexExp('not a list', ['item', 'item.type == "kitchen"'], {}),
          equals(-1));
      expect(findIndexExp(input, ['item'], {}),
          equals(-1)); // incomplete arguments
    });

    test('groupByExp', () {
      var input = [
        {'graduation_year': 2013, 'name': 'Jay'},
        {'graduation_year': 2014, 'name': 'John'},
        {'graduation_year': 2009, 'name': 'Jack'},
        {'graduation_year': 2013, 'name': 'Jane'}
      ];

      // Test simple property grouping
      var result = groupByExp(input, ['item', 'item.graduation_year'], {});
      expect(result, isA<List>());
      expect(result.length, equals(3)); // 2013, 2014, 2009

      // Check that groups are formed correctly
      var groups = <String, List>{};
      for (var group in result) {
        if (group is Map) {
          groups[group['name'].toString()] = group['items'] as List;
        }
      }

      expect(groups['2013']?.length, equals(2)); // Jay and Jane
      expect(groups['2014']?.length, equals(1)); // John
      expect(groups['2009']?.length, equals(1)); // Jack

      expect(groupByExp([], ['item', 'item.graduation_year'], {}), equals([]));
      expect(groupByExp('not a list', ['item', 'item.graduation_year'], {}),
          equals('not a list'));
      expect(groupByExp(input, ['item'], {}),
          equals(input)); // incomplete arguments
    });

    test('hasExp', () {
      var input = [
        {'active': true, 'name': 'Item1', 'price': 10},
        {'active': false, 'name': 'Item2', 'price': 20},
        {'inactive': true, 'name': 'Item3', 'price': 30}
      ];

      // Test equality comparison
      expect(hasExp(input, ['item', 'item.active == true'], {}), equals(true));
      expect(hasExp(input, ['item', 'item.active == false'], {}), equals(true));
      expect(hasExp(input, ['item', 'item.active == "missing"'], {}),
          equals(false));

      // Test numeric comparison
      expect(hasExp(input, ['item', 'item.price > 15'], {}), equals(true));
      expect(hasExp(input, ['item', 'item.price > 50'], {}), equals(false));

      // Test simple property access
      expect(hasExp(input, ['item', 'item.active'], {}), equals(true));
      expect(hasExp(input, ['item', 'item.missing'], {}), equals(false));

      expect(hasExp([], ['item', 'item.active == true'], {}), equals(false));
      expect(hasExp('not a list', ['item', 'item.active == true'], {}),
          equals(false));
      expect(
          hasExp(input, ['item'], {}), equals(false)); // incomplete arguments
    });

    test('rejectExp', () {
      var input = [
        {'type': 'kitchen', 'name': 'Spatula', 'taxable': true},
        {'type': 'living', 'name': 'Couch', 'taxable': false},
        {'type': 'kitchen', 'name': 'Fork', 'taxable': true},
        {'type': 'bedroom', 'name': 'Bed', 'taxable': false}
      ];

      // Test equality comparison
      expect(
          rejectExp(input, ['item', 'item.type == "kitchen"'], {}),
          equals([
            {'type': 'living', 'name': 'Couch', 'taxable': false},
            {'type': 'bedroom', 'name': 'Bed', 'taxable': false}
          ]));

      // Test boolean comparison
      expect(
          rejectExp(input, ['item', 'item.taxable == true'], {}),
          equals([
            {'type': 'living', 'name': 'Couch', 'taxable': false},
            {'type': 'bedroom', 'name': 'Bed', 'taxable': false}
          ]));

      // Test simple property access (reject truthy)
      expect(
          rejectExp(input, ['item', 'item.taxable'], {}),
          equals([
            {'type': 'living', 'name': 'Couch', 'taxable': false},
            {'type': 'bedroom', 'name': 'Bed', 'taxable': false}
          ]));

      expect(rejectExp([], ['item', 'item.type == "kitchen"'], {}), equals([]));
      expect(rejectExp('not a list', ['item', 'item.type == "kitchen"'], {}),
          equals('not a list'));
      expect(rejectExp(input, ['item'], {}),
          equals(input)); // incomplete arguments
    });
  });

  group('URL Filters', () {
    test('urlDecode', () {
      expect(urlDecode('hello+world', [], {}), equals('hello world'));
      expect(urlDecode('hello%20world', [], {}), equals('hello world'));
    });

    test('urlEncode', () {
      expect(urlEncode('hello world', [], {}), equals('hello+world'));
    });

    test('cgiEscape', () {
      expect(cgiEscape("It's a test!", [], {}), equals('It%27s+a+test%21'));
    });

    test('uriEscape', () {
      expect(uriEscape('http://example.com/path[1]/test', [], {}),
          equals('http://example.com/path[1]/test'));
    });

    test('slugify', () {
      expect(slugify('Hello World!', [], {}), equals('hello-world'));
      expect(slugify('Hello World!', ['default'], {}), equals('hello-world'));
      expect(slugify('Hello World!', ['ascii'], {}), equals('hello-world'));
      expect(slugify('Hello World!', ['pretty'], {}), equals('hello-world!'));
      expect(slugify('Hello  World!', ['raw'], {}), equals('hello-world!'));
      expect(slugify('Hello World!', ['none'], {}), equals('Hello World!'));
      expect(slugify('Héllö Wörld!', ['latin'], {}), equals('hello-world'));
      expect(slugify('Hello World!', ['default', true], {}),
          equals('Hello-World'));
      expect(slugify('Hello, World!', [], {}), equals('hello-world'));
      expect(slugify('   Hello,    World!   ', [], {}), equals('hello-world'));
      expect(slugify('Hello_World', ['pretty'], {}), equals('hello_world'));
      expect(slugify('Hello.World', ['pretty'], {}), equals('hello.world'));
      expect(slugify('Hello World!', ['invalid'], {}),
          equals('hello-world')); // default behavior
      expect(slugify('Hello, World!', ['raw'], {}),
          equals('hello,-world!')); // raw mode preserves punctuation
    });
  });

  group('String Filters', () {
    test('append', () {
      expect(append('Hello', ['World'], {}), equals('HelloWorld'));
      expect(append('', ['Test'], {}), equals('Test'));
      expect(() => append('Hello', [], {}), throwsArgumentError);
    });

    test('prepend', () {
      expect(prepend('World', ['Hello'], {}), equals('HelloWorld'));
      expect(prepend('', ['Test'], {}), equals('Test'));
      expect(() => prepend('World', [], {}), throwsArgumentError);
    });

    test('lstrip', () {
      expect(lstrip('  Hello  ', [], {}), equals('Hello  '));
      expect(lstrip('xxHelloxx', ['x'], {}), equals('Helloxx'));
      expect(lstrip('Hello', ['H'], {}), equals('ello'));
    });

    test('downcase', () {
      expect(downcase('HELLO', [], {}), equals('hello'));
      expect(downcase('HeLLo', [], {}), equals('hello'));
      expect(downcase('hello', [], {}), equals('hello'));
    });

    test('upcase', () {
      expect(upcase('hello', [], {}), equals('HELLO'));
      expect(upcase('HeLLo', [], {}), equals('HELLO'));
      expect(upcase('HELLO', [], {}), equals('HELLO'));
    });

    test('remove', () {
      expect(remove('Hello World', ['o'], {}), equals('Hell Wrld'));
      expect(remove('Hello World', ['l'], {}), equals('Heo Word'));
      expect(() => remove('Hello', [], {}), throwsArgumentError);
    });

    test('removeFirst', () {
      expect(removeFirst('Hello Hello', ['Hello'], {}), equals(' Hello'));
      expect(removeFirst('Hello World', ['o'], {}), equals('Hell World'));
      expect(() => removeFirst('Hello', [], {}), throwsArgumentError);
    });

    test('removeLast', () {
      expect(removeLast('Hello Hello', ['Hello'], {}), equals('Hello '));
      expect(removeLast('Hello World', ['o'], {}), equals('Hello Wrld'));
      expect(() => removeLast('Hello', [], {}), throwsArgumentError);
    });

    test('rstrip', () {
      expect(rstrip('  Hello  ', [], {}), equals('  Hello'));
      expect(rstrip('xxHelloxx', ['x'], {}), equals('xxHello'));
      expect(rstrip('Hello', ['o'], {}), equals('Hell'));
    });

    test('split', () {
      expect(split('Hello World', [' '], {}), equals(['Hello', 'World']));
      expect(split('a,b,c,,', [','], {}), equals(['a', 'b', 'c']));
      expect(() => split('Hello', [], {}), throwsArgumentError);
    });

    test('strip', () {
      expect(strip('  Hello  ', [], {}), equals('Hello'));
      expect(strip('xxHelloxx', ['x'], {}), equals('Hello'));
      expect(strip('xHellox', ['x'], {}), equals('Hello'));
    });

    test('stripNewlines', () {
      expect(stripNewlines('Hello\nWorld', [], {}), equals('HelloWorld'));
      expect(stripNewlines('Hello\r\nWorld', [], {}), equals('HelloWorld'));
      expect(stripNewlines('Hello World', [], {}), equals('Hello World'));
    });

    test('capitalize', () {
      expect(capitalize('hello', [], {}), equals('Hello'));
      expect(capitalize('HELLO', [], {}), equals('Hello'));
      expect(capitalize('hELLO', [], {}), equals('Hello'));
    });

    test('replace', () {
      expect(replace('Hello World', ['o', 'a'], {}), equals('Hella Warld'));
      expect(replace('Hello Hello', ['Hello', 'Hi'], {}), equals('Hi Hi'));
      expect(() => replace('Hello', ['o'], {}), throwsArgumentError);
    });

    test('replaceFirst', () {
      expect(
          replaceFirst('Hello Hello', ['Hello', 'Hi'], {}), equals('Hi Hello'));
      expect(
          replaceFirst('Hello World', ['o', 'a'], {}), equals('Hella World'));
      expect(() => replaceFirst('Hello', ['o'], {}), throwsArgumentError);
    });

    test('replaceLast', () {
      expect(
          replaceLast('Hello Hello', ['Hello', 'Hi'], {}), equals('Hello Hi'));
      expect(replaceLast('Hello World', ['o', 'a'], {}), equals('Hello Warld'));
      expect(() => replaceLast('Hello', ['o'], {}), throwsArgumentError);
    });

    test('truncate', () {
      expect(truncate('Hello World', [5], {}), equals('He...'));
      expect(truncate('Hello', [10], {}), equals('Hello'));
      expect(truncate('Hello World', [8, '...'], {}), equals('Hello...'));
    });

    test('truncatewords', () {
      expect(truncatewords('Hello World Foo Bar', [2], {}),
          equals('Hello World...'));
      expect(truncatewords('Hello', [2], {}), equals('Hello'));
      expect(truncatewords('Hello World Foo Bar', [2, '---'], {}),
          equals('Hello World---'));
    });

    test('normalizeWhitespace', () {
      expect(
          normalizeWhitespace('Hello   World', [], {}), equals('Hello World'));
      expect(normalizeWhitespace('   Hello   World   ', [], {}),
          equals(' Hello World '));
      expect(
          normalizeWhitespace('Hello\nWorld', [], {}), equals('Hello World'));
    });

    test('numberOfWords', () {
      expect(numberOfWords('Hello World', [], {}), equals(2));
      expect(numberOfWords('你好世界', ['cjk'], {}), equals(4));
      expect(numberOfWords('Hello 世界', ['auto'], {}), equals(3));
      expect(numberOfWords('', [], {}), equals(0));
    });

    test('arrayToSentenceString', () {
      expect(arrayToSentenceString(['apple', 'banana', 'orange'], [], {}),
          equals('apple, banana, and orange'));
      expect(arrayToSentenceString(['apple', 'banana'], [], {}),
          equals('apple and banana'));
      expect(arrayToSentenceString(['apple'], [], {}), equals('apple'));
      expect(arrayToSentenceString([], [], {}), equals(''));
      expect(arrayToSentenceString(['apple', 'banana', 'orange'], ['or'], {}),
          equals('apple, banana, or orange'));
    });
  });

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

    test('json', () {
      expect(json({'a': 1, 'b': 2}, [], {}), equals('{"a":1,"b":2}'));
      expect(
          json({'a': 1, 'b': 2}, [2], {}), equals('{\n  "a": 1,\n  "b": 2\n}'));
      expect(json([1, 2, 3], [], {}), equals('[1,2,3]'));
      expect(json('string', [], {}), equals('"string"'));
      expect(json(42, [], {}), equals('42'));
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

    test('toInteger', () {
      expect(toInteger('42', [], {}), equals(42));
      expect(toInteger(42.5, [], {}), equals(43)); // Rounds to nearest integer
      expect(toInteger('-10', [], {}), equals(-10));
      expect(() => toInteger('not a number', [], {}), throwsFormatException);
    });

    test('raw', () {
      expect(raw('string', [], {}), equals('string'));
      expect(raw(42, [], {}), equals(42));
      expect(raw({'a': 1}, [], {}), equals({'a': 1}));
      expect(raw([1, 2, 3], [], {}), equals([1, 2, 3]));
    });
  });

  group('Math Filters', () {
    test('abs', () {
      expect(abs(-5, [], {}), equals(5));
      expect(abs(5, [], {}), equals(5));
      expect(abs(0, [], {}), equals(0));
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
    });

    test('minus', () {
      expect(minus(10, [3], {}), equals(7));
      expect(minus(3, [10], {}), equals(-7));
      expect(() => minus(10, [], {}), throwsArgumentError);
    });

    test('modulo', () {
      expect(modulo(10, [3], {}), equals(1));
      expect(modulo(-10, [3], {}), equals(2)); // Changed from -1 to 2
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
        expect(
            dividedBy(10, [null], {}), equals(10)); // 10 / 1 (null becomes 1)
        expect(dividedBy(null, [null], {}), equals(0)); // 0 / 1
        expect(
            dividedBy(10, [0], {}), equals(0)); // division by zero protection
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
        expect(
            modulo(10, [null], {}), equals(0)); // 10 % 1 = 0 (null becomes 1)
        expect(modulo(null, [null], {}), equals(0));
        expect(modulo(10, [0], {}), equals(0)); // modulo by zero protection
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

  group('HTML Filters', () {
    test('escape should escape \' and &', () {
      expect(
        html.escape("Have you read 'James & the Giant Peach'?", [], {}),
        equals("Have you read &#39;James &amp; the Giant Peach&#39;?"),
      );
    });

    test('escape should escape normal string', () {
      expect(
        html.escape("Tetsuro Takara", [], {}),
        equals("Tetsuro Takara"),
      );
    });

    test('escape should escape undefined', () {
      expect(
        html.escape(null, [], {}),
        equals(""),
      );
    });

    test('escape_once should do escape', () {
      expect(
        html.escapeOnce("1 < 2 & 3", [], {}),
        equals("1 &lt; 2 &amp; 3"),
      );
    });

    test('escape_once should not escape twice', () {
      expect(
        html.escapeOnce("1 &lt; 2 &amp; 3", [], {}),
        equals("1 &lt; 2 &amp; 3"),
      );
    });

    test('escape_once should escape nil value to empty string', () {
      expect(
        html.escapeOnce(null, [], {}),
        equals(""),
      );
    });

    test('xml_escape should escape \' and &', () {
      expect(
        html.xmlEscape("Have you read 'James & the Giant Peach'?", [], {}),
        equals("Have you read &#39;James &amp; the Giant Peach&#39;?"),
      );
    });

    test('newline_to_br should support string_with_newlines', () {
      final src = "\nHello\nthere\r\n";
      final dst = "<br />\nHello<br />\nthere<br />\n";
      expect(
        html.newlineToBr(src, [], {}),
        equals(dst),
      );
    });

    test('strip_html should strip all tags', () {
      final input =
          'Have <em>you</em> read <cite><a href="https://en.wikipedia.org/wiki/Ulysses_(novel)">Ulysses</a></cite>?';
      expect(
        html.stripHtml(input, [], {}),
        equals("Have you read Ulysses?"),
      );
    });

    test('strip_html should strip all comment tags', () {
      expect(
        html.stripHtml("<!--Have you read-->Ulysses?", [], {}),
        equals("Ulysses?"),
      );
    });

    test('strip_html should strip multiline comments', () {
      final input = '<!--foo\r\nbar \ncoo\t  \r\n  -->';
      expect(
        html.stripHtml(input, [], {}),
        equals(""),
      );
    });

    test('strip_html should strip all style tags and their contents', () {
      final input =
          '<style>cite { font-style: italic; }</style><cite>Ulysses<cite>?';
      expect(
        html.stripHtml(input, [], {}),
        equals("Ulysses?"),
      );
    });

    test('strip_html should strip multiline styles', () {
      final input = '<style> \n.header {\r\n  color: black;\r\n}\n</style>';
      expect(
        html.stripHtml(input, [], {}),
        equals(""),
      );
    });

    test('strip_html should strip all scripts tags and their contents', () {
      final input =
          '<script async>console.log(\'hello world\')</script><cite>Ulysses<cite>?';
      expect(
        html.stripHtml(input, [], {}),
        equals("Ulysses?"),
      );
    });

    test('strip_html should strip multiline scripts', () {
      final input = '<script> \nfoo\r\nbar\n</script>';
      expect(
        html.stripHtml(input, [], {}),
        equals(""),
      );
    });

    test('strip_html should not strip non-matched <script>', () {
      final input = '<script></script>text<script></script>';
      expect(
        html.stripHtml(input, [], {}),
        equals("text"),
      );
    });

    test('strip_html should strip until empty', () {
      final input = '<br/><br />< p ></p></ p >';
      expect(
        html.stripHtml(input, [], {}),
        equals(""),
      );
    });
  });

  group('Date Filters', () {
    test('date filter', () {
      expect(date('2023-05-15', ['yyyy-MM-dd'], {}), equals('2023-05-15'));
      expect(date('2023-05-15', ['MMMM d, yyyy'], {}), equals('May 15, 2023'));
      expect(date('now', ['yyyy-MM-dd'], {}),
          equals(DateFormat('yyyy-MM-dd').format(tz.TZDateTime.now(tz.local))));
    });

    test('date_to_xmlschema filter', () {
      expect(dateToXmlschema('2023-05-15', [], {}),
          equals('2023-05-15T00:00:00.000-04:00'));
    });

    test('date_to_rfc822 filter', () {
      expect(dateToRfc822('2023-05-15', [], {}),
          equals('Mon, 15 May 2023 00:00:00 -0400'));
    });

    test('date_to_string filter', () {
      expect(dateToString('2023-05-15', [], {}), equals('15 May 2023'));
      expect(
          dateToString('2023-05-15', ['ordinal'], {}), equals('15th May 2023'));
      expect(dateToString('2023-05-15', ['ordinal', 'US'], {}),
          equals('May 15th, 2023'));
    });

    test('date_to_long_string filter', () {
      expect(dateToLongString('2023-05-15', [], {}), equals('15 May 2023'));
      expect(dateToLongString('2023-05-15', ['ordinal'], {}),
          equals('15th May 2023'));
      expect(dateToLongString('2023-05-15', ['ordinal', 'US'], {}),
          equals('May 15th, 2023'));
    });
  });

  group('Missing Filter Tests', () {
    test('jsonify (alias for json)', () {
      final map = {'name': 'John', 'age': 30};
      final result = json(map, [], {});
      expect(result, equals('{"name":"John","age":30}'));

      // Test with indentation
      final indentedResult = json(map, [2], {});
      expect(indentedResult, contains('{\n  "name"'));
    });

    test('lower (alias for downcase)', () {
      expect(lower('HELLO WORLD', [], {}), equals('hello world'));
      expect(lower('MiXeD cAsE', [], {}), equals('mixed case'));
      expect(lower('', [], {}), equals(''));
      expect(lower('already lowercase', [], {}), equals('already lowercase'));
    });

    test('upper (alias for upcase)', () {
      expect(upper('hello world', [], {}), equals('HELLO WORLD'));
      expect(upper('MiXeD cAsE', [], {}), equals('MIXED CASE'));
      expect(upper('', [], {}), equals(''));
      expect(upper('ALREADY UPPERCASE', [], {}), equals('ALREADY UPPERCASE'));
    });

    test('unescape', () {
      expect(html.unescape('&lt;p&gt;Hello &amp; welcome&lt;/p&gt;', [], {}),
          equals('<p>Hello & welcome</p>'));
      expect(html.unescape('&amp;quot;Hello&amp;quot;', [], {}),
          equals('&quot;Hello&quot;')); // Only unescapes known entities
      expect(html.unescape('&#39;Hello&#39;', [], {}), equals("'Hello'"));
      expect(html.unescape('No entities here', [], {}),
          equals('No entities here'));
      expect(html.unescape('', [], {}), equals(''));
    });
  });
}
