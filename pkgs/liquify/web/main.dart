import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:liquify/liquify.dart';
import 'package:web/web.dart';

import 'builtin_examples.dart';

const _examples = <String, PlaygroundExample>{
  'basic': PlaygroundExample(
    entryFile: 'index.liquid',
    files: {
      'index.liquid': r'''{% assign title = "Hello, World!" %}
<h1>{{ title }}</h1>
<p>Today is {{ "now" | date: "%B %d, %Y" }}</p>

{% capture greeting %}Hello {{ "World" | upcase }}{% endcapture %}
<p>{{ greeting }}</p>

{% for item in items %}
  <div class="item">
    <span>{{ item.name }}</span>
    <span>{{ item.price | prepend: "$" }}</span>
  </div>
{% endfor %}''',
    },
    contextJson: r'''{
  "items": [
    { "name": "Widget", "price": 9.99 },
    { "name": "Gadget", "price": 24.99 },
    { "name": "Doohickey", "price": 4.99 }
  ]
}''',
  ),
  'layout': PlaygroundExample(
    entryFile: 'posts/hello-world.liquid',
    files: {
      'layouts/base.liquid': r'''<!DOCTYPE html>
<html>
<head>
  <title>{% block title %}Default Title{% endblock %}</title>
  {% block meta %}{% endblock %}
  <link rel="stylesheet" href="/styles.css">
  {% block styles %}{% endblock %}
</head>
<body>
  <header>
    {% block header %}
      <nav>
        <a href="/">Home</a>
        <a href="/about">About</a>
        <a href="/contact">Contact</a>
      </nav>
    {% endblock %}
  </header>

  <main>
    {% block content %}
      Default content
    {% endblock %}
  </main>

  <footer>
    {% block footer %}
      <p>&copy; {{ year }} My Website</p>
    {% endblock %}
  </footer>

  <script src="/main.js"></script>
  {% block scripts %}{% endblock %}
</body>
</html>''',
      'layouts/post.liquid':
          r'''{% layout "layouts/base.liquid", title: post_title, year: year %}

{% block meta %}
  <meta name="author" content="{{ post.author }}">
  <meta name="description" content="{{ post.excerpt }}">
{% endblock %}

{% block styles %}
  <link rel="stylesheet" href="/blog.css">
{% endblock %}

{% block content %}
  <article>
    <h1>{{ post_title }}</h1>
    <div class="metadata">
      By {{ post.author }} on {{ post.date | date: "%B %d, %Y" }}
    </div>
    <div class="content">
      {{ post.content }}
    </div>

    {% if post.tags.size > 0 %}
      <div class="tags">
        Tags:
        {% for tag in post.tags %}
          <span class="tag">{{ tag }}</span>
        {% endfor %}
      </div>
    {% endif %}
  </article>
{% endblock %}

{% block scripts %}
  <script src="/blog.js"></script>
{% endblock %}''',
      'posts/hello-world.liquid': r'''{% assign post_title = "Hello, World!" %}
{% layout "layouts/post.liquid", post_title: post_title, year: year %}

{%- block header -%}
  <h1>HEADER CONTENT</h1>
{%- endblock -%}

{% block footer %}
  {{ block.parent }}
  <div class="post-footer">
    <a href="/posts">Back to Posts</a>
  </div>
{% endblock %}''',
    },
    contextJson: r'''{
  "year": 2024,
  "post": {
    "title": "Hello, World!",
    "author": "John Doe",
    "date": "2024-02-09",
    "excerpt": "An introduction to our blog",
    "content": "Welcome to our new blog! This is our first post exploring layout inheritance, blocks, and parent content.",
    "tags": ["welcome", "introduction", "liquid"]
  }
}''',
  ),
  'dynamic-layout': PlaygroundExample(
    entryFile: 'pages/profile.liquid',
    files: {
      'layouts/full.liquid': r'''<!DOCTYPE html>
<html>
<head>
  <title>{{ title }}</title>
</head>
<body>
  <aside>Full navigation</aside>
  <main>{% block content %}{% endblock %}</main>
</body>
</html>''',
      'layouts/minimal.liquid': r'''<!DOCTYPE html>
<html>
<head>
  <title>{{ title }}</title>
</head>
<body>
  <main class="minimal">
    {% block content %}{% endblock %}
  </main>
</body>
</html>''',
      'pages/profile.liquid':
          r'''{% layout "layouts/{{ layout_type }}.liquid", title: user.name %}

{% block content %}
  <article>
    <h1>{{ user.name }}</h1>
    <p>{{ user.bio }}</p>
    <p>Selected layout: <strong>{{ layout_type }}</strong></p>
  </article>
{% endblock %}''',
    },
    contextJson: r'''{
  "layout_type": "full",
  "user": {
    "name": "Ada Lovelace",
    "bio": "Mathematician and early computing pioneer."
  }
}''',
  ),
  ...builtinExamples,
};

