import 'package:intl/intl.dart';
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
}
