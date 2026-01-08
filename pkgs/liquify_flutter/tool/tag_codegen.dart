import 'dart:io';

import 'package:yaml/yaml.dart';

class TagSpec {
  TagSpec({
    required this.tag,
    required this.widget,
    required this.className,
    required this.properties,
    required this.children,
    required this.imports,
  });

  final String tag;
  final String widget;
  final String className;
  final List<PropertySpec> properties;
  final ChildSpec? children;
  final List<String> imports;
}

class PropertySpec {
  PropertySpec({
    required this.name,
    required this.type,
    required this.required,
    required this.defaultValue,
    required this.parser,
    required this.aliases,
  });

  final String name;
  final String type;
  final bool required;
  final String? defaultValue;
  final String? parser;
  final List<String> aliases;
}

class ChildSpec {
  ChildSpec({required this.kind, required this.fallback});

  final String kind;
  final String fallback;
}

void main(List<String> args) {
  final tagFilter = <String>{};
  final specFilter = <String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--tags' && i + 1 < args.length) {
      tagFilter.addAll(_splitList(args[++i]));
      continue;
    }
    if (arg == '--specs' && i + 1 < args.length) {
      specFilter.addAll(_splitList(args[++i]));
      continue;
    }
  }

  final specFiles = specFilter.isNotEmpty
      ? specFilter.map((path) => File(path)).toList()
      : _defaultSpecFiles();

  var specs = <TagSpec>[];
  for (final file in specFiles) {
    specs.addAll(_loadSpecFile(file));
  }
  if (tagFilter.isNotEmpty) {
    specs = specs.where((spec) => tagFilter.contains(spec.tag)).toList();
  }
  specs.sort((a, b) => a.tag.compareTo(b.tag));

  if (specs.isEmpty) {
    stderr.writeln('No specs matched.');
    exit(1);
  }

  for (final spec in specs) {
    final outPath = 'lib/src/tags/${spec.tag}.dart';
    _writeFile(outPath, _renderTag(spec));
    _writeFile(
      'test/generated/${spec.tag}_test.dart',
      _renderTest(spec),
    );
  }

  _writeFile('lib/src/generated_tags.dart', _renderGeneratedExports(specs));
  _writeFile(
    'lib/src/generated_tag_registry.dart',
    _renderGeneratedRegistry(specs),
  );
}

List<String> _splitList(String raw) {
  return raw
      .split(',')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList();
}

List<File> _defaultSpecFiles() {
  final dir = Directory('tool/tag_specs');
  if (!dir.existsSync()) {
    return const [];
  }
  return dir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.yaml'))
      .toList();
}

List<TagSpec> _loadSpecFile(File file) {
  final raw = loadYaml(file.readAsStringSync());
  if (raw == null) {
    return const [];
  }
  if (raw is YamlList) {
    return raw.map((entry) {
      if (entry is! YamlMap) {
        throw Exception('Spec ${file.path} has invalid list entry.');
      }
      return _loadSpec(entry, file.path);
    }).toList();
  }
  if (raw is YamlMap) {
    return [_loadSpec(raw, file.path)];
  }
  throw Exception('Spec ${file.path} has invalid YAML root.');
}

TagSpec _loadSpec(YamlMap raw, String sourcePath) {
  final tag = raw['tag']?.toString();
  final widget = raw['widget']?.toString();
  if (tag == null || widget == null) {
    throw Exception('Spec $sourcePath missing required fields.');
  }
  final className = raw['className']?.toString() ?? '${widget}Tag';
  final importsRaw = raw['imports'] as YamlList?;
  final imports = importsRaw
          ?.map((entry) => entry.toString())
          .toList() ??
      const <String>[];

  final childrenRaw = raw['children'] as YamlMap?;
  ChildSpec? children;
  if (childrenRaw != null) {
    children = ChildSpec(
      kind: childrenRaw['kind']?.toString() ?? 'none',
      fallback: childrenRaw['fallback']?.toString() ?? 'none',
    );
  }

  final properties = <PropertySpec>[];
  final propsRaw = raw['properties'] as YamlList?;
  if (propsRaw != null) {
    for (final entry in propsRaw) {
      final map = entry as YamlMap;
      final name = map['name']?.toString();
      final type = map['type']?.toString();
      if (name == null || type == null) {
        throw Exception('Spec $sourcePath has invalid property entry.');
      }
      final required = map['required'] == true;
      final aliasesRaw = map['aliases'] as YamlList?;
      final defaultValue = _formatDefault(map['default']);
      final parser = map['parser']?.toString();
      final aliases = aliasesRaw
              ?.map((alias) => alias.toString())
              .toList() ??
          const <String>[];
      properties.add(
        PropertySpec(
          name: name,
          type: type,
          required: required,
          defaultValue: defaultValue,
          parser: parser,
          aliases: aliases,
        ),
      );
    }
  }

  return TagSpec(
    tag: tag,
    widget: widget,
    className: className,
    properties: properties,
    children: children,
    imports: imports,
  );
}

