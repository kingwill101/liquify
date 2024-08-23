void main() {
  group('Array Filters', () {
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
  });

}
