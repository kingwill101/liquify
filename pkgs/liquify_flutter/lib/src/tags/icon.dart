import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class IconTag extends WidgetTagBase with AsyncTag {
  IconTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final props = <String, dynamic>{};
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'name':
        case 'icon':
        case 'codePoint':
        case 'code':
        case 'size':
        case 'fill':
        case 'weight':
        case 'grade':
        case 'opticalSize':
        case 'color':
        case 'shadows':
        case 'semanticLabel':
        case 'textDirection':
        case 'applyTextScaling':
        case 'blendMode':
        case 'fontWeight':
          props[name] = evaluator.evaluate(arg.value);
          break;
        default:
          handleUnknownArg('icon', name);
          break;
      }
    }
    props['color'] = resolvePropertyValue<Color?>(
      environment: evaluator.context,
      namedArgs: props,
      name: 'color',
      parser: parseColor,
    );
    buffer.write(_buildIcon(props));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final props = <String, dynamic>{};
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'name':
        case 'icon':
        case 'codePoint':
        case 'code':
        case 'size':
        case 'fill':
        case 'weight':
        case 'grade':
        case 'opticalSize':
        case 'color':
        case 'shadows':
        case 'semanticLabel':
        case 'textDirection':
        case 'applyTextScaling':
        case 'blendMode':
        case 'fontWeight':
          props[name] = evaluator.evaluate(arg.value);
          break;
        default:
          handleUnknownArg('icon', name);
          break;
      }
    }
    props['color'] = resolvePropertyValue<Color?>(
      environment: evaluator.context,
      namedArgs: props,
      name: 'color',
      parser: parseColor,
    );
    buffer.write(_buildIcon(props));
  }
}

Widget _buildIcon(Map<String, dynamic> props) {
  final icon = resolveIcon(props);
  if (icon == null) {
    return const SizedBox.shrink();
  }
  return Icon(
    icon,
    size: toDouble(props['size']),
    fill: toDouble(props['fill']),
    weight: toDouble(props['weight']),
    grade: toDouble(props['grade']),
    opticalSize: toDouble(props['opticalSize']),
    color: parseColor(props['color']),
    shadows: _parseShadows(props['shadows']),
    semanticLabel: props['semanticLabel']?.toString(),
    textDirection: parseTextDirection(props['textDirection']),
    applyTextScaling: toBool(props['applyTextScaling']),
    blendMode: parseBlendMode(props['blendMode']),
    fontWeight: parseFontWeight(props['fontWeight']),
  );
}

List<Shadow>? _parseShadows(Object? value) {
  if (value is List<Shadow>) {
    return value;
  }
  if (value is Iterable) {
    final shadows = <Shadow>[];
    for (final entry in value) {
      if (entry is Shadow) {
        shadows.add(entry);
      } else if (entry is Map) {
        shadows.add(
          Shadow(
            color: parseColor(entry['color']) ?? const Color(0xFF000000),
            offset: Offset(
              toDouble(entry['dx']) ?? toDouble(entry['x']) ?? 0,
              toDouble(entry['dy']) ?? toDouble(entry['y']) ?? 0,
            ),
            blurRadius:
                toDouble(entry['blurRadius']) ?? toDouble(entry['blur']) ?? 0,
          ),
        );
      }
    }
    return shadows;
  }
  return null;
}
