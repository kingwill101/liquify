import 'package:liquify/src/filters/string.dart';

import 'package:test/test.dart';

void main() {
  group('String Filters', () {
    test('append', () {
      expect(append('Hello', ['World'], {}), equals('HelloWorld'));
      expect(append('', ['Test'], {}), equals('Test'));
      expect(append(42, ['!'], {}), equals('42!'));
      expect(() => append('Hello', [], {}), throwsArgumentError);
    });

    test('prepend', () {
      expect(prepend('World', ['Hello'], {}), equals('HelloWorld'));
      expect(prepend('', ['Test'], {}), equals('Test'));
      expect(prepend(42, ['Value: '], {}), equals('Value: 42'));
      expect(() => prepend('World', [], {}), throwsArgumentError);
    });

    test('lstrip', () {
      expect(lstrip('  Hello  ', [], {}), equals('Hello  '));
      expect(lstrip('\t\tHello', [], {}), equals('Hello'));
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
      expect(remove('Hello World', ['z'], {}), equals('Hello World'));
      expect(() => remove('Hello', [], {}), throwsArgumentError);
    });

    test('removeFirst', () {
      expect(removeFirst('Hello Hello', ['Hello'], {}), equals(' Hello'));
      expect(removeFirst('Hello World', ['o'], {}), equals('Hell World'));
      expect(removeFirst('Hello World', ['z'], {}), equals('Hello World'));
      expect(() => removeFirst('Hello', [], {}), throwsArgumentError);
    });

    test('removeLast', () {
      expect(removeLast('Hello Hello', ['Hello'], {}), equals('Hello '));
      expect(removeLast('Hello World', ['o'], {}), equals('Hello Wrld'));
      expect(removeLast('Hello World', ['z'], {}), equals('Hello World'));
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
      expect(split('Hello', ['|'], {}), equals(['Hello']));
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
      expect(replaceFirst('Hello Hello', ['Hello', 'Hi'], {}),
          equals('Hi Hello'));
      expect(replaceFirst('Hello World', ['o', 'a'], {}),
          equals('Hella World'));
      expect(replaceFirst('Hello World', ['z', 'a'], {}),
          equals('Hello World'));
      expect(() => replaceFirst('Hello', ['o'], {}), throwsArgumentError);
    });

    test('replaceLast', () {
      expect(replaceLast('Hello Hello', ['Hello', 'Hi'], {}),
          equals('Hello Hi'));
      expect(replaceLast('Hello World', ['o', 'a'], {}), equals('Hello Warld'));
      expect(replaceLast('Hello World', ['z', 'a'], {}),
          equals('Hello World'));
      expect(() => replaceLast('Hello', ['o'], {}), throwsArgumentError);
    });

    test('truncate', () {
      expect(truncate('Hello World', [5], {}), equals('He...'));
      expect(truncate('Hello', [10], {}), equals('Hello'));
      expect(truncate('Hello World', [8, '...'], {}), equals('Hello...'));
    });

    test('truncate uses default length', () {
      final text = List.filled(60, 'a').join();
      expect(truncate(text, [], {}).length, equals(50));
    });

    test('truncatewords', () {
      expect(truncatewords('Hello World Foo Bar', [2], {}),
          equals('Hello World...'));
      expect(truncatewords('Hello', [2], {}), equals('Hello'));
      expect(truncatewords('Hello World Foo Bar', [2, '---'], {}),
          equals('Hello World---'));
    });

    test('truncatewords enforces minimum word count', () {
      expect(truncatewords('Hello World Foo Bar', [0], {}),
          equals('Hello...'));
      expect(truncatewords('Hello World Foo Bar', [-2], {}),
          equals('Hello...'));
    });

    test('normalizeWhitespace', () {
      expect(normalizeWhitespace('Hello   World', [], {}),
          equals('Hello World'));
      expect(normalizeWhitespace('   Hello   World   ', [], {}),
          equals(' Hello World '));
      expect(normalizeWhitespace('Hello\nWorld', [], {}), equals('Hello World'));
    });

    test('numberOfWords', () {
      expect(numberOfWords('Hello World', [], {}), equals(2));
      expect(numberOfWords('Hello   World\nagain', [], {}), equals(3));
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

    test('arrayToSentenceString requires a list input', () {
      expect(() => arrayToSentenceString('not a list', [], {}),
          throwsArgumentError);
    });
  });
}
