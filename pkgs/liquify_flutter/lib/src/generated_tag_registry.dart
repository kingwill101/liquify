// GENERATED CODE - DO NOT MODIFY BY HAND.
// Run: dart run tool/tag_codegen.dart

import 'package:liquify/parser.dart';
import 'tags/colored_box.dart';
import 'tags/ignore_pointer.dart';
import 'tags/sized_box.dart';

/// Tracks if generated tags have been registered to the global TagRegistry.
bool _generatedTagsRegistered = false;

/// Map of tag names to their creators - built once and reused.
Map<String, TagCreator>? _manualTagCreators;

Map<String, TagCreator> _getManualTagCreators() {
  return _manualTagCreators ??= {
    'colored_box': (content, filters) => ColoredBoxTag(content, filters),
    'ignore_pointer': (content, filters) => IgnorePointerTag(content, filters),
    'sized_box': (content, filters) => SizedBoxTag(content, filters),
  };
}

void registerGeneratedTags(Environment? environment) {
  final creators = _getManualTagCreators();

  // Register to global TagRegistry only once
  if (!_generatedTagsRegistered) {
    final existing = TagRegistry.tags.toSet();
    for (final entry in creators.entries) {
      if (!existing.contains(entry.key)) {
        TagRegistry.register(entry.key, entry.value);
      }
    }
    _generatedTagsRegistered = true;
  }

  // Register to environment's local tags if provided
  if (environment != null) {
    // Batch register all tags at once for better performance
    final localTags = environment.getRegister('tags') as Map<String, TagCreator>? ?? <String, TagCreator>{};
    localTags.addAll(creators);
    environment.setRegister('tags', localTags);
  }
}
