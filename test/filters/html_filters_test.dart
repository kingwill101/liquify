import 'package:liquify/src/filters/html.dart' as html;
import 'package:test/test.dart';

void main() {
  group('HTML Filters', () {
    test('escape should escape single quote and ampersand', () {
      expect(
        html.escape("Have you read 'James & the Giant Peach'?", [], {}),
        equals("Have you read &#39;James &amp; the Giant Peach&#39;?"),
      );
    });

    test('escape should pass through normal string', () {
      expect(
        html.escape('Tetsuro Takara', [], {}),
        equals('Tetsuro Takara'),
      );
    });

    test('escape should treat null as empty', () {
      expect(
        html.escape(null, [], {}),
        equals(''),
      );
    });

    test('escape_once should escape once', () {
      expect(
        html.escapeOnce('1 < 2 & 3', [], {}),
        equals('1 &lt; 2 &amp; 3'),
      );
    });

    test('escape_once should not double escape', () {
      expect(
        html.escapeOnce('1 &lt; 2 &amp; 3', [], {}),
        equals('1 &lt; 2 &amp; 3'),
      );
    });

    test('escape_once treats null as empty string', () {
      expect(
        html.escapeOnce(null, [], {}),
        equals(''),
      );
    });

    test('xml_escape should escape single quote and ampersand', () {
      expect(
        html.xmlEscape("Have you read 'James & the Giant Peach'?", [], {}),
        equals("Have you read &#39;James &amp; the Giant Peach&#39;?"),
      );
    });

    test('newline_to_br converts newlines', () {
      const src = '\nHello\nthere\r\n';
      const dst = '<br />\nHello<br />\nthere<br />\n';
      expect(
        html.newlineToBr(src, [], {}),
        equals(dst),
      );
    });

    test('strip_html removes tags', () {
      final input =
          'Have <em>you</em> read <cite><a href="https://en.wikipedia.org/wiki/Ulysses_(novel)">Ulysses</a></cite>?';
      expect(
        html.stripHtml(input, [], {}),
        equals('Have you read Ulysses?'),
      );
    });

    test('strip_html removes comment tags', () {
      expect(
        html.stripHtml('<!--Have you read-->Ulysses?', [], {}),
        equals('Ulysses?'),
      );
    });

    test('strip_html removes multiline comments', () {
      const input = '<!--foo\r\nbar \ncoo\t  \r\n  -->';
      expect(
        html.stripHtml(input, [], {}),
        equals(''),
      );
    });

    test('strip_html removes style tags', () {
      const input =
          '<style>cite { font-style: italic; }</style><cite>Ulysses<cite>?';
      expect(
        html.stripHtml(input, [], {}),
        equals('Ulysses?'),
      );
    });

    test('strip_html removes multiline styles', () {
      const input = '<style> \n.header {\r\n  color: black;\r\n}\n</style>';
      expect(
        html.stripHtml(input, [], {}),
        equals(''),
      );
    });

    test('strip_html removes script tags', () {
      const input =
          "<script async>console.log('hello world')</script><cite>Ulysses<cite>?";
      expect(
        html.stripHtml(input, [], {}),
        equals('Ulysses?'),
      );
    });

    test('strip_html removes multiline scripts', () {
      const input = '<script> \nfoo\r\nbar\n</script>';
      expect(
        html.stripHtml(input, [], {}),
        equals(''),
      );
    });

    test('strip_html keeps unmatched script tags content', () {
      const input = '<script></script>text<script></script>';
      expect(
        html.stripHtml(input, [], {}),
        equals('text'),
      );
    });

    test('strip_html removes until empty', () {
      const input = '<br/><br />< p ></p></ p >';
      expect(
        html.stripHtml(input, [], {}),
        equals(''),
      );
    });

    test('unescape restores entities', () {
      expect(
          html.unescape('&lt;p&gt;Hello &amp; welcome&lt;/p&gt;', [], {}),
          equals('<p>Hello & welcome</p>'));
      expect(
          html.unescape('&amp;quot;Hello&amp;quot;', [], {}),
          equals('&quot;Hello&quot;'));
      expect(
          html.unescape('&#39;Hello&#39;', [], {}), equals("'Hello'"));
      expect(html.unescape('No entities here', [], {}),
          equals('No entities here'));
      expect(html.unescape('', [], {}), equals(''));
    });
  });
}
