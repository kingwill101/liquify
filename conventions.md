# Liquify Flutter Port Conventions

This file documents how to port Flutter widgets into the Liquify Flutter
initiative so tags remain consistent, reusable, and testable.

## 1) Tag design principles
- Match Flutter API names/casing for properties (e.g. `minHeight`, `isExpanded`).
- Prefer minimal, direct mappings to Flutter widgets before adding abstractions.
- Reuse shared helpers in `tag_helpers.dart` and `property_resolver.dart`.
- Avoid widget-specific helpers if a shared utility would work.

## 2) Tag structure
- Tags MUST extend `WidgetTagBase`.
- Parsing logic lives in a `_parseConfig(...)` method.
- Build logic lives in a `_buildX(...)` function.
- Use `WidgetTagBase.asWidgets(...)` for child conversion.
- Use `resolveIds(...)` to construct id/key consistently.

## 3) Property tags vs widget tags
We support tags that render widgets and tags that exist only as properties.

Property tags:
- `padding`, `margin`, `alignment`, `size`, `child`, `background` (and others)
- Use `resolvePropertyValue(...)` to allow name args or property tags.

Example pattern:
```
final namedValues = <String, Object?>{};
// collect named args into namedValues
final padding = resolvePropertyValue<EdgeInsetsGeometry?>(
  environment: evaluator.context,
  namedArgs: namedValues,
  name: 'padding',
  parser: edgeInsets,
);
```

## 4) Parsing rules
- Always parse values via shared helpers (`parseColor`, `parseTextStyle`, etc).
- Keep switch cases explicit; every named arg must be enumerated.
- Unknown args MUST call `handleUnknownArg(tagName, name)` (strict mode).

## 5) Strict mode
Strict validation is enabled for tests and demo runs:
- Unknown tag args throw (strict tags).
- Unknown map keys throw in helper parsers (strict props).

When adding new keys to a map parser, update `_assertKnownKeys` allowlists in
`tag_helpers.dart`.

## 6) Actions/events
- Use `buildWidgetEvent(...)` and `resolveActionCallback(...)`.
- Include a consistent `event` name and useful `props` for handlers.

## 7) Demo + tests (required)
- Add a demo usage snippet in the example app assets.
- Add at least one widget test that uses the new tag.
- Tests run with strict tags/props enabled by default.

## 8) Naming and conventions
- Tag name is snake_case (e.g. `action_chip`, `date_picker`).
- Arg names mirror Flutter property casing.
- Favor readability over implicit behavior; keep parsing explicit.

## 9) Do/Don’t
Do:
- Reuse shared helpers and common property tags.
- Keep properties in Flutter casing.
- Add tests and demo usage with real data.

Don’t:
- Duplicate helpers in per-widget files.
- Swallow unknown arguments.
- Add properties that Flutter widgets don’t support.