String _renderTag(TagSpec spec) {
  final buffer = StringBuffer();
  final importSet = <String>{};
  importSet.addAll(spec.imports);
  if (!importSet.any(
    (value) => value.contains('package:flutter/material.dart') ||
        value.contains('package:flutter/widgets.dart'),
  )) {
    importSet.add('package:flutter/widgets.dart');
  }
  for (final entry in importSet) {
    buffer.writeln("import '$entry';");
  }
  buffer.writeln("import 'package:liquify/parser.dart';\n");
  buffer.writeln("import 'tag_helpers.dart';");
  buffer.writeln("import 'widget_tag_base.dart';\n");

  buffer.writeln('class ${spec.className} extends WidgetTagBase '
      'with CustomTagParser, AsyncTag {');
  buffer.writeln('  ${spec.className}(super.content, super.filters);\n');

  buffer.writeln('  @override');
  buffer.writeln('  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {');
  buffer.writeln('    final config = _parseConfig(evaluator);');
  buffer.writeln('    final children = captureChildrenSync(evaluator);');
  buffer.writeln('    buffer.write(_build${spec.widget}(config, children));');
  buffer.writeln('  }\n');

  buffer.writeln('  @override');
  buffer.writeln(
      '  Future<dynamic> evaluateWithContextAsync(Evaluator evaluator, Buffer buffer) async {');
  buffer.writeln('    final config = _parseConfig(evaluator);');
  buffer.writeln('    final children = await captureChildrenAsync(evaluator);');
  buffer.writeln('    buffer.write(_build${spec.widget}(config, children));');
  buffer.writeln('  }\n');

  buffer.writeln('  @override');
  buffer.writeln('  Parser parser() {');
  buffer.writeln('    final start = tagStart() &');
  buffer.writeln("        string('${spec.tag}').trim() &");
  buffer.writeln('        ref0(tagContent).optional().trim() &');
  buffer.writeln('        ref0(filter).star().trim() &');
  buffer.writeln('        tagEnd();');
  buffer.writeln(
      "    final endTag = tagStart() & string('end${spec.tag}').trim() & tagEnd();");
  buffer.writeln(
      '    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {');
  buffer.writeln(
      '      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);');
  buffer.writeln('      final filters = (values[3] as List).cast<Filter>();');
  buffer.writeln('      final nonFilterContent =');
  buffer.writeln('          content.where((node) => node is! Filter).toList();');
  buffer.writeln('      return Tag(');
  buffer.writeln("        '${spec.tag}',");
  buffer.writeln('        nonFilterContent,');
  buffer.writeln('        filters: filters,');
  buffer.writeln('        body: values[5].cast<ASTNode>(),');
  buffer.writeln('      );');
  buffer.writeln('    });');
  buffer.writeln('  }\n');

  buffer.writeln('  _${spec.widget}Config _parseConfig(Evaluator evaluator) {');
  buffer.writeln('    final config = _${spec.widget}Config();');
  buffer.writeln('    for (final arg in namedArgs) {');
  buffer.writeln('      final name = arg.identifier.name;');
  buffer.writeln('      final value = evaluator.evaluate(arg.value);');
  buffer.writeln('      switch (name) {');
  for (final prop in spec.properties) {
    buffer.writeln("        case '${prop.name}':");
    for (final alias in prop.aliases) {
      buffer.writeln("        case '$alias':");
    }
    buffer.writeln(
        '          config.${prop.name} = ${_parseExpression(prop, 'value')};');
    buffer.writeln('          break;');
  }
  buffer.writeln('        default:');
  buffer.writeln("          handleUnknownArg('${spec.tag}', name);");
  buffer.writeln('          break;');
  buffer.writeln('      }');
  buffer.writeln('    }');
  for (final prop in spec.properties.where((p) => p.required)) {
    buffer.writeln('    if (config.${prop.name} == null) {');
    buffer.writeln(
        "      throw Exception('${spec.tag} tag requires \"${prop.name}\"');");
    buffer.writeln('    }');
  }
  buffer.writeln('    return config;');
  buffer.writeln('  }');
  buffer.writeln('}');

  buffer.writeln('\nclass _${spec.widget}Config {');
  for (final prop in spec.properties) {
    buffer.writeln('  ${_dartType(prop.type)}? ${prop.name};');
  }
  buffer.writeln('}\n');

  buffer.writeln(
      'Widget _build${spec.widget}(_${spec.widget}Config config, List<Widget> children) {');
  final childSpec = spec.children;
  if (childSpec != null && childSpec.kind != 'none') {
    buffer.writeln('  final child = children.isNotEmpty');
    buffer.writeln('      ? wrapChildren(children)');
    buffer.writeln('      : ${_childFallback(childSpec)};');
  }
  buffer.writeln('  return ${spec.widget}(');
  for (final prop in spec.properties) {
    var valueExpr = 'config.${prop.name}';
    if (prop.defaultValue != null) {
      valueExpr = '$valueExpr ?? ${prop.defaultValue}';
    } else if (prop.required) {
      valueExpr = '$valueExpr!';
    }
    buffer.writeln('    ${prop.name}: $valueExpr,');
  }
  if (childSpec != null && childSpec.kind != 'none') {
    buffer.writeln('    child: child,');
  }
  buffer.writeln('  );');
  buffer.writeln('}');

  return buffer.toString();
}

