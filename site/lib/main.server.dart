import 'dart:io';

import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';

import 'dart_code_block.dart';
import 'docs_layout.dart';
import 'docs_links.dart';
import 'live_examples.dart';

void main() {
  Jaspr.initializeApp();
  final source = Directory('../pkgs/liquify/doc').absolute;
  final pages =
      source
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((file) => file.path.endsWith('.md'))
          .map((file) {
            final path = file.uri.path.substring(source.uri.path.length);
            return MemoryPage(
              path: path.endsWith('README.md')
                  ? '${path.substring(0, path.length - 'README.md'.length)}index.md'
                  : path,
              content: file.readAsStringSync(),
            );
          })
          .toList()
        ..sort((left, right) => left.path.compareTo(right.path));

  runApp(
    ContentApp.custom(
      loaders: [MemoryLoader(pages: pages)],
      configResolver: PageConfig.all(
        dataLoaders: [
          const MemoryDataLoader({
            'site': {'base': docsRoot, 'lang': 'en'},
          }),
        ],
        theme: const ContentTheme.none(),
        parsers: [MarkdownParser()],
        extensions: [DocsLinks(), LiveExamples()],
        components: [DartCodeBlock()],
        layouts: [LiquifyDocsLayout(pages.map((page) => page.path).toList())],
      ),
    ),
  );
}
