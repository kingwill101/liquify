import 'package:liquify/src/filters/html.dart' as html;

import 'package:test/test.dart';

void main() {
  group('HTML Filters', () {
    test('escape should escape " and < >', () {
      expect(
        html.escape('"Hello" <world>', [], {}),
        equals('&#34;Hello&#34; &lt;world&gt;'),
      );
    });

    test('escape should escape \' and &', () {
      expect(
        html.escape("Have you read 'James & the Giant Peach'?", [], {}),
        equals("Have you read &#39;James &amp; the Giant Peach&#39;?"),
      );
    });

    test('escape should escape normal string', () {
      expect(html.escape('Tetsuro Takara', [], {}), equals('Tetsuro Takara'));
    });

    test('escape should escape undefined', () {
      expect(html.escape(null, [], {}), equals(''));
    });

    test('escape_once should do escape', () {
      expect(html.escapeOnce('1 < 2 & 3', [], {}), equals('1 &lt; 2 &amp; 3'));
    });

    test('escape_once should not escape twice', () {
      expect(
        html.escapeOnce('1 &lt; 2 &amp; 3', [], {}),
        equals('1 &lt; 2 &amp; 3'),
      );
    });

    test('escape_once should escape nil value to empty string', () {
      expect(html.escapeOnce(null, [], {}), equals(''));
    });

    test('xml_escape should escape \' and &', () {
      expect(
        html.xmlEscape("Have you read 'James & the Giant Peach'?", [], {}),
        equals("Have you read &#39;James &amp; the Giant Peach&#39;?"),
      );
    });

    test('unescape should restore known entities', () {
      expect(
        html.unescape('&lt;p&gt;Hello &amp; welcome&lt;/p&gt;', [], {}),
        equals('<p>Hello & welcome</p>'),
      );
      expect(
        html.unescape('&amp;quot;Hello&amp;quot;', [], {}),
        equals('&quot;Hello&quot;'),
      );
      expect(html.unescape('&#39;Hello&#39;', [], {}), equals("'Hello'"));
      expect(
        html.unescape('No entities here', [], {}),
        equals('No entities here'),
      );
      expect(html.unescape('', [], {}), equals(''));
    });

    test('newline_to_br should support string_with_newlines', () {
      final src = "\nHello\nthere\r\n";
      final dst = "<br />\nHello<br />\nthere<br />\n";
      expect(html.newlineToBr(src, [], {}), equals(dst));
    });

    test('newline_to_br should handle null', () {
      expect(html.newlineToBr(null, [], {}), equals(''));
    });

    test('strip_html should strip all tags', () {
      final input =
          'Have <em>you</em> read <cite><a href="https://en.wikipedia.org/wiki/Ulysses_(novel)">Ulysses</a></cite>?';
      expect(html.stripHtml(input, [], {}), equals('Have you read Ulysses?'));
    });

    test('strip_html should strip all comment tags', () {
      expect(
        html.stripHtml('<!--Have you read-->Ulysses?', [], {}),
        equals('Ulysses?'),
      );
    });

    test('strip_html should strip multiline comments', () {
      final input = '<!--foo\r\nbar \ncoo\t  \r\n  -->';
      expect(html.stripHtml(input, [], {}), equals(''));
    });

    test('strip_html should strip all style tags and their contents', () {
      final input =
          '<style>cite { font-style: italic; }</style><cite>Ulysses<cite>?';
      expect(html.stripHtml(input, [], {}), equals('Ulysses?'));
    });

    test('strip_html should strip multiline styles', () {
      final input = '<style> \n.header {\r\n  color: black;\r\n}\n</style>';
      expect(html.stripHtml(input, [], {}), equals(''));
    });

    test('strip_html should strip all scripts tags and their contents', () {
      final input =
          '<script async>console.log(\'hello world\')</script><cite>Ulysses<cite>?';
      expect(html.stripHtml(input, [], {}), equals('Ulysses?'));
    });

    test('strip_html should strip multiline scripts', () {
      final input = '<script> \nfoo\r\nbar\n</script>';
      expect(html.stripHtml(input, [], {}), equals(''));
    });

    test('strip_html should not strip non-matched <script>', () {
      final input = '<script></script>text<script></script>';
      expect(html.stripHtml(input, [], {}), equals('text'));
    });

    test('strip_html should strip until empty', () {
      final input = '<br/><br />< p ></p></ p >';
      expect(html.stripHtml(input, [], {}), equals(''));
    });

    test('strip_newlines should remove line breaks', () {
      expect(html.stripNewlines('Hello\nWorld', [], {}), equals('HelloWorld'));
      expect(
        html.stripNewlines('Hello\r\nWorld', [], {}),
        equals('HelloWorld'),
      );
      expect(html.stripNewlines(null, [], {}), equals(''));
    });
  });
}
