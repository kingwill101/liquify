import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class ImageTag extends WidgetTagBase with AsyncTag {
  ImageTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    Object? imageValue;
    String? src;
    String? asset;
    Uint8List? bytes;
    ImageFrameBuilder? frameBuilder;
    ImageLoadingBuilder? loadingBuilder;
    ImageErrorWidgetBuilder? errorBuilder;
    String? semanticLabel;
    bool? excludeFromSemantics;
    double? width;
    double? height;
    Color? color;
    Animation<double>? opacity;
    BlendMode? colorBlendMode;
    BoxFit? fit;
    AlignmentGeometry? alignment;
    ImageRepeat? repeat;
    Rect? centerSlice;
    bool? matchTextDirection;
    bool? gaplessPlayback;
    bool? isAntiAlias;
    FilterQuality? filterQuality;
    final namedValues = <String, Object?>{};
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'image':
        case 'provider':
          imageValue = evaluator.evaluate(arg.value);
          break;
        case 'src':
        case 'url':
          src = evaluator.evaluate(arg.value)?.toString();
          break;
        case 'asset':
          asset = evaluator.evaluate(arg.value)?.toString();
          break;
        case 'bytes':
          final value = evaluator.evaluate(arg.value);
          if (value is Uint8List) {
            bytes = value;
          }
          break;
        case 'width':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'height':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'frameBuilder':
          final value = evaluator.evaluate(arg.value);
          if (value is ImageFrameBuilder) {
            frameBuilder = value;
          }
          break;
        case 'loadingBuilder':
          final value = evaluator.evaluate(arg.value);
          if (value is ImageLoadingBuilder) {
            loadingBuilder = value;
          }
          break;
        case 'errorBuilder':
          final value = evaluator.evaluate(arg.value);
          if (value is ImageErrorWidgetBuilder) {
            errorBuilder = value;
          }
          break;
        case 'semanticLabel':
          semanticLabel = evaluator.evaluate(arg.value)?.toString();
          break;
        case 'excludeFromSemantics':
          excludeFromSemantics = toBool(evaluator.evaluate(arg.value));
          break;
        case 'color':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'opacity':
          final value = evaluator.evaluate(arg.value);
          if (value is Animation<double>) {
            opacity = value;
          } else if (value is num) {
            opacity = AlwaysStoppedAnimation(value.toDouble());
          }
          break;
        case 'colorBlendMode':
          colorBlendMode = parseBlendMode(evaluator.evaluate(arg.value));
          break;
        case 'fit':
          fit = parseBoxFit(evaluator.evaluate(arg.value));
          break;
        case 'alignment':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'repeat':
          repeat = parseImageRepeat(evaluator.evaluate(arg.value));
          break;
        case 'centerSlice':
          final value = evaluator.evaluate(arg.value);
          if (value is Rect) {
            centerSlice = value;
          }
          break;
        case 'matchTextDirection':
          matchTextDirection = toBool(evaluator.evaluate(arg.value));
          break;
        case 'gaplessPlayback':
          gaplessPlayback = toBool(evaluator.evaluate(arg.value));
          break;
        case 'isAntiAlias':
          isAntiAlias = toBool(evaluator.evaluate(arg.value));
          break;
        case 'filterQuality':
          filterQuality = parseFilterQuality(evaluator.evaluate(arg.value));
          break;
        default:
          handleUnknownArg('image', name);
          break;
      }
    }
    width = resolvePropertyValue<double?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'width',
      parser: toDouble,
    );
    height = resolvePropertyValue<double?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'height',
      parser: toDouble,
    );
    color = resolvePropertyValue<Color?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'color',
      parser: parseColor,
    );
    alignment = resolvePropertyValue<AlignmentGeometry?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'alignment',
      parser: parseAlignmentGeometry,
    );
    buffer.write(
      _buildImage(
        imageValue: imageValue,
        src: src,
        asset: asset,
        bytes: bytes,
        frameBuilder: frameBuilder,
        loadingBuilder: loadingBuilder,
        errorBuilder: errorBuilder,
        semanticLabel: semanticLabel,
        excludeFromSemantics: excludeFromSemantics,
        width: width,
        height: height,
        color: color,
        opacity: opacity,
        colorBlendMode: colorBlendMode,
        fit: fit,
        alignment: alignment,
        repeat: repeat,
        centerSlice: centerSlice,
        matchTextDirection: matchTextDirection,
        gaplessPlayback: gaplessPlayback,
        isAntiAlias: isAntiAlias,
        filterQuality: filterQuality,
      ),
    );
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    Object? imageValue;
    String? src;
    String? asset;
    Uint8List? bytes;
    ImageFrameBuilder? frameBuilder;
    ImageLoadingBuilder? loadingBuilder;
    ImageErrorWidgetBuilder? errorBuilder;
    String? semanticLabel;
    bool? excludeFromSemantics;
    double? width;
    double? height;
    Color? color;
    Animation<double>? opacity;
    BlendMode? colorBlendMode;
    BoxFit? fit;
    AlignmentGeometry? alignment;
    ImageRepeat? repeat;
    Rect? centerSlice;
    bool? matchTextDirection;
    bool? gaplessPlayback;
    bool? isAntiAlias;
    FilterQuality? filterQuality;
    final namedValues = <String, Object?>{};
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'image':
        case 'provider':
          imageValue = evaluator.evaluate(arg.value);
          break;
        case 'src':
        case 'url':
          src = evaluator.evaluate(arg.value)?.toString();
          break;
        case 'asset':
          asset = evaluator.evaluate(arg.value)?.toString();
          break;
        case 'bytes':
          final value = evaluator.evaluate(arg.value);
          if (value is Uint8List) {
            bytes = value;
          }
          break;
        case 'width':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'height':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'frameBuilder':
          final value = evaluator.evaluate(arg.value);
          if (value is ImageFrameBuilder) {
            frameBuilder = value;
          }
          break;
        case 'loadingBuilder':
          final value = evaluator.evaluate(arg.value);
          if (value is ImageLoadingBuilder) {
            loadingBuilder = value;
          }
          break;
        case 'errorBuilder':
          final value = evaluator.evaluate(arg.value);
          if (value is ImageErrorWidgetBuilder) {
            errorBuilder = value;
          }
          break;
        case 'semanticLabel':
          semanticLabel = evaluator.evaluate(arg.value)?.toString();
          break;
        case 'excludeFromSemantics':
          excludeFromSemantics = toBool(evaluator.evaluate(arg.value));
          break;
        case 'color':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'opacity':
          final value = evaluator.evaluate(arg.value);
          if (value is Animation<double>) {
            opacity = value;
          } else if (value is num) {
            opacity = AlwaysStoppedAnimation(value.toDouble());
          }
          break;
        case 'colorBlendMode':
          colorBlendMode = parseBlendMode(evaluator.evaluate(arg.value));
          break;
        case 'fit':
          fit = parseBoxFit(evaluator.evaluate(arg.value));
          break;
        case 'alignment':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'repeat':
          repeat = parseImageRepeat(evaluator.evaluate(arg.value));
          break;
        case 'centerSlice':
          final value = evaluator.evaluate(arg.value);
          if (value is Rect) {
            centerSlice = value;
          }
          break;
        case 'matchTextDirection':
          matchTextDirection = toBool(evaluator.evaluate(arg.value));
          break;
        case 'gaplessPlayback':
          gaplessPlayback = toBool(evaluator.evaluate(arg.value));
          break;
        case 'isAntiAlias':
          isAntiAlias = toBool(evaluator.evaluate(arg.value));
          break;
        case 'filterQuality':
          filterQuality = parseFilterQuality(evaluator.evaluate(arg.value));
          break;
        default:
          handleUnknownArg('image', name);
          break;
      }
    }
    width = resolvePropertyValue<double?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'width',
      parser: toDouble,
    );
    height = resolvePropertyValue<double?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'height',
      parser: toDouble,
    );
    color = resolvePropertyValue<Color?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'color',
      parser: parseColor,
    );
    alignment = resolvePropertyValue<AlignmentGeometry?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'alignment',
      parser: parseAlignmentGeometry,
    );
    buffer.write(
      _buildImage(
        imageValue: imageValue,
        src: src,
        asset: asset,
        bytes: bytes,
        frameBuilder: frameBuilder,
        loadingBuilder: loadingBuilder,
        errorBuilder: errorBuilder,
        semanticLabel: semanticLabel,
        excludeFromSemantics: excludeFromSemantics,
        width: width,
        height: height,
        color: color,
        opacity: opacity,
        colorBlendMode: colorBlendMode,
        fit: fit,
        alignment: alignment,
        repeat: repeat,
        centerSlice: centerSlice,
        matchTextDirection: matchTextDirection,
        gaplessPlayback: gaplessPlayback,
        isAntiAlias: isAntiAlias,
        filterQuality: filterQuality,
      ),
    );
  }
}

