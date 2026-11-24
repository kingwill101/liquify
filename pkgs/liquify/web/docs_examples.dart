import 'dart:async';
import 'dart:convert';

import 'package:jaspr/client.dart';
import 'package:jaspr/dom.dart';
import 'package:liquify/liquify.dart';
import 'package:web/web.dart' as web;

import 'code_editor.dart';
import 'share_link.dart';
import 'syntax.dart';

const _entry = 'index.liquid';

void main() {
  final examples = web.document.querySelectorAll('.docs-example');
  for (var i = 0; i < examples.length; i++) {
    final element = examples.item(i)! as web.HTMLElement;
    final source = element.getAttribute('data-liquid')!;
    final context = element.getAttribute('data-context')!;
    final files = Map<String, String>.from(
      jsonDecode(element.getAttribute('data-files')!) as Map,
    );
    element.id = 'liquid-example-$i';
    element.textContent = '';
    runApp(
      LiveExample({...files, _entry: source}, context),
      attachTo: '#${element.id}',
    );
  }
}

class LiveExample extends StatefulComponent {
  const LiveExample(this.files, this.context);

  final Map<String, String> files;
  final String context;

  @override
  State<LiveExample> createState() => _LiveExampleState();
}

class _LiveExampleState extends State<LiveExample> {
  late Map<String, String> _files = Map.of(component.files);
  late String _context = component.context;
  String? _activeFile = _entry;
  var _revision = 0;
  var _generation = 0;
  var _output = '';
  var _error = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    unawaited(_render());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _render() async {
    final generation = ++_generation;
    try {
      final decoded = jsonDecode(_context);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Data must be a JSON object.');
      }
      final output = await Template.fromFile(
        _entry,
        MapRoot(Map.of(_files), throwOnMissing: true),
        data: decoded,
        environmentSetup: (environment) => environment.maxRangeSize = 10000,
      ).renderAsync();
      if (!mounted || generation != _generation) return;
      setState(() {
        _output = output;
        _error = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _output = error.toString();
        _error = true;
      });
    }
  }

  String? get _playgroundUrl =>
      encodeSharedWorkspace(Uri.base.resolve('/liquify/'), (
        files: _files,
        entry: _entry,
        active: _activeFile ?? _entry,
        context: _context,
        example: 'basic',
      ));

  void _edit(String text) {
    setState(() {
      if (_activeFile case final path?) {
        _files[path] = text;
      } else {
        _context = text;
      }
    });
    _generation++;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 250), _render);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _files = Map.of(component.files);
      _context = component.context;
      _revision++;
    });
    unawaited(_render());
  }

  @override
  Component build(BuildContext context) {
    final playground = _playgroundUrl;
    final activeFile = _activeFile;
    return div(classes: 'live-example', [
      div(classes: 'example-edit', [
        div(classes: 'example-bar', [
          for (final (label, file) in [
            ('Liquid', _entry),
            ('JSON data', null),
            for (final path in _files.keys)
              if (path != _entry) (path, path),
          ])
            button(
              [Component.text(label)],
              type: ButtonType.button,
              attributes: {'aria-pressed': '${activeFile == file}'},
              onClick: () => setState(() => _activeFile = file),
            ),
          button(
            [const Component.text('Reset')],
            type: ButtonType.button,
            classes: 'example-reset',
            onClick: _reset,
          ),
        ]),
        CodeEditor(
          key: ValueKey('$_revision:$activeFile'),
          label: switch (activeFile) {
            null => 'Example JSON data',
            _entry => 'Example Liquid code',
            final path => 'Example template $path',
          },
          value: activeFile == null ? _context : _files[activeFile]!,
          language: activeFile == null
              ? CodeLanguage.json
              : CodeLanguage.liquid,
          onInput: _edit,
        ),
      ]),
      div(classes: 'example-output', [
        div(classes: 'example-bar', [
          const Component.text('Output'),
          if (playground != null)
            a(href: playground, [const Component.text('Open in playground')]),
        ]),
        pre(
          attributes: {'aria-live': 'polite'},
          [
            if (_error)
              Component.text(_output)
            else
              ...highlightCode(_output, CodeLanguage.html),
          ],
        ),
      ]),
    ]);
  }
}
