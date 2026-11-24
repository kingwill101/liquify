import 'package:highlight/highlight.dart' as hl;
import 'package:highlight/languages/dart.dart' as language;
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

class DartCodeBlock extends CustomComponent {
  DartCodeBlock() : super.base();

  final _highlighter = hl.Highlight()..registerLanguage('dart', language.dart);

  @override
  Component? create(Node node, NodesBuilder builder) {
    if (node case ElementNode(
      tag: 'pre',
      children: [
        ElementNode(
          tag: 'code',
          attributes: {'class': 'language-dart'},
          :final innerText,
        ),
      ],
    )) {
      final tokens = _highlighter.parse(innerText, language: 'dart').nodes;
      return figure(classes: 'dart-snippet', [
        figcaption([const Component.text('Dart')]),
        pre([
          code([
            if (tokens == null)
              Component.text(innerText)
            else
              ...tokens.map(_token),
          ]),
        ]),
      ]);
    }
    return null;
  }

  Component _token(hl.Node node) {
    final children = [
      if (node.value case final text?) Component.text(text),
      ...?node.children?.map(_token),
    ];
    return node.className == null
        ? Component.fragment(children)
        : span(classes: 'dart-${node.className}', children);
  }
}
