import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

import 'docs_links.dart';

class LiveExamples implements PageExtension {
  @override
  Future<List<Node>> apply(Page page, List<Node> nodes) async {
    final result = <Node>[];
    for (var index = 0; index < nodes.length; index++) {
      final source = _fence(nodes[index], 'liquid-live');
      if (source == null) {
        result.add(nodes[index]);
        continue;
      }
      final data = index + 1 < nodes.length
          ? _fence(nodes[index + 1], 'json-live')
          : null;
      if (data != null) index++;
      final files = index + 1 < nodes.length
          ? _fence(nodes[index + 1], 'files-live')
          : null;
      if (files != null) index++;
      result.add(ComponentNode(_example(source, data ?? '{}', files ?? '{}')));
    }
    return result;
  }

  String? _fence(Node node, String language) {
    if (node case ElementNode(
      tag: 'pre',
      children: [ElementNode(tag: 'code', :final attributes, :final innerText)],
    ) when attributes['class'] == 'language-$language') {
      return innerText;
    }
    return null;
  }

  Component _example(String code, String data, String files) => div(
    classes: 'docs-example',
    attributes: {
      'data-liquid': code,
      'data-context': data,
      'data-files': files,
    },
    [
      pre([Component.text(code)]),
    ],
  );
}

const liveExamplesScript = '${playgroundRoot}docs_examples.dart.js';
