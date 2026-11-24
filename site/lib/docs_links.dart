import 'package:jaspr_content/jaspr_content.dart';

const playgroundRoot = '/liquify/';
const docsRoot = '${playgroundRoot}docs/';

String docsPath(String sourcePath) {
  final filename = sourcePath.split('/').last;
  if (filename == 'README.md' || filename == 'index.md') {
    return '$docsRoot${sourcePath.substring(0, sourcePath.length - filename.length)}';
  }
  if (filename.endsWith('.md')) {
    return '$docsRoot${sourcePath.substring(0, sourcePath.length - 3)}/';
  }
  return '$docsRoot$sourcePath';
}

class DocsLinks implements PageExtension {
  @override
  Future<List<Node>> apply(Page page, List<Node> nodes) async {
    final title = nodes
        .whereType<ElementNode>()
        .where((node) => node.tag == 'h1')
        .firstOrNull
        ?.innerText;
    if (title != null) {
      page.apply(
        data: {
          'page': {'title': title, 'titleBase': 'Liquify'},
        },
      );
    }
    return nodes.map((node) => _rewrite(node, page)).toList();
  }

  Node _rewrite(Node node, Page page) {
    if (node is! ElementNode) return node;
    final children = node.children
        ?.map((child) => _rewrite(child, page))
        .toList();
    final href = node.attributes['href'];
    if (node.tag != 'a' || href == null) {
      return ElementNode(node.tag, node.attributes, children);
    }
    return ElementNode(node.tag, {
      ...node.attributes,
      'href': _resolve(page.path, href),
    }, children);
  }

  String _resolve(String sourcePath, String href) {
    final uri = Uri.tryParse(href);
    if (uri == null || uri.hasScheme || uri.hasAuthority) return href;
    if (href == '/') return docsRoot;
    if (href == '../CONTRIBUTING.md' && sourcePath == 'index.md') {
      return 'https://github.com/kingwill101/liquify#contributing';
    }
    if (uri.path.startsWith('/')) return href;
    final path = Uri(path: '/$sourcePath').resolveUri(uri).path.substring(1);
    return uri.replace(path: docsPath(path)).toString();
  }
}
