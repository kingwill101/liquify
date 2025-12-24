import 'package:liquify/src/filters/url.dart';

import 'package:test/test.dart';

void main() {
  group('URL Filters', () {
    test('urlDecode', () {
      expect(urlDecode('hello+world', [], {}), equals('hello world'));
      expect(urlDecode('hello%20world', [], {}), equals('hello world'));
      expect(urlDecode(null, [], {}), equals(''));
    });

    test('urlEncode', () {
      expect(urlEncode('hello world', [], {}), equals('hello+world'));
      expect(urlEncode(null, [], {}), equals(''));
    });

    test('cgiEscape', () {
      expect(cgiEscape("It's a test!", [], {}), equals('It%27s+a+test%21'));
      expect(cgiEscape("!*'()", [], {}), equals('%21%2A%27%28%29'));
    });

    test('uriEscape', () {
      expect(uriEscape('http://example.com/path[1]/test', [], {}),
          equals('http://example.com/path[1]/test'));
      expect(uriEscape('hello world', [], {}), equals('hello%20world'));
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
      expect(slugify('   Hello,    World!   ', [], {}),
          equals('hello-world'));
      expect(slugify('Hello_World', ['pretty'], {}), equals('hello_world'));
      expect(slugify('Hello.World', ['pretty'], {}), equals('hello.world'));
      expect(slugify('Hello World!', ['invalid'], {}), equals('hello-world'));
      expect(slugify('Hello, World!', ['raw'], {}), equals('hello,-world!'));
    });

    test('slugify supports ascii and latin rules', () {
      expect(slugify('Héllö Wörld!', ['ascii'], {}), equals('hll-wrld'));
      expect(slugify('Straße', ['latin'], {}), equals('strasse'));
    });

    test('slugify preserves case for cased inputs', () {
      expect(slugify('Hello World', ['default', true], {}),
          equals('Hello-World'));
      expect(slugify('KeepCase', ['none', true], {}), equals('KeepCase'));
    });
  });
}
