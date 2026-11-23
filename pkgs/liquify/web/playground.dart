import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:jaspr/client.dart';
import 'package:jaspr/dom.dart';
import 'package:liquify/liquify.dart';
import 'package:web/web.dart' as web;

import 'code_editor.dart';
import 'examples.dart';
import 'share_link.dart';
import 'syntax.dart';

class Playground extends StatefulComponent {
  const Playground();

  @override
  State<Playground> createState() => _PlaygroundState();
}

class _PlaygroundState extends State<Playground> {
  var _files = <String, String>{};
  var _example = 'basic';
  var _entry = '';
  var _active = '';
  var _context = '';
  var _output = '';
  var _status = '';
  var _notice = '';
  var _preview = false;
  var _autoRender = true;
  var _renderFailed = false;
  var _editorRevision = 0;
  var _renderGeneration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadExample(_example);
    _restoreLink();
    unawaited(_render());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadExample(String key) {
    final example = examples[key]!;
    _example = key;
    _files = Map.of(example.files);
    _entry = _active = example.entryFile;
    _context = example.contextJson;
    _editorRevision++;
  }

  void _selectExample(String key) {
    final url = Uri.base;
    if (hasSharedWorkspace(url)) {
      web.window.history.replaceState(
        null,
        '',
        url.removeFragment().toString(),
      );
    }
    setState(() {
      _notice = '';
      _loadExample(key);
    });
    unawaited(_render());
  }

  void _restoreLink() {
    final url = Uri.base;
    if (!hasSharedWorkspace(url)) return;
    try {
      final workspace = decodeSharedWorkspace(url);
      _files = workspace.files;
      _entry = workspace.entry;
      _active = workspace.active;
      _context = workspace.context;
      _example = examples.containsKey(workspace.example)
          ? workspace.example
          : 'basic';
    } on FormatException {
      _notice = 'Could not open the shared workspace.';
    }
  }

  Future<void> _share() async {
    final url = encodeSharedWorkspace(Uri.base, (
      files: _files,
      entry: _entry,
      active: _active,
      context: _context,
      example: _example,
    ));
    if (url == null) {
      setState(
        () => _notice = 'This workspace is too large to share as a URL.',
      );
      return;
    }
    web.window.history.replaceState(null, '', url);
    try {
      await web.window.navigator.clipboard.writeText(url).toDart;
      if (mounted) setState(() => _notice = 'Link copied.');
    } catch (_) {
      if (mounted) setState(() => _notice = 'Link saved in the address bar.');
    }
  }

  Future<void> _render() async {
    _timer?.cancel();
    final generation = ++_renderGeneration;
    final entry = _entry;
    try {
      final context = _context.trim().isEmpty
          ? <String, dynamic>{}
          : jsonDecode(_context);
      if (context is! Map<String, dynamic>) {
        throw const FormatException('Context must be a JSON object.');
      }
      final template = Template.fromFile(
        entry,
        MapRoot(Map.of(_files), throwOnMissing: true),
        environmentSetup: (environment) => environment.maxRangeSize = 10000,
        data: context,
      );
      final result = await template.renderAsync();
      if (!mounted || generation != _renderGeneration) return;
      setState(() {
        _output = result;
        _status = 'Rendered $entry';
        _renderFailed = false;
      });
    } catch (error) {
      if (!mounted || generation != _renderGeneration) return;
      setState(() {
        _output = '$error';
        _status = 'Render failed';
        _renderFailed = true;
        _preview = false;
      });
    }
  }

  void _scheduleRender() {
    _timer?.cancel();
    if (_autoRender) _timer = Timer(const Duration(milliseconds: 280), _render);
  }

  void _editPath({required bool rename}) {
    final value = web.window
        .prompt(
          rename ? 'Rename template' : 'New template path',
          rename ? _active : 'snippets/new-template.liquid',
        )
        ?.trim();
    if (value == null || value.isEmpty) return;
    final path = value.endsWith('.liquid') ? value : '$value.liquid';
    if (rename && path == _active) return;
    if (!isTemplatePath(path) || _files.containsKey(path)) {
      setState(() => _notice = 'Enter a unique template path.');
      return;
    }
    setState(() {
      _notice = '';
      _files[path] = rename ? _files.remove(_active)! : '';
      if (rename && _entry == _active) _entry = path;
      _active = path;
    });
    _scheduleRender();
  }

  void _deleteFile() {
    if (_files.length < 2 || !web.window.confirm('Delete $_active?')) return;
    setState(() {
      _files.remove(_active);
      if (_entry == _active) _entry = (_files.keys.toList()..sort()).first;
      _active = _entry;
    });
    unawaited(_render());
  }

