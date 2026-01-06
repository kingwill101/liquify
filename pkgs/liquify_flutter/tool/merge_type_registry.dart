import 'dart:io';

import 'package:yaml/yaml.dart';

void main(List<String> args) {
  final generatedPath = args.isNotEmpty
      ? args[0]
      : 'tool/type_registry.generated.yaml';
  final overridesPath = args.length > 1
      ? args[1]
      : 'tool/type_registry.overrides.yaml';
  final outputPath = args.length > 2 ? args[2] : 'tool/type_registry.yaml';

  final generatedFile = File(generatedPath);
  if (!generatedFile.existsSync()) {
    stderr.writeln('Missing generated registry file: $generatedPath');
    exit(1);
  }

  final overridesFile = File(overridesPath);
  if (!overridesFile.existsSync()) {
    stderr.writeln('Missing overrides file: $overridesPath');
    exit(1);
  }

  final generatedData = _parseYaml(generatedFile.readAsStringSync());
  final overridesData = _parseYaml(overridesFile.readAsStringSync());

  final generatedTypes = _extractTypes(generatedData);
  final overrideTypes = _extractTypes(overridesData);

  final merged = _mergeTypes(generatedTypes, overrideTypes);
  File(outputPath).writeAsStringSync(_YamlWriter().write({'types': merged}));

  stdout.writeln(
    'Merged ${overrideTypes.length} overrides into ${generatedTypes.length} generated entries -> $outputPath',
  );
}

YamlMap _parseYaml(String content) {
  final data = loadYaml(content);
  if (data is YamlMap) {
    return data;
  }
  return YamlMap();
}

List<Map<String, Object?>> _extractTypes(YamlMap data) {
  final raw = data['types'];
  if (raw is! YamlList) {
    return [];
  }
  final entries = <Map<String, Object?>>[];
  for (final item in raw) {
    if (item is YamlMap) {
      final entry = <String, Object?>{};
      item.nodes.forEach((key, value) {
        entry[key.value.toString()] = _convertYaml(value.value);
      });
      if (entry['name'] is String) {
        entries.add(entry);
      }
    }
  }
  return entries;
}

List<Map<String, Object?>> _mergeTypes(
  List<Map<String, Object?>> generated,
  List<Map<String, Object?>> overrides,
) {
  final merged = <String, Map<String, Object?>>{
    for (final entry in generated)
      entry['name'] as String: Map<String, Object?>.from(entry),
  };
  for (final entry in overrides) {
    final name = entry['name'] as String?;
    if (name == null) {
      continue;
    }
    merged[name] = Map<String, Object?>.from(entry);
  }
  final entries = merged.values.toList()
    ..sort((a, b) =>
        (a['name'] as String).compareTo(b['name'] as String));
  return entries;
}

Object? _convertYaml(Object? value) {
  if (value is YamlMap) {
    final map = <String, Object?>{};
    value.nodes.forEach((key, val) {
      map[key.value.toString()] = _convertYaml(val.value);
    });
    return map;
  }
  if (value is YamlList) {
    return value.map((entry) => _convertYaml(entry)).toList();
  }
  return value;
}

class _YamlWriter {
  String write(Object? value) {
    final buffer = StringBuffer();
    _writeValue(buffer, value, 0);
    if (!buffer.toString().endsWith('\n')) {
      buffer.writeln();
    }
    return buffer.toString();
  }

  void _writeValue(StringBuffer buffer, Object? value, int indent) {
    if (value is List) {
      if (value.isEmpty) {
        buffer.writeln('${_indent(indent)}[]');
        return;
      }
      for (final entry in value) {
        buffer.write('${_indent(indent)}- ');
        _writeInlineOrIndented(buffer, entry, indent + 2);
      }
      return;
    }
    if (value is Map) {
      if (value.isEmpty) {
        buffer.writeln('${_indent(indent)}{}');
        return;
      }
      for (final entry in value.entries) {
        buffer.write('${_indent(indent)}${entry.key}: ');
        _writeInlineOrIndented(buffer, entry.value, indent + 2);
      }
      return;
    }
    buffer.writeln('${_indent(indent)}${_scalar(value)}');
  }

  void _writeInlineOrIndented(
    StringBuffer buffer,
    Object? value,
    int indent,
  ) {
    if (value is Map || value is List) {
      buffer.writeln();
      _writeValue(buffer, value, indent);
    } else {
      buffer.writeln(_scalar(value));
    }
  }

  String _scalar(Object? value) {
    if (value == null) {
      return 'null';
    }
    if (value is bool || value is num) {
      return value.toString();
    }
    final text = value.toString();
    if (text.isEmpty) {
      return "''";
    }
    final escaped = text.replaceAll("'", "''");
    if (RegExp(r'[:\n#]|^\\s|\\s$').hasMatch(text)) {
      return "'$escaped'";
    }
    return text;
  }

  String _indent(int size) => ' ' * size;
}
