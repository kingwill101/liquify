import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

enum CodeLanguage { liquid, json, html }

final _liquid = RegExp(r'(\{\{-?|\{%-?)([\s\S]*?)(-?\}\}|-?%\}|$)');
final _html = RegExp(r'<!--[\s\S]*?(?:-->|$)|</?[\w!][^<>]*>|&[\w#]+;');
final _htmlTag = RegExp(
  r'''("[^"]*"|'[^']*'|</?[\w!:-]+|[\w:-]+(?=\s*=)|/?>)''',
);
final _propertySeparator = RegExp(r'\s*:');
final _json = RegExp(
  r'''("(?:\\.|[^"\\])*(?:"|$))|(\b(?:true|false|null)\b)|(-?\d+(?:\.\d+)?(?:[Ee][+-]?\d+)?)''',
);
final _expression = RegExp(
  r'''("(?:\\.|[^"\\])*(?:"|$)|'(?:\\.|[^'\\])*(?:'|$))|(\|\s*[\w-]+)|(\b(?:nil|null|blank|empty|true|false|and|or|contains)\b)|(-?\d+(?:\.\d+)?)''',
);

List<Component> highlightCode(String source, CodeLanguage language) =>
    switch (language) {
      CodeLanguage.html => _highlightHtml(source),
      CodeLanguage.json => _tokenize(source, _json, (match) {
        final kind = match[1] == null
            ? (match[2] == null ? 'number' : 'keyword')
            : (_propertySeparator.matchAsPrefix(source, match.end) != null
                  ? 'property'
                  : 'string');
        return [_token(kind, match[0]!)];
      }),
      CodeLanguage.liquid => _tokenize(source, _liquid, (match) {
        final opening = match[1]!;
        final expression = match[2]!;
        final closing = match[3]!;
        final tag = opening.startsWith('{%')
            ? RegExp(r'^\s*([\w-]+)').firstMatch(expression)
            : null;
        return [
          _token('delimiter', opening),
          if (tag != null) _token('keyword', tag[0]!),
          ..._tokenize(expression.substring(tag?.end ?? 0), _expression, (m) {
            final kind = m[1] != null
                ? 'string'
                : m[2] != null
                ? 'filter'
                : m[3] != null
                ? 'keyword'
                : 'number';
            return [_token(kind, m[0]!)];
          }),
          _token('delimiter', closing),
        ];
      }, plain: _highlightHtml),
    };

List<Component> _highlightHtml(String source) => _tokenize(source, _html, (m) {
  final text = m[0]!;
  if (text.startsWith('<!--')) return [_token('comment', text)];
  if (text.startsWith('&')) return [_token('delimiter', text)];
  return _tokenize(text, _htmlTag, (tag) {
    final text = tag[0]!;
    final kind = switch (text[0]) {
      '"' || "'" => 'string',
      '<' || '>' || '/' => 'tag',
      _ => 'property',
    };
    return [_token(kind, text)];
  });
});

List<Component> _tokenize(
  String source,
  RegExp pattern,
  List<Component> Function(RegExpMatch) color, {
  List<Component> Function(String) plain = _plain,
}) {
  final components = <Component>[];
  var offset = 0;
  for (final match in pattern.allMatches(source)) {
    if (offset < match.start) {
      components.addAll(plain(source.substring(offset, match.start)));
    }
    components.addAll(color(match));
    offset = match.end;
  }
  if (offset < source.length)
    components.addAll(plain(source.substring(offset)));
  return components;
}

List<Component> _plain(String source) => [Component.text(source)];

Component _token(String kind, String value) =>
    span(classes: 'syntax-$kind', [Component.text(value)]);
