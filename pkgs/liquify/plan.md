Yes — **we can keep this non‑breaking at the public API level** *and* still get the “render to different targets” behavior you’re describing.

The key nuance is:

* **Making `Template.render()` itself generic is *effectively* a breaking change** in Dart (type inference + call sites with no contextual type often collapse to `dynamic`, and you lose the strong guarantee that `render()` returns `String`).
* But you *can* get the same end result (string vs `UiNode` vs Stac JSON) by:

  1. keeping `Template.render(): String` exactly as-is
  2. adding an **additive** generic entry point like `renderWith<T>(RenderTarget<T> target)`
  3. providing a **Flutter/SDUI wrapper type** (e.g. `UiTemplate`) that exposes `render()` returning `UiDocument` (or `UiNode`) — so you still get `template.render()` vs `flutterThingy.render()` with “the same public APIs”, just on different types.

Below is a **handoff-ready RFC** that bakes in that approach, explicitly calls out where Liquify needs changes, and answers your open questions.

---

# RFC: Multi‑Target Rendering & SDUI for Liquify (String → UI Tree / JSON)

**Status:** Draft (handoff-ready)
**Date:** 2025‑12‑23
**Owners:** Liquify maintainers
**Primary Goal:** Extend Liquify to render **Flutter UI trees / SDUI schemas** while preserving existing **string/HTML rendering** and reusing the current parser + tag/filter system.

---

## 1) Motivation

Liquify already has the right conceptual shape:

* Parser → AST
* Evaluator walks AST
* Tags + filters are extension points
* Output is accumulated into a `Buffer`

Today `Buffer` is string‑backed: it writes `obj.toString()` into an internal `StringBuffer`. ([Dart packages][1])

We want:

1. **No rewrite** of parser/AST
2. **Minimal breakage** for existing users
3. A path to:

   * Flutter UI rendering
   * Over‑the‑wire SDUI (JSON schemas)
   * Layout/block composition (already a Liquify strength)

---

## 2) Current constraints in Liquify (important for design)

### 2.1 Buffer capture exists, but it’s string‑only today

Evaluator has a “block buffer stack”:

* `pushBuffer()` currently does `_blockBuffers.add(Buffer());` ([Dart packages][2])
* `popBuffer()` returns `_blockBuffers.removeLast().toString()` ([Dart packages][3])
* `currentBuffer` selects the top block buffer if present, else root `buffer`. ([Dart packages][4])

So: capture exists structurally, but it assumes a **string Buffer**.

### 2.2 Tag writes currently bypass `currentBuffer`

`evaluateNodes()` writes non-tag nodes to `currentBuffer`, but tags go through `visitTag`. ([Dart packages][5])

`Evaluator.visitTag()` currently calls `tag?.evaluate(this, buffer);` — i.e. **root buffer**, not `currentBuffer`. ([Dart packages][6])
Same issue in async: `evaluateAsync` uses `buffer`. ([Dart packages][7])

For SDUI / node capture / layout slots, tags must respect “what buffer am I currently writing to”.

This is either:

* a **bug** relative to capture semantics, or
* a legacy behavior some users may rely on

We’ll treat it as a **behavioral compatibility risk** (see §10).

### 2.3 Tags and filters are already the correct extension point

Custom tags implement `evaluate(Evaluator, Buffer)` / `evaluateAsync(...)`. ([Dart packages][8])
This is good: we can keep that interface stable and evolve the Buffer.

---

## 3) Proposed direction (validated)

### Core idea

**Generalize the output “sink”, not the parser or the tag API.**

Keep:

* AST
* evaluator
* tag/filter registries
* tag `evaluate(evaluator, buffer)` signature ([Dart packages][8])

Evolve:

* Buffer internals → from “string only” to “pluggable sink”
* capture implementation → sink‑aware (`spawn` / `merge`)
* tag writes → target the *active* buffer (`currentBuffer`)

---

## 4) Rendering API design: “render tells us what it wants”

You proposed: “make render generic so default returns String, Flutter returns UiNode”.

### 4.1 Why `Template.render<T>()` is not recommended

Making `render()` generic in Dart can cause:

* loss of type stability at call sites (type argument can infer to `dynamic`)
* signature breaking for users relying on `String render()` shape
* worse DX (surprising inference behaviors)

So we avoid changing `render()`.

### 4.2 The non‑breaking version of your idea

Add a **new, additive generic entry point**:

```dart
abstract class RenderTarget<R> {
  RenderSink<R> createSink();
  R finalize(RenderSink<R> sink);
}

abstract class RenderSink<R> {
  void write(Object? value);
  void writeln([Object? value]);
  void clear();

  /// New: used for capture/layout/block
  RenderSink<R> spawn();
  void merge(RenderSink<R> other);

  R result();

  /// Optional: debug / fallback string representation
  String debugString();
}
```

