import 'package:jaspr/client.dart';
import 'package:jaspr/dom.dart';
import 'package:web/web.dart' as web;

import 'syntax.dart';

class CodeEditor extends StatefulComponent {
  const CodeEditor({
    required this.label,
    required this.value,
    required this.language,
    required this.onInput,
    super.key,
  });

  final String label;
  final String value;
  final CodeLanguage language;
  final ValueChanged<String> onInput;

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  late String _text = component.value;

  @override
  Component build(BuildContext context) {
    return div(classes: 'code-editor', [
      pre(
        classes: 'code-mirror',
        attributes: {'aria-hidden': 'true'},
        [
          ...highlightCode(_text, component.language),
          if (_text.endsWith('\n')) const Component.text('\n'),
        ],
      ),
      textarea(
        [Component.text(component.value)],
        attributes: {'aria-label': component.label, 'wrap': 'off'},
        spellCheck: SpellCheck.isFalse,
        events: {
          'scroll': (event) {
            final editor = event.target! as web.HTMLTextAreaElement;
            final mirror = editor.previousElementSibling!;
            mirror.scrollTop = editor.scrollTop;
            mirror.scrollLeft = editor.scrollLeft;
          },
        },
        onInput: (text) {
          setState(() => _text = text);
          component.onInput(text);
        },
      ),
    ]);
  }
}
