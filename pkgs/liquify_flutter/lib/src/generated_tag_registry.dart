// GENERATED CODE - DO NOT MODIFY BY HAND.
// Run: dart run tool/tag_codegen.dart

import 'package:liquify/parser.dart';
import 'tags/colored_box.dart';
import 'tags/ignore_pointer.dart';
import 'tags/sized_box.dart';

void registerGeneratedTags(Environment? environment) {
  _registerGeneratedTag('colored_box', (content, filters) => ColoredBoxTag(content, filters), environment);
  _registerGeneratedTag('ignore_pointer', (content, filters) => IgnorePointerTag(content, filters), environment);
  _registerGeneratedTag('sized_box', (content, filters) => SizedBoxTag(content, filters), environment);
}

void _registerGeneratedTag(
  String name,
  TagCreator creator,
  Environment? environment,
) {
  TagRegistry.register(name, creator);
  if (environment != null) {
    environment.registerLocalTag(name, creator);
  }
}