Then keep existing:

```dart
class Template {
  String render() => renderWith(StringRenderTarget());
  Future<String> renderAsync() => renderWithAsync(StringRenderTarget());

  R renderWith<R>(RenderTarget<R> target) { ... }
  Future<R> renderWithAsync<R>(RenderTarget<R> target) { ... }
}
```

**Existing users keep calling `template.render()` and get a `String`.**
New users can call `template.renderWith(UiTarget())` to get UI trees, Stac JSON, etc.

### 4.3 “Same public APIs” for Flutter: wrapper type

To get your desired ergonomics:

* `Template.render()` → `String`
* `UiTemplate.render()` → `UiDocument` (or `UiNode`)

without changing `Template.render()`:

```dart
class UiTemplate {
  UiTemplate(this._template, {UiTarget? target})
      : _target = target ?? const UiTarget();

  final Template _template;
  final UiTarget _target;

  UiDocument render() => _template.renderWith(_target);
  Future<UiDocument> renderAsync() => _template.renderWithAsync(_target);

  // mirror Template API: updateContext, environment, etc.
}
```

So you get:

* `template.render()` (string)
* `uiTemplate.render()` (UI)

This matches your “template vs flutterthingy” vision **without an API break**.

---

## 5) Core engine refactor: Buffer becomes sink‑backed

### 5.1 Buffer public API remains stable

Buffer today exposes:

* `write(Object?)`
* `writeln([Object?])`
* `clear()`
* `toString()`
* `isEmpty`, `length` ([Dart packages][9])

We keep these, but internally delegate to `RenderSink`.

### 5.2 Additive Buffer extensions needed for UI + capture

Add:

```dart
class Buffer {
  Buffer({RenderSink? sink}) : _sink = sink ?? StringSink();

  Buffer spawn() => Buffer(sink: _sink.spawn());
  void merge(Buffer other) => _sink.merge(other._sink);

  Object value() => _sink.result();
}
```

* `spawn()` replaces “make a new Buffer()” patterns
* `merge()` replaces “append inner.toString()” patterns
* `value()` lets a target read the final structured output

### 5.3 Default behavior stays identical

`StringSink` implements current semantics:

* `write(null)` writes empty string (matches current implementation). ([Dart packages][1])
* `toString()` returns the underlying string. ([Dart packages][10])

So existing output stays the same.

---

## 6) Capture / blocks / layouts must become sink‑aware

Today:

* `pushBuffer()` always creates `Buffer()` which is string-backed ([Dart packages][2])
* `popBuffer()` returns `toString()` ([Dart packages][3])

### Proposed:

* `pushBuffer()` should spawn from the currently active sink:

```dart
void pushBuffer() {
  _blockBuffers.add(currentBuffer.spawn());
}
```

* Keep `popBuffer(): String` for backwards compatibility, but implement it as:

```dart
String popBuffer() => _blockBuffers.removeLast().toString();
```

* Add a new **non-breaking** API:

```dart
Object? popBufferValue() => _blockBuffers.removeLast().value();
```

This lets core tags (layout/block) capture structured nodes in UI mode without changing Liquid’s `capture` tag semantics.

---

## 7) Fixing tag output routing: `buffer` vs `currentBuffer`

This is the single most important correctness point for UI rendering.

Current:

````dart
tag?.evaluate(this, buffer);
``` :contentReference[oaicite:14]{index=14}

Proposed:

```dart
tag?.evaluate(this, currentBuffer);
````

And async similarly. ([Dart packages][7])

### Compatibility risk

This is a **behavior change**. If any existing templates “accidentally” depended on tags escaping capture buffers, they’ll behave differently.

Mitigation options:

* **Option A (recommended):** Treat as a bugfix, but add a short migration note.
* **Option B (safer):** Introduce an `Environment`/`Evaluator` flag:

  * `legacyTagWritesToRootBuffer = true` (default for 1.x)
  * UI targets force it off
  * flip default in 2.0

Given you’re open to a breaking change if needed, we can:

* ship the sink architecture non-breaking
* ship the tag routing fix behind a flag
* later flip in a major bump

---

## 8) UI output model: `UiNode` (or reuse Stac)

### 8.1 Why not render Flutter Widgets directly?

Widgets:

* aren’t serializable
* can’t be sent over the wire
* complicate diffing/state restoration

So we output a **data model** first, then render it.

### 8.2 Proposed schema (engine-owned)

```dart
sealed class UiNode {
  Map<String, dynamic> toJson();
}

class UiElement extends UiNode {
  final String type;
  final Map<String, dynamic> props;
  final List<UiNode> children;
  final String? key;
}

class UiText extends UiNode {
  final String text;
}
```