Widget _buildImage({
  required Object? imageValue,
  required String? src,
  required String? asset,
  required Uint8List? bytes,
  required ImageFrameBuilder? frameBuilder,
  required ImageLoadingBuilder? loadingBuilder,
  required ImageErrorWidgetBuilder? errorBuilder,
  required String? semanticLabel,
  required bool? excludeFromSemantics,
  required double? width,
  required double? height,
  required Color? color,
  required Animation<double>? opacity,
  required BlendMode? colorBlendMode,
  required BoxFit? fit,
  required AlignmentGeometry? alignment,
  required ImageRepeat? repeat,
  required Rect? centerSlice,
  required bool? matchTextDirection,
  required bool? gaplessPlayback,
  required bool? isAntiAlias,
  required FilterQuality? filterQuality,
}) {
  ImageProvider? provider;
  if (imageValue is ImageProvider) {
    provider = imageValue;
  } else if (src != null && src.isNotEmpty) {
    provider = NetworkImage(src);
  } else if (asset != null && asset.isNotEmpty) {
    provider = AssetImage(asset);
  } else if (bytes != null) {
    provider = MemoryImage(bytes);
  }
  if (provider == null) {
    return const SizedBox.shrink();
  }
  return Image(
    image: provider,
    frameBuilder: frameBuilder,
    loadingBuilder: loadingBuilder,
    errorBuilder: errorBuilder,
    semanticLabel: semanticLabel,
    excludeFromSemantics: excludeFromSemantics ?? false,
    width: width,
    height: height,
    color: color,
    opacity: opacity,
    colorBlendMode: colorBlendMode,
    fit: fit,
    alignment: alignment ?? Alignment.center,
    repeat: repeat ?? ImageRepeat.noRepeat,
    centerSlice: centerSlice,
    matchTextDirection: matchTextDirection ?? false,
    gaplessPlayback: gaplessPlayback ?? false,
    isAntiAlias: isAntiAlias ?? false,
    filterQuality: filterQuality ?? FilterQuality.medium,
  );
}
