import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class PlaceholderTag extends WidgetTagBase with AsyncTag {
  PlaceholderTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    buffer.write(_buildPlaceholder(config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    buffer.write(_buildPlaceholder(config));
  }

  _PlaceholderConfig _parseConfig(Evaluator evaluator) {
    final config = _PlaceholderConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'color':
          config.color = parseColor(value);
          break;
        case 'strokeWidth':
          config.strokeWidth = toDouble(value);
          break;
        case 'fallbackWidth':
          config.fallbackWidth = toDouble(value);
          break;
        case 'fallbackHeight':
          config.fallbackHeight = toDouble(value);
          break;
        default:
          handleUnknownArg('placeholder', name);
          break;
      }
    }
    return config;
  }
}

class _PlaceholderConfig {
  Color? color;
  double? strokeWidth;
  double? fallbackWidth;
  double? fallbackHeight;
}

Widget _buildPlaceholder(_PlaceholderConfig config) {
  return Placeholder(
    color: config.color ?? const Color(0xFF455A64),
    strokeWidth: config.strokeWidth ?? 2.0,
    fallbackWidth: config.fallbackWidth ?? 120.0,
    fallbackHeight: config.fallbackHeight ?? 80.0,
  );
}