`Buffer`/`UiSink` can store a **fragment** (`List<UiNode>`) as its result.

### 8.3 “Just works” text behavior

If a template writes raw text or `{{ variable }}` outside a UI tag:

* `UiSink.write("hello")` becomes `UiText("hello")`
* adjacent text nodes can be merged

This gives you a JSX-like feel:

* string output naturally becomes text nodes
* explicit tags create element nodes

---

## 9) Tag → Flutter mapping

### 9.1 UI tags are additive (do not replace Liquid tags)

Example Liquid:

```liquid
{% column gap:12 %}
  Hello {{ user.name }}
  {% button text:"Buy" action:{ "type":"navigate", "route":"/checkout" } %}
{% endcolumn %}
```

* `column` tag creates `UiElement(type:"column")`
* body is captured via `pushBuffer()`/`popBufferValue()`
* `button` outputs a `UiElement(type:"button")`

### 9.2 Reusing core tags

Most built-ins are control-flow and should work unchanged once tag routing + capture are sink-aware:

* `if/unless`, `for`, `case`, `assign`, etc.

Tags needing updates are those that capture or “compose” output:

* `capture`
* `layout` / `block`
* `render` / `include`

Liquify’s docs highlight layout + blocks as a core feature. ([Dart packages][11])
Making them sink-aware turns this into a major UI composition advantage (layouts = shells, blocks = slots).

---

## 10) Styling strategy (Mix optional)

### 10.1 Styling stays data

Keep styles as:

* tokens (`variant: "primary"`)
* classes (`class: "p-4 gap-2"`)
* or structured maps

No Flutter types in core.

### 10.2 Mix integration as an adapter

If you want Mix:

* implement in `liquify_flutter`
* map `props["style"]` / `props["class"]` → Mix styles

Mix stays optional and doesn’t infect server-side rendering.

---

## 11) Over-the-wire SDUI modes

You asked: “React Native-ish over the wire?”

Yes. There are 3 modes:

### Mode A — Client-side templates (fast MVP)

* Server sends Liquid templates
* Client parses + renders locally (Liquify in Flutter)
* Requires sandboxing (strict environment) which Liquify already supports. ([Dart packages][11])

### Mode B — Server renders UI schema (recommended SDUI)

* Server runs Liquify → outputs `UiDocument` JSON
* Client receives JSON → renders widgets using registry
* Best for security and platform consistency

### Mode C — Diff/Patch (future)

* send patches to UI tree
* preserve state using node `key`

---

## 12) “Look into Stac”: how we can leverage it

Stac is explicitly an SDUI framework for Flutter that renders UI from JSON and supports registering parsers/actions. ([GitHub][12])

**Two good integration paths:**

### Path 1: Liquify → our `UiNode` → our Flutter renderer

Pros:

* full control of schema
* can be framework-agnostic
* simpler core ownership

### Path 2: Liquify → Stac JSON → Stac renderer

Pros:

* fastest route to “over the wire” UI + actions
* reuse Stac’s runtime + extension model

Cons:

* schema coupled to Stac
* you inherit Stac’s limitations/choices

**Recommendation for MVP speed:** ship `UiNode` *but* keep it close enough that you can add a `StacTarget` later (or even first). The architecture (RenderTarget + sink) supports multiple outputs.

---

## 13) Non-breaking plan summary

### What stays unchanged for existing users

* `Template.render(): String` and `Template.renderAsync(): Future<String>` stay exactly the same. ([Dart packages][11])
* Tag API remains `evaluate(Evaluator, Buffer)`. ([Dart packages][8])
* Buffer continues to support `write/writeln/toString`. ([Dart packages][9])

### What is additive

* `Template.renderWith<T>(RenderTarget<T>)`
* `Template.renderWithAsync<T>(RenderTarget<T>)`
* `Buffer.spawn()`, `Buffer.merge(...)`, `Buffer.value()`
* `Evaluator.popBufferValue()` (or equivalent)
* `UiTemplate` wrapper type in Flutter package

### The only “behavior break” to manage

* `visitTag` writing to `currentBuffer` instead of `buffer`. ([Dart packages][6])
  Mitigate with a flag + staged rollout if needed (§7).

---

## 14) Implementation roadmap (handoff tasks)

### Phase 0 — Tests + safety net

* Add tests for:

  * `{% capture %}` containing tags
  * layouts/blocks capturing content
  * ensure `render()` output unchanged for baseline templates

### Phase 1 — Core sink architecture (minimal refactor)

* Add `RenderSink` + `RenderTarget`
* Convert `Buffer` to delegate to a sink
* Implement `StringSink` to match existing behavior (including null handling). ([Dart packages][1])
* Add `spawn/merge/value`