  @override
  Component build(BuildContext context) {
    return div(classes: 'app', [
      header([
        div(classes: 'brand', [
          span(classes: 'mark', [Component.text('{%')]),
          h1([Component.text('Liquify Playground')]),
        ]),
        div(classes: 'controls', [
          select(
            [
              for (final key in examples.keys)
                option(
                  [Component.text(key.replaceAll('-', ' '))],
                  value: key,
                  selected: key == _example,
                ),
            ],
            value: _example,
            attributes: {'aria-label': 'Example'},
            onChange: (values) {
              if (values.isNotEmpty) _selectExample(values.single);
            },
          ),
          _button('Reset', () => _selectExample(_example)),
          label([
            input<bool>(
              type: InputType.checkbox,
              checked: _autoRender,
              onChange: (value) {
                setState(() => _autoRender = value);
                _scheduleRender();
              },
            ),
            Component.text('Auto-render'),
          ]),
          _button('Share', _share),
          _button('Render', _render, classes: 'primary'),
        ]),
      ]),
      if (_notice.isNotEmpty)
        p(
          classes: 'notice',
          attributes: {'role': 'status'},
          [Component.text(_notice)],
        ),
      main_(classes: 'workspace', [
        section(classes: 'panel templates', [
          _panelHeader(
            'Templates',
            '${_files.length} files',
            actions: [_button('New file', () => _editPath(rename: false))],
          ),
          div(classes: 'template-body', [
            aside([
              nav(
                attributes: {'aria-label': 'Template files'},
                [
                  for (final path in _files.keys.toList()..sort())
                    button(
                      [
                        span([Component.text(path)]),
                        if (path == _entry) small([Component.text('Entry')]),
                      ],
                      classes: path == _active ? 'file selected' : 'file',
                      onClick: () => setState(() => _active = path),
                    ),
                ],
              ),
              div(classes: 'entry', [
                Component.text('Entry template'),
                code([Component.text(_entry)]),
              ]),
            ]),
            div(classes: 'editor', [
              div(classes: 'editor-bar', [
                code([Component.text(_active)]),
                div(classes: 'actions', [
                  _button('Set as entry', () {
                    setState(() => _entry = _active);
                    unawaited(_render());
                  }, disabled: _entry == _active),
                  _button('Rename', () => _editPath(rename: true)),
                  _button('Delete', _deleteFile, disabled: _files.length < 2),
                ]),
              ]),
              CodeEditor(
                label: 'Selected Liquid template',
                value: _files[_active]!,
                key: ValueKey('$_editorRevision:$_active'),
                language: CodeLanguage.liquid,
                onInput: (text) {
                  _files[_active] = text;
                  _scheduleRender();
                },
              ),
            ]),
          ]),
        ]),
        section(classes: 'panel context', [
          _panelHeader('Context', 'JSON variables'),
          CodeEditor(
            label: 'JSON context',
            value: _context,
            key: ValueKey('context:$_editorRevision'),
            language: CodeLanguage.json,
            onInput: (text) {
              _context = text;
              _scheduleRender();
            },
          ),
        ]),
        section(classes: 'panel output', [
          _panelHeader(
            'Output',
            _status,
            actions: [
              _button(
                'Raw',
                () => setState(() => _preview = false),
                classes: _preview ? null : 'selected',
              ),
              _button(
                'Preview',
                () => setState(() => _preview = true),
                classes: _preview ? 'selected' : null,
                disabled: _renderFailed,
              ),
            ],
          ),
          if (_preview)
            iframe(
              [],
              src: 'about:blank',
              sandbox: '',
              attributes: {'srcdoc': _output, 'title': 'Rendered HTML preview'},
            )
          else
            pre(classes: _renderFailed ? 'error' : null, [
              if (_renderFailed)
                Component.text(_output)
              else
                ...highlightCode(_output, CodeLanguage.html),
            ]),
        ]),
      ]),
    ]);
  }

  Component _panelHeader(
    String title,
    String detail, {
    List<Component> actions = const [],
  }) {
    return div(classes: 'panel-header', [
      div([
        h2([Component.text(title)]),
        span([Component.text(detail)]),
      ]),
      if (actions.isNotEmpty) div(classes: 'actions', actions),
    ]);
  }

  Component _button(
    String label,
    VoidCallback onClick, {
    String? classes,
    bool disabled = false,
  }) {
    return button(
      [Component.text(label)],
      type: ButtonType.button,
      classes: classes,
      disabled: disabled,
      onClick: onClick,
    );
  }
}
