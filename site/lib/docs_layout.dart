import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

import 'docs_links.dart';
import 'live_examples.dart';

class LiquifyDocsLayout extends PageLayoutBase {
  const LiquifyDocsLayout(this.pages);

  final List<String> pages;

  @override
  String get name => 'liquify-docs';

  @override
  Iterable<Component> buildHead(Page page) sync* {
    yield* super.buildHead(page);
    yield script(src: '${playgroundRoot}theme.js');
    yield link(rel: 'stylesheet', href: '${playgroundRoot}theme.css');
    yield link(rel: 'stylesheet', href: '${docsRoot}styles.css');
    yield script(src: liveExamplesScript, defer: true);
  }

  @override
  Component buildBody(Page page, Component child) {
    return div(classes: 'docs-shell', [
      a(classes: 'skip-link', href: '${docsPath(page.path)}#main-content', [
        const Component.text('Skip to content'),
      ]),
      header(classes: 'site-header', [
        a(classes: 'site-brand', href: docsRoot, [
          img(
            classes: 'brand-mark',
            src:
                'https://raw.githubusercontent.com/kingwill101/liquify/master/pkgs/liquify/assets/logo.png',
            alt: '',
          ),
          const Component.text('Liquify'),
        ]),
        nav(
          classes: 'site-nav',
          attributes: {'aria-label': 'Site'},
          [
            a(
              href: docsRoot,
              attributes: {'aria-current': 'page'},
              [const Component.text('Docs')],
            ),
            a(href: playgroundRoot, [const Component.text('Playground')]),
            a(href: 'https://github.com/kingwill101/liquify', [
              const Component.text('GitHub'),
            ]),
            button(
              [const Component.text('Dark')],
              classes: 'theme-toggle',
              type: ButtonType.button,
              attributes: {'data-theme-toggle': '', 'aria-label': 'Dark mode'},
            ),
          ],
        ),
      ]),
      div(classes: 'docs-grid', [
        aside(classes: 'docs-sidebar', [
          details(classes: 'mobile-nav', [
            summary([const Component.text('Browse documentation')]),
            _navigation(page),
          ]),
          div(classes: 'desktop-nav', [_navigation(page)]),
        ]),
        main_(id: 'main-content', [
          if (page.path.contains('/'))
            nav(
              classes: 'breadcrumb',
              attributes: {'aria-label': 'Breadcrumb'},
              [
                a(href: docsRoot, [const Component.text('Docs')]),
                span(
                  attributes: {'aria-hidden': 'true'},
                  [const Component.text('/')],
                ),
                a(href: docsPath('${page.path.split('/').first}/index.md'), [
                  Component.text(_sectionLabel(page.path.split('/').first)),
                ]),
              ],
            ),
          article(classes: page.path == 'index.md' ? 'docs-overview' : null, [
            child,
          ]),
        ]),
      ]),
    ]);
  }

  Component _navigation(Page page) {
    return nav(
      attributes: {'aria-label': 'Documentation'},
      [
        _pageLink('index.md', page, 'Overview'),
        for (final (prefix, label) in [
          ('examples/', 'Examples'),
          ('tags/', 'Tags'),
          ('filters/', 'Filters'),
        ]) ...[
          h2([Component.text(label)]),
          _pageLink('${prefix}index.md', page, 'Overview'),
          for (final path in pages.where(
            (path) => path.startsWith(prefix) && !path.endsWith('/index.md'),
          ))
            _pageLink(path, page, _label(path)),
        ],
        h2([const Component.text('Advanced')]),
        _pageLink(
          'environment-scoped-registry.md',
          page,
          'Environment-scoped registry',
        ),
      ],
    );
  }

  Component _pageLink(String path, Page page, String label) {
    return a(
      href: docsPath(path),
      attributes: {if (page.path == path) 'aria-current': 'page'},
      [Component.text(label)],
    );
  }

  String _sectionLabel(String section) =>
      '${section[0].toUpperCase()}${section.substring(1)}';

  String _label(String path) {
    final filename = path.split('/').last;
    final text = filename
        .substring(0, filename.length - 3)
        .replaceAll('-', ' ');
    return switch (text) {
      'html' => 'HTML',
      'url' => 'URL',
      _ => _sectionLabel(text),
    };
  }
}