### Phase 2 — Capture becomes sink-aware

* Update BufferHandling:

  * `pushBuffer()` uses `currentBuffer.spawn()` instead of `Buffer()` ([Dart packages][2])
  * add `popBufferValue()`

### Phase 3 — Fix tag routing (with compatibility plan)

* Change `visitTag` / `visitTagAsync` to pass `currentBuffer` (or gate behind flag). ([Dart packages][6])

### Phase 4 — UI schema + UI sink

* Add `liquify_ui` (or `liquify_sdui`) package:

  * `UiNode`, `UiText`, `UiElement`, `UiAction`
  * `UiSink` implements `RenderSink<UiDocument>`
  * `UiTarget` for `renderWith`

### Phase 5 — Flutter renderer package

* `liquify_flutter`:

  * registry `type → WidgetBuilder`
  * action registry `action.type → handler`
  * optional Mix adapter

### Phase 6 — SDUI server path

* Add:

  * schema JSON versioning
  * validation
  * caching

---

## 15) Proposed “handoff” usage examples

### Existing users (unchanged)

```dart
final t = Template.parse('Hello {{ name }}', data: {'name': 'World'});
final s = t.render(); // String
```

### UI rendering (new)

```dart
final ui = UiTemplate.parse(
  '{% column %}Hello {{ name }}{% endcolumn %}',
  data: {'name': 'World'},
);

final doc = ui.render(); // UiDocument
```

### Over the wire (server)

```dart
final doc = ui.render();
return jsonEncode(doc.toJson());
```

### Over the wire (client)

```dart
final doc = UiDocument.fromJson(jsonDecode(payload));
final widget = LiquifyFlutterRenderer(registry).build(doc);
```

---

## 16) Decision points (to validate before coding)

1. **Tag routing fix strategy**

   * immediate change (bugfix) vs feature flag vs major bump

2. **Schema choice**

   * Own `UiNode` vs Stac JSON output first
   * (You can support both via multiple targets)

3. **Layout/block semantics in UI mode**

   * Keep Liquid `capture` string semantics
   * Add structured capture APIs for internal layout/block
   * Possibly add UI-specific `slot` tag later

---

# Validation Answer (explicit)

### Would this mean *no breaking change*?

* **No breaking change to the public API is required** (existing `Template.render(): String` stays).
* There **is one potential behavioral change** you must manage: tags should write to `currentBuffer`, not root `buffer`, to make capture/layout correct. ([Dart packages][6])
  You can ship that behind a flag to keep 1.x stable and flip in 2.0.

### Does your “render tells us what it wants” idea work?

Yes — **implemented as `renderWith<T>(RenderTarget<T>)` + wrapper types** (so `Template.render()` remains stable, while `UiTemplate.render()` returns UI).

---

If you want, the next concrete handoff artifact is a **checklist of exact file-level edits** (Buffer → sink, BufferHandling changes, visitTag routing change, plus a minimal `UiSink` proof-of-concept).

[1]: https://pub.dev/documentation/liquify/latest/parser/Buffer/write.html "write method - Buffer class - parser library - Dart API"
[2]: https://pub.dev/documentation/liquify/latest/parser/BufferHandling/pushBuffer.html "pushBuffer method - BufferHandling extension - parser library - Dart API"
[3]: https://pub.dev/documentation/liquify/latest/parser/BufferHandling/popBuffer.html "popBuffer method - BufferHandling extension - parser library - Dart API"
[4]: https://pub.dev/documentation/liquify/latest/parser/BufferHandling/currentBuffer.html "currentBuffer property - BufferHandling extension - parser library - Dart API"
[5]: https://pub.dev/documentation/liquify/latest/parser/Evaluation/evaluateNodes.html "evaluateNodes method - Evaluation extension - parser library - Dart API"
[6]: https://pub.dev/documentation/liquify/latest/parser/Evaluator/visitTag.html "visitTag method - Evaluator class - parser library - Dart API"
[7]: https://pub.dev/documentation/liquify/latest/parser/Evaluator/visitTagAsync.html "visitTagAsync method - Evaluator class - parser library - Dart API"
[8]: https://pub.dev/documentation/liquify/latest/parser/AbstractTag-class.html "AbstractTag class - parser library - Dart API"
[9]: https://pub.dev/documentation/liquify/latest/parser/Buffer-class.html "Buffer class - parser library - Dart API"
[10]: https://pub.dev/documentation/liquify/latest/parser/Buffer/toString.html "toString method - Buffer class - parser library - Dart API"
[11]: https://pub.dev/documentation/liquify/latest/liquify "liquify library - Dart API"
[12]: https://github.com/StacDev/stac?utm_source=chatgpt.com "StacDev/stac"