String _renderGeneratedExports(List<TagSpec> specs) {
  final buffer = StringBuffer();
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.');
  buffer.writeln('// Run: dart run tool/tag_codegen.dart\n');
  for (final spec in specs) {
    buffer.writeln(
        "export 'tags/${spec.tag}.dart' show ${spec.className};");
  }
  return buffer.toString();
}

String _renderGeneratedRegistry(List<TagSpec> specs) {
  final buffer = StringBuffer();
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.');
  buffer.writeln('// Run: dart run tool/tag_codegen.dart\n');
  buffer.writeln("import 'package:liquify/parser.dart';");
  for (final spec in specs) {
    buffer.writeln("import 'tags/${spec.tag}.dart';");
  }
  buffer.writeln('\nvoid registerGeneratedTags(Environment? environment) {');
  for (final spec in specs) {
    buffer.writeln(
        "  _registerGeneratedTag('${spec.tag}', (content, filters) => ${spec.className}(content, filters), environment);");
  }
  buffer.writeln('}');
  buffer.writeln('\nvoid _registerGeneratedTag(');
  buffer.writeln('  String name,');
  buffer.writeln('  TagCreator creator,');
  buffer.writeln('  Environment? environment,');
  buffer.writeln(') {');
  buffer.writeln('  TagRegistry.register(name, creator);');
  buffer.writeln('  if (environment != null) {');
  buffer.writeln('    environment.registerLocalTag(name, creator);');
  buffer.writeln('  }');
  buffer.writeln('}');
  return buffer.toString();
}

String _renderTest(TagSpec spec) {
  final buffer = StringBuffer();
  buffer.writeln("import 'package:flutter/widgets.dart';");
  buffer.writeln("import 'package:flutter_test/flutter_test.dart';\n");
  buffer.writeln("import '../test_utils.dart';\n");
  buffer.writeln('void main() {');
  buffer.writeln("  testWidgets('${spec.tag} renders', (tester) async {");
  buffer.writeln('    await pumpTemplate(');
  buffer.writeln('      tester,');
  buffer.writeln("      '''");
  buffer.writeln(_testTemplate(spec));
  buffer.writeln("      '''");
  buffer.writeln('    );');
  buffer.writeln('    expect(find.byType(${spec.widget}), findsWidgets);');
  buffer.writeln('  });');
  buffer.writeln('}');
  return buffer.toString();
}

String _testTemplate(TagSpec spec) {
  switch (spec.tag) {
    case 'colored_box':
      return '{% colored_box color: "#FF0000" %}'
          '{% text value: "Sample" %}'
          '{% endcolored_box %}';
    case 'sized_box':
      return '{% sized_box width: 120 height: 80 %}'
          '{% endsized_box %}';
    case 'ignore_pointer':
      return '{% ignore_pointer ignoring: true %}'
          '{% text value: "Sample" %}'
          '{% endignore_pointer %}';
    default:
      return '{% ${spec.tag} %}{% end${spec.tag} %}';
  }
}

String _parseExpression(PropertySpec prop, String valueVar) {
  if (prop.parser != null && prop.parser!.isNotEmpty) {
    return '${prop.parser}($valueVar)';
  }
  switch (prop.type) {
    case 'double':
      return 'toDouble($valueVar)';
    case 'int':
      return 'toInt($valueVar)';
    case 'bool':
      return 'toBool($valueVar)';
    case 'String':
      return '$valueVar?.toString()';
    case 'Color':
      return 'parseColor($valueVar)';
    default:
      return valueVar;
  }
}

String _dartType(String type) {
  return type;
}

String _childFallback(ChildSpec spec) {
  switch (spec.fallback) {
    case 'shrink':
      return 'const SizedBox.shrink()';
    case 'none':
      return 'null';
    default:
      return 'null';
  }
}

String? _formatDefault(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    final escaped = value.replaceAll('\\', '\\\\').replaceAll("'", "\\'");
    return "'$escaped'";
  }
  return value.toString();
}

void _writeFile(String path, String contents) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}
