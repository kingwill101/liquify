import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class AvatarTag extends WidgetTagBase with AsyncTag {
  AvatarTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    buffer.write(_buildAvatar(config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    buffer.write(_buildAvatar(config));
  }

  _AvatarConfig _parseConfig(Evaluator evaluator) {
    final config = _AvatarConfig();
    final namedValues = <String, Object?>{};
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'text':
        case 'label':
        case 'value':
          config.text = value?.toString();
          break;
        case 'icon':
        case 'name':
          config.icon = resolveIcon({'name': value});
          break;
        case 'image':
        case 'asset':
        case 'src':
        case 'url':
          config.image = value?.toString();
          break;
        case 'backgroundColor':
        case 'background':
          config.backgroundColor = parseColor(value);
          break;
        case 'foregroundColor':
        case 'foreground':
          config.foregroundColor = parseColor(value);
          break;
        case 'radius':
          config.radius = toDouble(value);
          break;
        case 'minRadius':
          config.minRadius = toDouble(value);
          break;
        case 'maxRadius':
          config.maxRadius = toDouble(value);
          break;
        case 'child':
          if (value is Widget) {
            config.child = value;
          }
          namedValues[name] = value;
          break;
        default:
          handleUnknownArg('avatar', name);
          break;
      }
    }
    final resolvedChild = resolvePropertyValue<Widget?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'child',
      parser: (value) => value is Widget ? value : null,
    );
    if (resolvedChild != null) {
      config.child = resolvedChild;
    }
    return config;
  }
}

class _AvatarConfig {
  String? text;
  IconData? icon;
  String? image;
  Color? backgroundColor;
  Color? foregroundColor;
  double? radius;
  double? minRadius;
  double? maxRadius;
  Widget? child;
}

Widget _buildAvatar(_AvatarConfig config) {
  ImageProvider? imageProvider;
  if (config.image != null && config.image!.trim().isNotEmpty) {
    final src = config.image!.trim();
    imageProvider = src.startsWith('http')
        ? NetworkImage(src)
        : AssetImage(src) as ImageProvider;
  }

  Widget? child = config.child;
  if (child == null) {
    if (config.text != null && config.text!.trim().isNotEmpty) {
      child = Text(config.text!.trim());
    } else if (config.icon != null) {
      child = Icon(config.icon);
    }
  }

  return CircleAvatar(
    backgroundColor: config.backgroundColor,
    foregroundColor: config.foregroundColor,
    radius: config.radius,
    minRadius: config.minRadius,
    maxRadius: config.maxRadius,
    backgroundImage: imageProvider,
    child: child,
  );
}