Future<void> main() async {
  final templateInput =
      document.getElementById('templateInput') as HTMLTextAreaElement;
  final dataInput = document.getElementById('dataInput') as HTMLTextAreaElement;

  final exampleSelect =
      document.getElementById('exampleSelect') as HTMLSelectElement;
  final autoRender = document.getElementById('autoRender') as HTMLInputElement;
  final renderBtn = document.getElementById('renderBtn') as HTMLButtonElement;
  final resetBtn = document.getElementById('resetBtn') as HTMLButtonElement;

  final fileList = document.getElementById('fileList') as HTMLElement;
  final fileCount = document.getElementById('fileCount') as HTMLSpanElement;
  final entryPath = document.getElementById('entryPath') as HTMLElement;
  final activePath = document.getElementById('activePath') as HTMLElement;
  final workspaceHint =
      document.getElementById('workspaceHint') as HTMLSpanElement;

  final newFileBtn = document.getElementById('newFileBtn') as HTMLButtonElement;
  final setEntryBtn =
      document.getElementById('setEntryBtn') as HTMLButtonElement;
  final renameFileBtn =
      document.getElementById('renameFileBtn') as HTMLButtonElement;
  final deleteFileBtn =
      document.getElementById('deleteFileBtn') as HTMLButtonElement;

  final rawTabBtn = document.getElementById('rawTabBtn') as HTMLButtonElement;
  final previewTabBtn =
      document.getElementById('previewTabBtn') as HTMLButtonElement;
  final rawOutputPanel =
      document.getElementById('rawOutputPanel') as HTMLElement;
  final outputRaw = document.getElementById('outputRaw') as HTMLElement;
  final previewOutput =
      document.getElementById('previewOutput') as HTMLIFrameElement;
  final renderTime = document.getElementById('renderTime') as HTMLSpanElement;
  final renderStatus =
      document.getElementById('renderStatus') as HTMLSpanElement;

  final fileDialog = document.getElementById('fileDialog') as HTMLDialogElement;
  final fileForm = document.getElementById('fileForm') as HTMLFormElement;
  final fileDialogTitle =
      document.getElementById('fileDialogTitle') as HTMLElement;
  final filePathInput =
      document.getElementById('filePathInput') as HTMLInputElement;
  final fileDialogError =
      document.getElementById('fileDialogError') as HTMLElement;
  final fileDialogCloseBtn =
      document.getElementById('fileDialogCloseBtn') as HTMLButtonElement;
  final fileDialogCancelBtn =
      document.getElementById('fileDialogCancelBtn') as HTMLButtonElement;

  final deleteDialog =
      document.getElementById('deleteDialog') as HTMLDialogElement;
  final deletePath = document.getElementById('deletePath') as HTMLElement;
  final cancelDeleteBtn =
      document.getElementById('cancelDeleteBtn') as HTMLButtonElement;
  final confirmDeleteBtn =
      document.getElementById('confirmDeleteBtn') as HTMLButtonElement;

  var selectedExample = 'basic';
  var files = <String, String>{};
  var activeFile = '';
  var entryFile = '';
  var outputMode = 'raw';
  var renderGeneration = 0;
  Timer? renderTimer;

  String? fileDialogOperation;
  String? renameSource;

  void refreshEditorHighlighting() {
    document.dispatchEvent(Event('liquify-editor-refresh'));
  }

  void refreshOutputHighlighting() {
    document.dispatchEvent(Event('liquify-output-refresh'));
  }

  void saveActiveFile() {
    if (activeFile.isNotEmpty && files.containsKey(activeFile)) {
      files[activeFile] = templateInput.value;
    }
  }

  void showOutputMode(String mode) {
    outputMode = mode;
    final showRaw = outputMode == 'raw';

    rawOutputPanel.hidden = (!showRaw).toJS;
    previewOutput.hidden = showRaw.toJS;

    rawTabBtn.className = showRaw ? 'output-tab active' : 'output-tab';
    previewTabBtn.className = showRaw ? 'output-tab' : 'output-tab active';
    rawTabBtn.setAttribute('aria-selected', showRaw ? 'true' : 'false');
    previewTabBtn.setAttribute('aria-selected', showRaw ? 'false' : 'true');
  }

  void refreshFileList() {
    fileList.textContent = '';

    final paths = files.keys.toList()..sort();
    for (final path in paths) {
      final button = document.createElement('button') as HTMLButtonElement;
      button.type = 'button';
      button.className = path == activeFile ? 'file-item active' : 'file-item';
      button.title = path;

      final pathLabel = document.createElement('span') as HTMLSpanElement;
      pathLabel.className = 'file-path-label';
      pathLabel.textContent = path;
      button.appendChild(pathLabel);

      if (path == entryFile) {
        final badge = document.createElement('span') as HTMLSpanElement;
        badge.className = 'entry-badge';
        badge.textContent = 'entry';
        button.appendChild(badge);
      }

      button.onClick.listen((_) {
        if (path == activeFile) return;
        saveActiveFile();
        activeFile = path;
        templateInput.value = files[path] ?? '';
        refreshFileList();
        refreshEditorHighlighting();
      });

      fileList.appendChild(button);
    }

    final count = files.length;
    fileCount.textContent = '$count ${count == 1 ? 'file' : 'files'}';
    activePath.textContent = activeFile;
    entryPath.textContent = entryFile;
    workspaceHint.textContent = activeFile == entryFile
        ? 'Editing the entry template'
        : 'Editing a dependency template';

    setEntryBtn.disabled = activeFile == entryFile;
    deleteFileBtn.disabled = files.length <= 1;
  }

  Future<void> renderWorkspace() async {
    renderTimer?.cancel();
    saveActiveFile();

    final generation = ++renderGeneration;
    final start = DateTime.now().microsecondsSinceEpoch;

    renderBtn.disabled = true;
    renderBtn.textContent = 'Rendering…';
    renderStatus.textContent = 'Rendering $entryFile';

    try {
      final dataText = dataInput.value.trim();
      final dynamic decoded = dataText.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(dataText);

      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Context must be a JSON object.');
      }

      final root = MapRoot(Map<String, String>.from(files));
      final template = Template.fromFile(entryFile, root, data: decoded);
      final result = await template.renderAsync();

      if (generation != renderGeneration) return;

      outputRaw.textContent = result;
      outputRaw.className = 'hljs language-xml';
      previewOutput.setAttribute('srcdoc', result);
      refreshOutputHighlighting();

      final elapsed = (DateTime.now().microsecondsSinceEpoch - start) / 1000;
      renderTime.textContent = '${elapsed.toStringAsFixed(1)}ms';
      renderStatus.textContent = 'Rendered $entryFile';
    } catch (error) {
      if (generation != renderGeneration) return;

      outputRaw.textContent = 'Error: $error';
      outputRaw.className = 'hljs output-error';
      previewOutput.setAttribute('srcdoc', '');
      renderTime.textContent = '';
      renderStatus.textContent = 'Render failed';
      showOutputMode('raw');
    } finally {
      if (generation == renderGeneration) {
        renderBtn.disabled = false;
        renderBtn.textContent = 'Render';
      }
    }
  }

  void scheduleRender() {
    renderTimer?.cancel();
    if (!autoRender.checked) return;

    renderTimer = Timer(const Duration(milliseconds: 280), () {
      renderWorkspace();
    });
  }

  void loadExample(String key) {
    final example = _examples[key];
    if (example == null) return;

    renderTimer?.cancel();
    selectedExample = key;
    files = Map<String, String>.from(example.files);
    entryFile = example.entryFile;
    activeFile = entryFile;

    exampleSelect.value = key;
    templateInput.value = files[activeFile] ?? '';
    dataInput.value = example.contextJson;

    refreshFileList();
    refreshEditorHighlighting();
    renderWorkspace();
  }

  String normalizeTemplatePath(String value) {
    var path = value.trim().replaceAll('\\', '/');
    while (path.startsWith('./')) {
      path = path.substring(2);
    }
    while (path.contains('//')) {
      path = path.replaceAll('//', '/');
    }
    while (path.startsWith('/')) {
      path = path.substring(1);
    }
    if (path.isNotEmpty && !path.endsWith('/') && !path.endsWith('.liquid')) {
      path = '$path.liquid';
    }
    return path;
  }

  String? validateTemplatePath(String path, {String? currentPath}) {
    if (path.isEmpty) return 'Enter a template path.';
    if (path.split('/').any((segment) => segment == '.' || segment == '..')) {
      return 'Current- and parent-directory segments are not allowed.';
    }
    if (path.endsWith('/')) return 'The path must include a file name.';
    if (files.containsKey(path) && path != currentPath) {
      return 'A template with this path already exists.';
    }
    return null;
  }

  void openFileDialogForCreate() {
    fileDialogOperation = 'create';
    renameSource = null;
    fileDialogTitle.textContent = 'Add template';
    filePathInput.value = 'snippets/new-template.liquid';
    fileDialogError.textContent = '';
    fileDialog.showModal();
    filePathInput.focus();
  }

  void openFileDialogForRename() {
    fileDialogOperation = 'rename';
    renameSource = activeFile;
    fileDialogTitle.textContent = 'Rename template';
    filePathInput.value = activeFile;
    fileDialogError.textContent = '';
    fileDialog.showModal();
    filePathInput.focus();
  }

  void closeFileDialog() {
    fileDialog.close();
    fileDialogError.textContent = '';
  }

  templateInput.onInput.listen((_) {
    saveActiveFile();
    scheduleRender();
  });

  dataInput.onInput.listen((_) => scheduleRender());

  exampleSelect.onChange.listen((_) {
    loadExample(exampleSelect.value);
  });

  autoRender.onChange.listen((_) {
    if (autoRender.checked) scheduleRender();
  });

  renderBtn.onClick.listen((_) {
    renderWorkspace();
  });

  resetBtn.onClick.listen((_) {
    loadExample(selectedExample);
  });

  rawTabBtn.onClick.listen((_) => showOutputMode('raw'));
  previewTabBtn.onClick.listen((_) => showOutputMode('preview'));

  setEntryBtn.onClick.listen((_) {
    saveActiveFile();
    entryFile = activeFile;
    refreshFileList();
    renderWorkspace();
  });

  newFileBtn.onClick.listen((_) => openFileDialogForCreate());
  renameFileBtn.onClick.listen((_) => openFileDialogForRename());

  deleteFileBtn.onClick.listen((_) {
    if (files.length <= 1) return;
    deletePath.textContent = activeFile;
    deleteDialog.showModal();
  });

  cancelDeleteBtn.onClick.listen((_) => deleteDialog.close());

  confirmDeleteBtn.onClick.listen((_) {
    if (files.length <= 1) {
      deleteDialog.close();
      return;
    }

    final removedPath = activeFile;
    files.remove(removedPath);

    final remainingPaths = files.keys.toList()..sort();
    if (entryFile == removedPath) entryFile = remainingPaths.first;
    activeFile = entryFile;
    templateInput.value = files[activeFile] ?? '';

    deleteDialog.close();
    refreshFileList();
    refreshEditorHighlighting();
    renderWorkspace();
  });

  fileDialogCloseBtn.onClick.listen((_) => closeFileDialog());
  fileDialogCancelBtn.onClick.listen((_) => closeFileDialog());

  fileForm.onSubmit.listen((event) {
    event.preventDefault();

    final path = normalizeTemplatePath(filePathInput.value);
    final error = validateTemplatePath(
      path,
      currentPath: fileDialogOperation == 'rename' ? renameSource : null,
    );

    if (error != null) {
      fileDialogError.textContent = error;
      return;
    }

    if (fileDialogOperation == 'rename') {
      final source = renameSource;
      if (source == null || !files.containsKey(source)) {
        fileDialogError.textContent = 'The original template no longer exists.';
        return;
      }

      saveActiveFile();
      final content = files.remove(source) ?? '';
      files[path] = content;
      if (entryFile == source) entryFile = path;
      activeFile = path;
    } else {
      saveActiveFile();
      files[path] = '<!-- New Liquify template -->\n';
      activeFile = path;
    }

    templateInput.value = files[activeFile] ?? '';
    closeFileDialog();
    refreshFileList();
    refreshEditorHighlighting();
    scheduleRender();
  });

  EventStreamProviders.keyDownEvent.forTarget(document).listen((event) {
    if ((event.ctrlKey || event.metaKey) && event.key == 'Enter') {
      event.preventDefault();
      renderWorkspace();
    }
  });

  showOutputMode('raw');
  loadExample(selectedExample);
}
