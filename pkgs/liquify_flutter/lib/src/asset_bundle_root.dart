import 'dart:io';

import 'package:flutter/services.dart';
import 'package:liquify/liquify.dart';

class AssetBundleRoot implements Root {
  AssetBundleRoot._(
    this._templates, {
    required this.bundle,
    required this.basePath,
    List<String>? extensions,
    this.throwOnMissing = false,
  }) : _extensions = extensions ?? const ['.liquid', '.html'];

  final AssetBundle bundle;
  final String basePath;
  final bool throwOnMissing;
  final List<String> _extensions;
  final Map<String, String> _templates;

  static Future<AssetBundleRoot> load({
    AssetBundle? bundle,
    String basePath = 'assets',
    List<String>? extensions,
    bool throwOnMissing = false,
  }) async {
    final resolvedBundle = bundle ?? rootBundle;
    final manifest = await AssetManifest.loadFromAssetBundle(resolvedBundle);
    final templates = <String, String>{};
    final normalizedBase = _normalizeBase(basePath);
    final exts = extensions ?? const ['.liquid', '.html'];

    for (final assetPath in manifest.listAssets()) {
      if (!_matchesBase(assetPath, normalizedBase)) {
        continue;
      }
      if (!exts.any((ext) => assetPath.endsWith(ext))) {
        continue;
      }
      final content = await resolvedBundle.loadString(assetPath);
      templates[assetPath] = content;
      final relPath = _stripBase(assetPath, normalizedBase);
      templates[relPath] = content;
    }

    return AssetBundleRoot._(
      templates,
      bundle: resolvedBundle,
      basePath: normalizedBase,
      extensions: exts,
      throwOnMissing: throwOnMissing,
    );
  }

  static Future<AssetBundleRoot> loadFromDirectory({
    required String directory,
    String basePath = '',
    List<String>? extensions,
    bool throwOnMissing = false,
  }) async {
    final dir = Directory(directory);
    if (!dir.existsSync()) {
      if (throwOnMissing) {
        throw FileSystemException('Directory not found', directory);
      }
      return AssetBundleRoot._(
        const {},
        bundle: rootBundle,
        basePath: _normalizeBase(basePath),
        extensions: extensions ?? const ['.liquid', '.html'],
        throwOnMissing: throwOnMissing,
      );
    }
    final exts = extensions ?? const ['.liquid', '.html'];
    final templates = <String, String>{};
    final normalizedBase = _normalizeBase(basePath);
    final basePathAbs = dir.absolute.path;
    final prefix = basePathAbs.endsWith(Platform.pathSeparator)
        ? basePathAbs
        : '$basePathAbs${Platform.pathSeparator}';
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final path = entity.path;
      if (!exts.any((ext) => path.endsWith(ext))) {
        continue;
      }
      final content = await entity.readAsString();
      final relPath = path.startsWith(prefix)
          ? path.substring(prefix.length)
          : path;
      final normalizedRel = relPath.replaceAll('\\', '/');
      templates[normalizedRel] = content;
      if (normalizedBase.isNotEmpty) {
        templates['$normalizedBase/$normalizedRel'] = content;
      }
    }
    return AssetBundleRoot._(
      templates,
      bundle: rootBundle,
      basePath: normalizedBase,
      extensions: exts,
      throwOnMissing: throwOnMissing,
    );
  }

  @override
  Source resolve(String relPath) {
    final normalized = _normalizePath(relPath);
    final resolved = _resolvePath(normalized);
    if (resolved != null) {
      return Source(null, resolved, this);
    }
    if (throwOnMissing) {
      throw TemplateNotFoundException(relPath);
    }
    return Source(null, '', this);
  }

  @override
  Future<Source> resolveAsync(String relPath) async {
    return Future.value(resolve(relPath));
  }

  String? _resolvePath(String path) {
    if (_templates.containsKey(path)) {
      return _templates[path];
    }
    if (_hasExtension(path)) {
      return null;
    }
    for (final ext in _extensions) {
      final withExt = '$path$ext';
      if (_templates.containsKey(withExt)) {
        return _templates[withExt];
      }
    }
    return null;
  }

  static String _normalizeBase(String value) {
    var base = value.trim();
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return base;
  }

  static bool _matchesBase(String assetPath, String basePath) {
    if (basePath.isEmpty) {
      return true;
    }
    return assetPath.startsWith('$basePath/');
  }

  static String _stripBase(String assetPath, String basePath) {
    if (basePath.isEmpty) {
      return assetPath;
    }
    final prefix = '$basePath/';
    if (assetPath.startsWith(prefix)) {
      return assetPath.substring(prefix.length);
    }
    return assetPath;
  }

  static String _normalizePath(String value) {
    var normalized = value.replaceAll('\\', '/').trim();
    if (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }
    return normalized;
  }

  static bool _hasExtension(String path) {
    final lastSlash = path.lastIndexOf('/');
    final lastDot = path.lastIndexOf('.');
    return lastDot > lastSlash;
  }
}
