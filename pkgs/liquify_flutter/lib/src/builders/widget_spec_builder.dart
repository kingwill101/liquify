import 'dart:collection';
import 'dart:convert';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:yaml/yaml.dart';

class WidgetSpecBuilder implements Builder {
  WidgetSpecBuilder(this.options);

  final BuilderOptions options;

  @override
  Map<String, List<String>> get buildExtensions => const {
    'tool/widgets_to_port.yaml': [
      'tool/tag_specs/generated/widgets.yaml',
      'tool/tag_specs/generated/widgets.report.json',
      'lib/src/generated/widget_tags.dart',
      'lib/src/generated/widget_tag_registry.dart',
      'test/generated/widget_tags_test.dart',
      'lib/src/generated/type_parsers.dart',
      'lib/src/generated/type_parser_aliases.dart',
      'lib/src/generated/type_filters.dart',
      'lib/src/generated/callback_drops.dart',
      'lib/src/generated/type_registry.dart',
      'tool/type_registry.generated.yaml',
      'tool/type_registry.yaml',
    ],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final rawConfig = await buildStep.readAsString(buildStep.inputId);
    final config = _WidgetSpecConfig.parse(rawConfig);
    if (config.widgets.isEmpty) {
      return;
    }

    final baseRegistry = _buildPrimitiveRegistry();

    final libraries = <String, LibraryElement>{};
    for (final uri in config.libraries) {
      final assetId = AssetId.resolve(Uri.parse(uri), from: buildStep.inputId);
      libraries[uri] = await buildStep.resolver.libraryFor(assetId);
    }

    final classIndex = <String, _ResolvedClass>{};
    final enumIndex = <String, _ResolvedEnum>{};
    final typedefIndex = <String, _ResolvedAlias>{};
    libraries.forEach((uri, library) {
      for (final entry in library.exportNamespace.definedNames2.entries) {
        final element = entry.value;
        if (element is ClassElement) {
          final name = element.name;
          if (name != null) {
            classIndex[name] = _ResolvedClass(element, uri);
          }
        }
        if (element is EnumElement) {
          final name = element.name;
          if (name != null) {
            enumIndex[name] = _ResolvedEnum(element, uri);
          }
        }
        if (element is TypeAliasElement) {
          final name = element.name;
          if (name != null) {
            typedefIndex[name] = _ResolvedAlias(element, uri);
          }
        }
      }
      for (final element in library.classes) {
        final name = element.name;
        if (name != null) {
          classIndex[name] = _ResolvedClass(element, uri);
        }
      }
      for (final element in library.enums) {
        final name = element.name;
        if (name != null) {
          enumIndex[name] = _ResolvedEnum(element, uri);
        }
      }
      for (final element in library.typeAliases) {
        final name = element.name;
        if (name != null) {
          typedefIndex[name] = _ResolvedAlias(element, uri);
        }
      }
    });

    final constIndex = _buildConstIndex(classIndex);

    final bootstrapGraph = _scanWidgetTypes(
      config: config,
      classIndex: classIndex,
      enumIndex: enumIndex,
      typedefIndex: typedefIndex,
      registry: baseRegistry,
      constIndex: constIndex,
    );
    final generatedRegistryMaps = _buildRegistryBootstrap(
      typeGraph: bootstrapGraph,
      registry: baseRegistry,
      classIndex: classIndex,
      enumIndex: enumIndex,
      typedefIndex: typedefIndex,
      constIndex: constIndex,
    );
    final generatedRegistry = _registryFromMaps(generatedRegistryMaps);
    final mergedRegistry = _mergeRegistries(baseRegistry, generatedRegistry);

    final specs = <Map<String, Object?>>[];
    final enumParsers = <String, _ResolvedEnum>{};
    final classParsers = <String, _ClassParserSpec>{};
    final callbackDrops = <String, _CallbackDropSpec>{};
    final generatedSpecs = <_GeneratedSpec>[];
    final report = <String, Object?>{'widgets': <Map<String, Object?>>[]};
    final typeGraph = _TypeGraph(
      registry: mergedRegistry,
      classIndex: classIndex,
      enumIndex: enumIndex,
      constIndex: constIndex,
      enumParsers: enumParsers,
      classParsers: classParsers,
      callbackDrops: callbackDrops,
    );

    for (final request in config.widgets) {
      final resolved = classIndex[request.name];
      final classElement = resolved?.element;
      final widgetReport = <String, Object?>{
        'widget': request.name,
        'tag': request.tag,
      };

      if (classElement == null) {
        widgetReport['error'] = 'Class not found in configured libraries.';
        (report['widgets'] as List).add(widgetReport);
        continue;
      }

      final isWidgetClass = _isWidgetType(classElement.thisType);
      final returnType = isWidgetClass ? 'Widget' : request.name;
      final constructor =
          classElement.unnamedConstructor ?? classElement.constructors.first;
      final staticConstNames = classElement.fields
          .where((field) => field.isStatic && field.isConst && !field.isPrivate)
          .map((field) => field.name ?? '')
          .where((name) => name.isNotEmpty)
          .toSet();
      final properties = <Map<String, Object?>>[];
      final generatedProperties = <_GeneratedProperty>[];
      final skipped = <Map<String, String>>[];
      var childKind = 'none';
      var childNullable = true;
      var positionalIndex = 0;
      final widgetImports = <String>{
        request.libraryOverride ?? resolved?.library ?? config.libraries.first,
      };

      for (final param in constructor.formalParameters) {
        final name = param.name;
        if (name == null || name.isEmpty) {
          continue;
        }
        final type = param.type;
        final typeName = _typeDisplayName(type);
        final typeLibrary = _typeLibrary(type);
        final isNullable = type.nullabilitySuffix == NullabilitySuffix.question;
        final rawDefault = param.defaultValueCode;
        final hasDefault =
            rawDefault != null &&
            rawDefault.trim().isNotEmpty &&
            rawDefault.trim() != 'null';
        final defaultValueCode = _resolveDefaultValue(
          param,
          classElement.name ?? request.name,
          staticConstNames,
        );
        final typeLookup = _normalizeTypeName(typeName);
        final registryEntry = mergedRegistry.lookup(
          typeLookup,
          fullTypeName: typeName,
        );

        typeGraph.resolveDartType(type, source: '${request.name}.$name');

        if (registryEntry != null && registryEntry.imports.isNotEmpty) {
          widgetImports.addAll(registryEntry.imports);
        }

        if (!param.isRequiredNamed &&
            !param.isRequiredPositional &&
            hasDefault &&
            defaultValueCode == null &&
            !isNullable) {
          skipped.add({
            'name': name,
            'type': typeName,
            'reason': 'default value not representable',
          });
          continue;
        }
        if (name == 'child' && _isWidgetType(type)) {
          childKind = 'single';
          childNullable = type.nullabilitySuffix == NullabilitySuffix.question;
          continue;
        }
        if (name == 'children' && _isWidgetList(type)) {
          childKind = 'list';
          continue;
        }
        final isPositional = !param.isNamed;
        final position = isPositional ? positionalIndex++ : null;

        String? parserName = registryEntry?.parser;
        var usesEvaluator = registryEntry?.usesEvaluator ?? false;
        if (registryEntry != null && registryEntry.kind == 'enum') {
          if (parserName == null || parserName.isEmpty) {
            final enumName = _baseTypeName(registryEntry.name);
            final resolvedEnum = enumIndex[enumName];
            if (resolvedEnum != null) {
              parserName = _generatedEnumParserName(enumName);
              enumParsers[enumName] = resolvedEnum;
            }
          }
        }

        if (registryEntry != null && registryEntry.kind == 'class') {
          final className = _baseTypeName(registryEntry.name);
          final generatedName = _generatedClassParserName(className);
          if (parserName == null || parserName.isEmpty) {
            parserName = registryEntry.parser;
          }
          if (parserName == generatedName) {
            final spec = classParsers[className];
            if (spec != null) {
              usesEvaluator = spec.usesEvaluator;
            }
          }
        }

        final mapping = registryEntry == null
            ? null
            : _MappedType(
                _sanitizeTypeName(typeLookup),
                parser: parserName,
                usesEvaluator: usesEvaluator,
              );
        if (mapping == null ||
            mapping.parser == null && registryEntry?.kind == 'callback') {
          final skippedEntry = <String, String>{'name': name, 'type': typeName};
          if (typeLibrary != null) {
            skippedEntry['typeLibrary'] = typeLibrary;
          }
          if (registryEntry != null) {
            skippedEntry['registryKind'] = registryEntry.kind;
          }
          if (!isNullable) {
            skippedEntry['nullable'] = 'false';
          }
          if (registryEntry == null) {
            skippedEntry['reason'] = 'missing_registry_entry';
          } else if (registryEntry.kind == 'callback' &&
              mapping?.parser == null) {
            skippedEntry['reason'] = 'callback_missing_parser';
          } else if (registryEntry.kind == 'enum' && mapping?.parser == null) {
            skippedEntry['reason'] = 'enum_missing_parser';
          } else if (registryEntry.kind == 'class' && mapping?.parser == null) {
            skippedEntry['reason'] = 'class_missing_parser';
          } else if (registryEntry.kind == 'wrapper' &&
              mapping?.parser == null) {
            skippedEntry['reason'] = 'wrapper_missing_parser';
          }
          skipped.add(skippedEntry);
          continue;
        }

        final prop = <String, Object?>{'name': name, 'type': mapping.type};
        if (typeLibrary != null) {
          prop['typeLibrary'] = typeLibrary;
        }
        if (isPositional) {
          prop['positionalIndex'] = position;
        }
        if ((isPositional && param.isRequiredPositional) ||
            (!isPositional && param.isRequiredNamed)) {
          prop['required'] = true;
        }
        if (mapping.parser != null) {
          prop['parser'] = mapping.parser!;
        }
        if (mapping.usesEvaluator) {
          prop['usesEvaluator'] = true;
        }
        if (typeLibrary != null) {
          prop['typeLibrary'] = typeLibrary;
        }
        if (!isNullable) {
          prop['nullable'] = false;
        }
        properties.add(prop);
        final parserOutputType =
            registryEntry?.outputType ??
            (registryEntry?.name.isNotEmpty == true
                ? _normalizeTypeName(registryEntry!.name)
                : null);
        generatedProperties.add(
          _GeneratedProperty(
            name: name,
            type: mapping.type,
            required:
                (isPositional && param.isRequiredPositional) ||
                (!isPositional && param.isRequiredNamed),
            positionalIndex: position,
            parser: mapping.parser,
            parserOutputType: parserOutputType,
            typeLibrary: typeLibrary,
            nullable: isNullable,
            defaultValue: defaultValueCode,
            usesEvaluator: mapping.usesEvaluator,
          ),
        );
      }

      properties.sort(
        (a, b) => a['name'].toString().compareTo(b['name'].toString()),
      );
      generatedProperties.sort((a, b) => a.name.compareTo(b.name));

      final spec = <String, Object?>{
        'tag': request.tag,
        'widget': request.name,
        'className': 'Generated${request.name}Tag',
        'returnType': returnType,
        'imports': widgetImports.toList()..sort(),
      };
      if (childKind != 'none') {
        spec['children'] = {
          'kind': childKind,
          'fallback': childKind == 'single'
              ? (childNullable ? 'none' : 'shrink')
              : 'none',
        };
      }
      if (properties.isNotEmpty) {
        spec['properties'] = properties;
      }
      specs.add(spec);

      generatedSpecs.add(
        _GeneratedSpec(
          tag: request.tag,
          widget: request.name,
          className: 'Generated${request.name}Tag',
          returnType: returnType,
          imports: widgetImports.toList()..sort(),
          children: childKind == 'none'
              ? null
              : _GeneratedChild(
                  kind: childKind,
                  fallback: childKind == 'single'
                      ? (childNullable ? 'none' : 'shrink')
                      : 'none',
                ),
          properties: generatedProperties,
        ),
      );

      widgetReport['skipped'] = skipped;
      widgetReport['properties'] = properties;
      (report['widgets'] as List).add(widgetReport);
    }

    for (final entry in mergedRegistry.entries.values) {
      if (entry.kind == 'enum') {
        final enumName = _baseTypeName(entry.name);
        final resolvedEnum = enumIndex[enumName];
        if (resolvedEnum != null) {
          enumParsers[enumName] = resolvedEnum;
        }
        continue;
      }
      if (entry.kind == 'class') {
        final className = _baseTypeName(entry.name);
        final generatedName = _generatedClassParserName(className);
        if (entry.parser == generatedName) {
          typeGraph._ensureClassParserSpec(entry);
        }
      }
    }

    specs.sort((a, b) => a['tag'].toString().compareTo(b['tag'].toString()));
    generatedSpecs.sort((a, b) => a.tag.compareTo(b.tag));

    final resolvedTypes =
        typeGraph.resolved.values.map((entry) => entry.toJson()).toList()..sort(
          (a, b) => a['type'].toString().compareTo(b['type'].toString()),
        );
    final skippedTypes =
        typeGraph.skipped.values.map((entry) => entry.toJson()).toList()..sort(
          (a, b) => a['type'].toString().compareTo(b['type'].toString()),
        );

    report['generatedTags'] = generatedSpecs.map((spec) => spec.tag).toList();
    final callbackDropList = callbackDrops.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    report['generatedDrops'] = callbackDropList
        .map((spec) => _callbackDropClassName(spec.name))
        .toList();
    report['typeGraph'] = {'resolved': resolvedTypes, 'skipped': skippedTypes};

    final usesGeneratedParsers = generatedSpecs.any(
      (spec) => spec.properties.any(
        (prop) => prop.parser?.startsWith('parseGenerated') ?? false,
      ),
    );

    final yamlOutput = _YamlWriter().write(specs);
    final yamlId = AssetId(
      buildStep.inputId.package,
      'tool/tag_specs/generated/widgets.yaml',
    );
    await buildStep.writeAsString(yamlId, yamlOutput);

    final reportId = AssetId(
      buildStep.inputId.package,
      'tool/tag_specs/generated/widgets.report.json',
    );
    await buildStep.writeAsString(
      reportId,
      const JsonEncoder.withIndent('  ').convert(report),
    );

    final generatedRegistryId = AssetId(
      buildStep.inputId.package,
      'lib/src/generated/widget_tag_registry.dart',
    );
    await buildStep.writeAsString(
      generatedRegistryId,
      _renderGeneratedRegistry(generatedSpecs),
    );

    final generatedTestsId = AssetId(
      buildStep.inputId.package,
      'test/generated/widget_tags_test.dart',
    );
    await buildStep.writeAsString(
      generatedTestsId,
      _renderGeneratedTests(generatedSpecs),
    );

    final typeParsersId = AssetId(
      buildStep.inputId.package,
      'lib/src/generated/type_parsers.dart',
    );
    final enumParserList = enumParsers.values.toList()
      ..sort((a, b) => (a.element.name ?? '').compareTo(b.element.name ?? ''));
    final classParserList = classParsers.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final collectionParsers = _collectCollectionParsers(mergedRegistry);
    final wrapperParsers = _collectWrapperParsers(mergedRegistry);
    final generatedParsers = _collectGeneratedParserSets(
      enumParserList,
      classParserList,
      collectionParsers,
      wrapperParsers,
    );
    final missingParsers = _collectMissingParserSpecs(
      mergedRegistry,
      generatedParsers,
    );
    final evaluatorParsers = _expandEvaluatorParsers(
      {
        ...generatedParsers.evaluator,
        ...missingParsers
            .where((parser) => parser.usesEvaluator)
            .map((parser) => parser.name),
      },
      classParserList,
      collectionParsers,
      wrapperParsers,
    );

    final generatedTagId = AssetId(
      buildStep.inputId.package,
      'lib/src/generated/widget_tags.dart',
    );
    await buildStep.writeAsString(
      generatedTagId,
      _renderGeneratedTags(
        generatedSpecs,
        includeTypeParsers: usesGeneratedParsers,
        evaluatorParsers: evaluatorParsers,
      ),
    );
    await buildStep.writeAsString(
      typeParsersId,
      _renderTypeParsers(
        enumParserList,
        classParserList,
        collectionParsers,
        wrapperParsers,
        missingParsers,
        evaluatorParsers,
      ),
    );

    final typeParserAliasesId = AssetId(
      buildStep.inputId.package,
      'lib/src/generated/type_parser_aliases.dart',
    );
    await buildStep.writeAsString(
      typeParserAliasesId,
      _renderParserAliases(mergedRegistry, evaluatorParsers),
    );

    final typeFiltersId = AssetId(
      buildStep.inputId.package,
      'lib/src/generated/type_filters.dart',
    );
    await buildStep.writeAsString(
      typeFiltersId,
      _renderTypeFilters(mergedRegistry, evaluatorParsers),
    );

    final callbackDropsId = AssetId(
      buildStep.inputId.package,
      'lib/src/generated/callback_drops.dart',
    );
    await buildStep.writeAsString(
      callbackDropsId,
      _renderCallbackDrops(callbackDropList),
    );

    final generatedRegistryYamlId = AssetId(
      buildStep.inputId.package,
      'tool/type_registry.generated.yaml',
    );
    await buildStep.writeAsString(
      generatedRegistryYamlId,
      _YamlWriter().write({'types': generatedRegistryMaps}),
    );

    final mergedRegistryId = AssetId(
      buildStep.inputId.package,
      'tool/type_registry.yaml',
    );
    await buildStep.writeAsString(
      mergedRegistryId,
      _YamlWriter().write({'types': _registryToMaps(mergedRegistry)}),
    );

    final generatedTypeRegistryId = AssetId(
      buildStep.inputId.package,
      'lib/src/generated/type_registry.dart',
    );
    await buildStep.writeAsString(
      generatedTypeRegistryId,
      _renderGeneratedTypeRegistry(mergedRegistry, evaluatorParsers),
    );
  }
}

class _WidgetSpecConfig {
  _WidgetSpecConfig({required this.libraries, required this.widgets});

  final List<String> libraries;
  final List<_WidgetRequest> widgets;

  factory _WidgetSpecConfig.parse(String source) {
    final raw = loadYaml(source);
    if (raw is! YamlMap) {
      return _WidgetSpecConfig(libraries: _defaultLibraries, widgets: const []);
    }
    final libraries =
        (raw['libraries'] as YamlList?)
            ?.map((entry) => entry.toString())
            .toList() ??
        _defaultLibraries;
    final widgets = <_WidgetRequest>[];
    final widgetRaw = raw['widgets'];
    if (widgetRaw is YamlList) {
      for (final entry in widgetRaw) {
        if (entry is YamlMap) {
          final name = entry['name']?.toString() ?? entry['widget']?.toString();
          if (name == null) {
            continue;
          }
          widgets.add(
            _WidgetRequest(
              name: name,
              tag: entry['tag']?.toString() ?? _toSnakeCase(name),
              libraryOverride: entry['library']?.toString(),
            ),
          );
        } else {
          final name = entry.toString();
          if (name.trim().isEmpty) {
            continue;
          }
          widgets.add(_WidgetRequest(name: name, tag: _toSnakeCase(name)));
        }
      }
    }
    return _WidgetSpecConfig(libraries: libraries, widgets: widgets);
  }
}

class _WidgetRequest {
  _WidgetRequest({required this.name, required this.tag, this.libraryOverride});

  final String name;
  final String tag;
  final String? libraryOverride;
}

List<_ConstFieldSpec> _buildConstIndex(Map<String, _ResolvedClass> classIndex) {
  final fields = <_ConstFieldSpec>[];
  for (final entry in classIndex.values) {
    final element = entry.element;
    final ownerName = element.name ?? '';
    if (ownerName.isEmpty) {
      continue;
    }
    for (final field in element.fields) {
      if (!field.isStatic || !field.isConst) {
        continue;
      }
      final fieldName = field.name;
      if (fieldName == null || fieldName.isEmpty || fieldName.startsWith('_')) {
        continue;
      }
      fields.add(
        _ConstFieldSpec(
          owner: ownerName,
          name: fieldName,
          type: field.type,
          library: entry.library,
        ),
      );
    }
  }
  return fields;
}

List<_ResolvedClass> _collectConcreteSubtypes(
  ClassElement base,
  Map<String, _ResolvedClass> classIndex,
) {
  final typeSystem = base.library.typeSystem;
  final baseType = base.thisType;
  final matches = <_ResolvedClass>[];
  for (final entry in classIndex.values) {
    final element = entry.element;
    final name = element.name;
    if (name == null ||
        name.isEmpty ||
        name == base.name ||
        name.startsWith('_')) {
      continue;
    }
    if (element.isAbstract) {
      continue;
    }
    if (typeSystem.isAssignableTo(element.thisType, baseType)) {
      matches.add(entry);
    }
  }
  matches.sort((a, b) {
    final aName = a.element.name ?? '';
    final bName = b.element.name ?? '';
    return aName.compareTo(bName);
  });
  return matches;
}

ConstructorElement? _selectNoArgConstructor(ClassElement element) {
  ConstructorElement? fallback;
  for (final constructor in element.constructors) {
    if (constructor.isPrivate) {
      continue;
    }
    final hasRequired = constructor.formalParameters.any(
      (param) => param.isRequiredNamed || param.isRequiredPositional,
    );
    if (hasRequired) {
      continue;
    }
    if ((constructor.name ?? '').isEmpty) {
      return constructor;
    }
    fallback ??= constructor;
  }
  return fallback;
}

_TypeGraph _scanWidgetTypes({
  required _WidgetSpecConfig config,
  required Map<String, _ResolvedClass> classIndex,
  required Map<String, _ResolvedEnum> enumIndex,
  required Map<String, _ResolvedAlias> typedefIndex,
  required _TypeRegistry registry,
  required List<_ConstFieldSpec> constIndex,
}) {
  final enumParsers = <String, _ResolvedEnum>{};
  final classParsers = <String, _ClassParserSpec>{};
  final callbackDrops = <String, _CallbackDropSpec>{};
  final typeGraph = _TypeGraph(
    registry: registry,
    classIndex: classIndex,
    enumIndex: enumIndex,
    constIndex: constIndex,
    enumParsers: enumParsers,
    classParsers: classParsers,
    callbackDrops: callbackDrops,
  );

  for (final request in config.widgets) {
    final resolved = classIndex[request.name];
    final classElement = resolved?.element;
    if (classElement == null) {
      continue;
    }
    final constructor =
        classElement.unnamedConstructor ?? classElement.constructors.first;
    for (final param in constructor.formalParameters) {
      if (!param.isNamed) {
        continue;
      }
      final name = param.name;
      if (name == null || name.isEmpty) {
        continue;
      }
      if ((name == 'child' && _isWidgetType(param.type)) ||
          (name == 'children' && _isWidgetList(param.type))) {
        continue;
      }
      typeGraph.resolveDartType(param.type, source: '${request.name}.$name');
    }
  }
  return typeGraph;
}

class _ResolvedClass {
  _ResolvedClass(this.element, this.library);

  final ClassElement element;
  final String library;
}

class _ResolvedEnum {
  _ResolvedEnum(this.element, this.library);

  final EnumElement element;
  final String library;
}

class _ResolvedAlias {
  _ResolvedAlias(this.element, this.library);

  final TypeAliasElement element;
  final String library;
}

class _ConstFieldSpec {
  _ConstFieldSpec({
    required this.owner,
    required this.name,
    required this.type,
    required this.library,
  });

  final String owner;
  final String name;
  final DartType type;
  final String library;

  String get accessor => '$owner.$name';
}

class _TypeRegistry {
  _TypeRegistry(this.entries, this.aliases);

  final Map<String, _TypeRegistryEntry> entries;
  final Map<String, String> aliases;

  _TypeRegistryEntry? lookup(String normalizedName, {String? fullTypeName}) {
    if (fullTypeName != null) {
      final exact = entries[fullTypeName];
      if (exact != null) {
        return exact;
      }
      final aliasExact = aliases[fullTypeName];
      if (aliasExact != null) {
        return entries[aliasExact];
      }
    }
    final alias = aliases[normalizedName];
    if (alias != null) {
      return entries[alias];
    }
    final entry = entries[normalizedName];
    if (entry != null) {
      return entry;
    }
    final base = _baseTypeName(normalizedName);
    if (base != normalizedName) {
      final aliasBase = aliases[base];
      if (aliasBase != null) {
        return entries[aliasBase];
      }
      return entries[base];
    }
    return null;
  }
}

class _TypeRegistryEntry {
  _TypeRegistryEntry({
    required this.name,
    required this.kind,
    this.parser,
    this.usesEvaluator = false,
    this.outputType,
    this.aliases = const [],
    this.dropSymbols = const [],
    this.imports = const [],
    this.constructor,
    this.fields = const [],
    this.constructors = const [],
  });

  final String name;
  final String kind;
  final String? parser;
  final bool usesEvaluator;
  final String? outputType;
  final List<String> aliases;
  final List<String> dropSymbols;
  final List<String> imports;
  final String? constructor;
  final List<_TypeRegistryField> fields;
  final List<_TypeRegistryConstructor> constructors;
}

class _TypeRegistryField {
  _TypeRegistryField({
    required this.name,
    required this.type,
    this.defaultValue,
    this.required = false,
  });

  final String name;
  final String type;
  final String? defaultValue;
  final bool required;
}

class _TypeRegistryConstructor {
  _TypeRegistryConstructor({
    required this.name,
    this.positional = const [],
    this.named = const [],
  });

  final String name;
  final List<_TypeRegistryField> positional;
  final List<_TypeRegistryField> named;
}

class _CollectionTypeInfo {
  _CollectionTypeInfo({required this.base, required this.elementType});

  final String base;
  final String elementType;
}

class _CollectionParserSpec {
  _CollectionParserSpec({
    required this.name,
    required this.collectionType,
    required this.elementType,
    required this.elementParser,
    required this.usesEvaluator,
    required this.imports,
  });

  final String name;
  final String collectionType;
  final String elementType;
  final String elementParser;
  final bool usesEvaluator;
  final List<String> imports;
}

class _WrapperTypeInfo {
  _WrapperTypeInfo({required this.base, required this.elementType});

  final String base;
  final String elementType;
}

class _WrapperParserSpec {
  _WrapperParserSpec({
    required this.name,
    required this.wrapperType,
    required this.elementType,
    required this.elementParser,
    required this.usesEvaluator,
    required this.imports,
  });

  final String name;
  final String wrapperType;
  final String elementType;
  final String elementParser;
  final bool usesEvaluator;
  final List<String> imports;
}

class _TypeGraphEntry {
  _TypeGraphEntry({
    required this.name,
    required this.kind,
    this.typeLibrary,
    this.parser,
    this.usesEvaluator,
    this.outputType,
    this.reason,
    List<String>? sources,
  }) : sources = sources ?? [];

  final String name;
  final String? kind;
  final String? typeLibrary;
  final String? parser;
  final bool? usesEvaluator;
  final String? outputType;
  final String? reason;
  final List<String> sources;

  void addSource(String source) {
    if (!sources.contains(source)) {
      sources.add(source);
    }
  }

  Map<String, Object?> toJson() {
    final data = <String, Object?>{'type': name};
    if (kind != null) {
      data['kind'] = kind!;
    }
    if (typeLibrary != null) {
      data['typeLibrary'] = typeLibrary!;
    }
    if (parser != null) {
      data['parser'] = parser!;
    }
    if (usesEvaluator != null) {
      data['usesEvaluator'] = usesEvaluator!;
    }
    if (outputType != null) {
      data['output'] = outputType!;
    }
    if (reason != null) {
      data['reason'] = reason!;
    }
    if (sources.isNotEmpty) {
      data['sources'] = sources;
    }
    return data;
  }
}

class _TypeGraph {
  _TypeGraph({
    required this.registry,
    required this.classIndex,
    required this.enumIndex,
    required this.constIndex,
    required this.enumParsers,
    required this.classParsers,
    required this.callbackDrops,
  });

  final _TypeRegistry registry;
  final Map<String, _ResolvedClass> classIndex;
  final Map<String, _ResolvedEnum> enumIndex;
  final List<_ConstFieldSpec> constIndex;
  final Map<String, _ResolvedEnum> enumParsers;
  final Map<String, _ClassParserSpec> classParsers;
  final Map<String, _CallbackDropSpec> callbackDrops;

  final Map<String, _TypeGraphEntry> resolved = {};
  final Map<String, _TypeGraphEntry> skipped = {};

  final Set<String> _buildingClassParsers = {};

  void _ensureIndexedType(DartType type) {
    if (type is! InterfaceType) {
      return;
    }
    final element = type.element;
    final name = element.name;
    if (name == null || name.isEmpty) {
      return;
    }
    final library = _typeLibrary(type) ?? '';
    if (element is EnumElement) {
      enumIndex.putIfAbsent(name, () => _ResolvedEnum(element, library));
      return;
    }
    if (element is ClassElement) {
      classIndex.putIfAbsent(name, () => _ResolvedClass(element, library));
    }
  }

  void resolveDartType(DartType type, {required String source}) {
    _ensureIndexedType(type);
    if (_isWidgetType(type)) {
      final typeName = _normalizeTypeName(_typeDisplayName(type));
      final entry = registry.lookup(typeName, fullTypeName: typeName);
      if (entry != null) {
        resolveTypeName(
          typeName,
          source: source,
          typeLibrary: _typeLibrary(type),
        );
        return;
      }
      _recordSkipped(
        typeName,
        reason: 'widget_type',
        typeLibrary: _typeLibrary(type),
        source: source,
      );
      return;
    }
    if (type is InterfaceType && _isCollectionType(type.element.name)) {
      final typeName = _normalizeTypeName(_typeDisplayName(type));
      resolveTypeName(
        typeName,
        source: source,
        typeLibrary: _typeLibrary(type),
      );
      for (final arg in type.typeArguments) {
        if (!_isWidgetType(arg)) {
          resolveDartType(arg, source: source);
        }
      }
      return;
    }
    if (type is InterfaceType && _isWrapperType(type.element.name)) {
      final typeName = _normalizeTypeName(_typeDisplayName(type));
      resolveTypeName(
        typeName,
        source: source,
        typeLibrary: _typeLibrary(type),
      );
      for (final arg in type.typeArguments) {
        if (!_isWidgetType(arg)) {
          resolveDartType(arg, source: source);
        }
      }
      return;
    }
    if (type is TypeParameterType) {
      final bound = type.bound;
      resolveDartType(bound, source: source);
      return;
    }

    final typeName = _normalizeTypeName(_typeDisplayName(type));
    resolveTypeName(typeName, source: source, typeLibrary: _typeLibrary(type));

    if (type is InterfaceType) {
      for (final arg in type.typeArguments) {
        if (!_isWidgetType(arg)) {
          resolveDartType(arg, source: source);
        }
      }
    }
  }

  void resolveTypeName(
    String typeName, {
    required String source,
    String? typeLibrary,
  }) {
    if (typeName.isEmpty) {
      return;
    }
    final normalized = _normalizeTypeName(typeName);
    final entry = registry.lookup(normalized, fullTypeName: typeName);
    if (entry == null) {
      _recordSkipped(
        normalized,
        reason: 'missing_registry_entry',
        typeLibrary: typeLibrary ?? _lookupTypeLibrary(normalized),
        source: source,
      );
      return;
    }

    _recordResolved(
      entry.name,
      entry,
      typeLibrary: typeLibrary ?? _lookupTypeLibrary(entry.name),
      source: source,
    );

    switch (entry.kind) {
      case 'enum':
        final enumName = _baseTypeName(entry.name);
        final resolvedEnum = enumIndex[enumName];
        if (resolvedEnum != null) {
          enumParsers[enumName] = resolvedEnum;
        }
        break;
      case 'class':
        final className = _baseTypeName(entry.name);
        final generatedName = _generatedClassParserName(className);
        if (entry.parser == generatedName &&
            _ensureClassParserSpec(entry) == null) {
          _recordSkipped(
            entry.name,
            reason: 'class_parser_unresolved',
            typeLibrary: typeLibrary ?? _lookupTypeLibrary(entry.name),
            source: source,
          );
        }
        break;
      case 'callback':
        if (entry.dropSymbols.isNotEmpty) {
          callbackDrops[entry.name] = _CallbackDropSpec(
            name: entry.name,
            type: entry.outputType ?? entry.name,
            symbols: entry.dropSymbols,
            imports: entry.imports,
          );
        }
        break;
      default:
        break;
    }
  }

  _ClassParserSpec? _ensureClassParserSpec(_TypeRegistryEntry entry) {
    final className = _baseTypeName(entry.name);
    final existing = classParsers[className];
    if (existing != null) {
      return existing;
    }
    if (_buildingClassParsers.contains(className)) {
      _recordSkipped(className, reason: 'class_cycle');
      return null;
    }
    _buildingClassParsers.add(className);
    final resolvedClass = classIndex[className];
    final classElement = resolvedClass?.element;
    final constValues = classElement == null
        ? const <_ClassConstValue>[]
        : _buildConstValues(classElement);
    final subtypeParsers = classElement == null
        ? const <_SubtypeParserSpec>[]
        : _collectSubtypeParsers(className, classElement);

    var constructors = <_ClassConstructorSpec>[];
    if (classElement != null) {
      constructors = _buildConstructorSpecsFromElement(className, classElement);
    } else if (entry.constructors.isNotEmpty || entry.fields.isNotEmpty) {
      constructors = _buildConstructorSpecsFromRegistry(className, entry);
    }

    if (constructors.isEmpty && constValues.isEmpty) {
      // Still generate an identity parser so tags can accept existing instances.
      constructors = const [];
    }

    final usesEvaluator =
        constructors.any(
          (ctor) =>
              ctor.positional.any((field) => field.usesEvaluator) ||
              ctor.named.any((field) => field.usesEvaluator),
        ) ||
        subtypeParsers.any((parser) => parser.usesEvaluator);
    final isGeneric = classElement?.typeParameters.isNotEmpty ?? false;

    final spec = _ClassParserSpec(
      name: className,
      constructors: constructors,
      constValues: constValues,
      subtypeParsers: subtypeParsers,
      usesEvaluator: usesEvaluator,
      isGeneric: isGeneric,
      library: _lookupTypeLibrary(className),
    );
    classParsers[className] = spec;
    _buildingClassParsers.remove(className);
    return spec;
  }

  List<_ClassConstructorSpec> _buildConstructorSpecsFromElement(
    String className,
    ClassElement element,
  ) {
    final specs = <_ClassConstructorSpec>[];
    final staticConstNames = element.fields
        .where((field) => field.isStatic && field.isConst && !field.isPrivate)
        .map((field) => field.name ?? '')
        .where((name) => name.isNotEmpty)
        .toSet();
    for (final constructor in element.constructors) {
      if (constructor.isPrivate) {
        continue;
      }
      if (element.isAbstract && !constructor.isFactory) {
        continue;
      }
      final positional = <_ClassParserField>[];
      final named = <_ClassParserField>[];
      var requiredPositional = 0;
      var invalid = false;
      var stopPositional = false;

      for (final param in constructor.formalParameters) {
        final paramName = param.name;
        if (paramName == null || paramName.isEmpty) {
          continue;
        }
        if (param.isPositional) {
          if (stopPositional) {
            continue;
          }
          if (_isWidgetType(param.type) || _isWidgetList(param.type)) {
            if (param.isRequiredPositional) {
              invalid = true;
              break;
            }
            stopPositional = true;
            continue;
          }
          final field = _resolveFieldFromDartType(
            className,
            paramName,
            param.type,
            required: param.isRequiredPositional,
            defaultValue: _qualifyDefaultValue(
              staticConstNames,
              className,
              _normalizeDefaultValue(param.defaultValueCode),
            ),
          );
          if (field == null) {
            if (param.isRequiredPositional) {
              invalid = true;
              break;
            }
            stopPositional = true;
            continue;
          }
          positional.add(field);
          if (param.isRequiredPositional) {
            requiredPositional += 1;
          }
        } else if (param.isNamed) {
          if (_isWidgetType(param.type) || _isWidgetList(param.type)) {
            if (param.isRequiredNamed) {
              invalid = true;
              break;
            }
            continue;
          }
          final field = _resolveFieldFromDartType(
            className,
            paramName,
            param.type,
            required: param.isRequiredNamed,
            defaultValue: _qualifyDefaultValue(
              staticConstNames,
              className,
              _normalizeDefaultValue(param.defaultValueCode),
            ),
          );
          if (field == null) {
            if (param.isRequiredNamed) {
              invalid = true;
              break;
            }
            continue;
          }
          named.add(field);
        }
      }

      if (invalid) {
        continue;
      }

      specs.add(
        _ClassConstructorSpec(
          name: constructor.name ?? '',
          positional: positional,
          named: named,
          requiredPositional: requiredPositional,
        ),
      );
    }
    return specs;
  }

  List<_ClassConstructorSpec> _buildConstructorSpecsFromRegistry(
    String className,
    _TypeRegistryEntry entry,
  ) {
    final specs = <_ClassConstructorSpec>[];
    if (entry.constructors.isNotEmpty) {
      for (final constructor in entry.constructors) {
        final positional = <_ClassParserField>[];
        final named = <_ClassParserField>[];
        var requiredPositional = 0;
        var invalid = false;
        var stopPositional = false;

        for (final field in constructor.positional) {
          if (stopPositional) {
            continue;
          }
          final resolved = _resolveFieldFromRegistry(className, field);
          if (resolved == null) {
            if (field.required) {
              invalid = true;
              break;
            }
            stopPositional = true;
            continue;
          }
          positional.add(resolved);
          if (field.required) {
            requiredPositional += 1;
          }
        }
        if (invalid) {
          continue;
        }
        for (final field in constructor.named) {
          final resolved = _resolveFieldFromRegistry(className, field);
          if (resolved == null) {
            if (field.required) {
              invalid = true;
              break;
            }
            continue;
          }
          named.add(resolved);
        }
        if (invalid) {
          continue;
        }
        specs.add(
          _ClassConstructorSpec(
            name: constructor.name,
            positional: positional,
            named: named,
            requiredPositional: requiredPositional,
          ),
        );
      }
    } else if (entry.fields.isNotEmpty) {
      final named = <_ClassParserField>[];
      var invalid = false;
      for (final field in entry.fields) {
        final resolved = _resolveFieldFromRegistry(className, field);
        if (resolved == null) {
          if (field.required) {
            invalid = true;
            break;
          }
          continue;
        }
        named.add(resolved);
      }
      if (!invalid) {
        specs.add(
          _ClassConstructorSpec(
            name: entry.constructor ?? '',
            positional: const [],
            named: named,
            requiredPositional: 0,
          ),
        );
      }
    }
    return specs;
  }

  _ClassParserField? _resolveFieldFromDartType(
    String className,
    String fieldName,
    DartType fieldType, {
    required bool required,
    required String? defaultValue,
  }) {
    final fieldTypeName = _normalizeTypeName(_typeDisplayName(fieldType));
    resolveDartType(fieldType, source: '$className.$fieldName');
    final normalizedFieldType = _normalizeTypeName(fieldTypeName);
    final fieldEntry = registry.lookup(
      normalizedFieldType,
      fullTypeName: fieldTypeName,
    );
    if (fieldEntry == null) {
      if (required) {
        _recordSkipped(
          className,
          reason: 'class_field_missing_registry',
          source: '$className.$fieldName',
        );
      }
      return null;
    }
    final nullable = fieldType.nullabilitySuffix == NullabilitySuffix.question;
    return _resolveFieldParser(
      className,
      fieldName,
      fieldEntry,
      fieldTypeName: fieldTypeName,
      defaultValue: defaultValue,
      required: required,
      nullable: nullable,
    );
  }

  _ClassParserField? _resolveFieldFromRegistry(
    String className,
    _TypeRegistryField field,
  ) {
    final fieldTypeName = field.type;
    resolveTypeName(fieldTypeName, source: '$className.${field.name}');
    final normalizedFieldType = _normalizeTypeName(fieldTypeName);
    final fieldEntry = registry.lookup(
      normalizedFieldType,
      fullTypeName: fieldTypeName,
    );
    if (fieldEntry == null) {
      if (field.required) {
        _recordSkipped(
          className,
          reason: 'class_field_missing_registry',
          source: '$className.${field.name}',
        );
      }
      return null;
    }
    final nullable =
        fieldTypeName.trim().endsWith('?') ||
        (fieldEntry.outputType?.trim().endsWith('?') ?? false);
    return _resolveFieldParser(
      className,
      field.name,
      fieldEntry,
      fieldTypeName: fieldTypeName,
      defaultValue: field.defaultValue,
      required: field.required,
      nullable: nullable,
    );
  }

  _ClassParserField? _resolveFieldParser(
    String className,
    String fieldName,
    _TypeRegistryEntry fieldEntry, {
    required String fieldTypeName,
    required String? defaultValue,
    required bool required,
    required bool nullable,
  }) {
    var parserName = fieldEntry.parser;
    var fieldUsesEvaluator = fieldEntry.usesEvaluator;
    if (fieldEntry.kind == 'enum' &&
        (parserName == null || parserName.isEmpty)) {
      final enumName = _baseTypeName(fieldEntry.name);
      final resolvedEnum = enumIndex[enumName];
      if (resolvedEnum != null) {
        enumParsers[enumName] = resolvedEnum;
        parserName = _generatedEnumParserName(enumName);
      }
    }
    if (fieldEntry.kind == 'class') {
      final fieldClassName = _baseTypeName(fieldEntry.name);
      final generatedName = _generatedClassParserName(fieldClassName);
      final expectsGenerated =
          parserName == null ||
          parserName.isEmpty ||
          parserName == generatedName;
      if (expectsGenerated) {
        final nestedSpec = _ensureClassParserSpec(fieldEntry);
        if (nestedSpec != null) {
          parserName = generatedName;
          fieldUsesEvaluator = nestedSpec.usesEvaluator;
        }
      }
    }
    if (!fieldUsesEvaluator && parserName == 'parseGeneratedObject') {
      fieldUsesEvaluator = true;
    }

    if (parserName == null || parserName.isEmpty) {
      if (required) {
        _recordSkipped(
          className,
          reason: 'class_field_missing_parser',
          source: '$className.$fieldName',
        );
      }
      return null;
    }

    return _ClassParserField(
      name: fieldName,
      type: _sanitizeTypeName(_normalizeTypeName(fieldTypeName)),
      parserOutputType:
          fieldEntry.outputType ?? _normalizeTypeName(fieldEntry.name),
      parser: parserName,
      usesEvaluator: fieldUsesEvaluator,
      required: required,
      nullable: nullable,
      defaultValue: defaultValue,
    );
  }

  List<_ClassConstValue> _buildConstValues(ClassElement element) {
    final typeSystem = element.library.typeSystem;
    final targetType = element.thisType;
    final candidates = <_ConstFieldSpec>[];
    for (final field in constIndex) {
      if (typeSystem.isAssignableTo(field.type, targetType)) {
        candidates.add(field);
      }
    }
    if (candidates.isEmpty) {
      return const [];
    }
    final shortBuckets = <String, List<_ConstFieldSpec>>{};
    final values = <_ClassConstValue>[];
    final seenKeys = <String>{};
    for (final field in candidates) {
      final fullKey = _normalizeLookupKey(field.accessor);
      if (fullKey.isNotEmpty && !seenKeys.contains(fullKey)) {
        seenKeys.add(fullKey);
        values.add(
          _ClassConstValue(
            key: fullKey,
            expression: field.accessor,
            library: field.library,
          ),
        );
      }
      final shortKey = _normalizeLookupKey(field.name);
      if (shortKey.isNotEmpty) {
        shortBuckets.putIfAbsent(shortKey, () => []).add(field);
      }
    }
    for (final entry in shortBuckets.entries) {
      final bucket = entry.value
        ..sort((a, b) {
          final ownerCompare = a.owner.compareTo(b.owner);
          if (ownerCompare != 0) {
            return ownerCompare;
          }
          return a.name.compareTo(b.name);
        });
      final field = bucket.first;
      final key = entry.key;
      if (!seenKeys.contains(key)) {
        seenKeys.add(key);
        values.add(
          _ClassConstValue(
            key: key,
            expression: field.accessor,
            library: field.library,
          ),
        );
      }
    }

    if (element.isAbstract) {
      final subtypeCandidates = _collectConcreteSubtypes(element, classIndex);
      if (subtypeCandidates.isNotEmpty) {
        final subtypeNames = subtypeCandidates
            .map((entry) => entry.element.name ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
        final keyMap = _buildSubtypeKeyMap(element.name ?? '', subtypeNames);
        for (final entry in subtypeCandidates) {
          final name = entry.element.name ?? '';
          if (name.isEmpty) {
            continue;
          }
          final ctor = _selectNoArgConstructor(entry.element);
          if (ctor == null) {
            continue;
          }
          final ctorName = ctor.name ?? '';
          final call = ctorName.isEmpty ? '$name()' : '$name.$ctorName()';
          final expression = ctor.isConst ? 'const $call' : call;
          final keys = keyMap[name] ?? const <String>[];
          for (final key in keys) {
            if (seenKeys.contains(key)) {
              continue;
            }
            seenKeys.add(key);
            values.add(
              _ClassConstValue(
                key: key,
                expression: expression,
                library: entry.library,
              ),
            );
          }
        }
      }
    }
    values.sort((a, b) => a.key.compareTo(b.key));
    return values;
  }

  List<_SubtypeParserSpec> _collectSubtypeParsers(
    String className,
    ClassElement element,
  ) {
    final typeSystem = element.library.typeSystem;
    final baseType = element.thisType;
    final candidates = <String, _TypeRegistryEntry>{};
    for (final entry in registry.entries.values) {
      if (entry.kind != 'class') {
        continue;
      }
      final candidateName = _baseTypeName(entry.name);
      if (candidateName.isEmpty || candidateName == className) {
        continue;
      }
      final resolved = classIndex[candidateName];
      if (resolved == null || resolved.element.isAbstract) {
        continue;
      }
      if (!typeSystem.isAssignableTo(resolved.element.thisType, baseType)) {
        continue;
      }
      candidates[candidateName] = entry;
    }
    if (candidates.isEmpty) {
      return const [];
    }
    final keyMap = _buildSubtypeKeyMap(className, candidates.keys);
    final specs = <_SubtypeParserSpec>[];
    for (final entry in candidates.entries) {
      final keys = keyMap[entry.key] ?? const <String>[];
      if (keys.isEmpty) {
        continue;
      }
      final parserName =
          entry.value.parser ?? _generatedClassParserName(entry.key);
      var usesEvaluator = entry.value.usesEvaluator;
      if (entry.value.kind == 'class') {
        final generatedName = _generatedClassParserName(entry.key);
        if (parserName == generatedName) {
          final nestedSpec = _ensureClassParserSpec(entry.value);
          if (nestedSpec != null) {
            usesEvaluator = nestedSpec.usesEvaluator;
          }
        }
      }
      specs.add(
        _SubtypeParserSpec(
          keys: keys,
          parser: parserName,
          usesEvaluator: usesEvaluator,
        ),
      );
    }
    return specs;
  }

  void _recordResolved(
    String typeName,
    _TypeRegistryEntry entry, {
    String? typeLibrary,
    String? source,
  }) {
    final existing = resolved[typeName];
    if (existing != null) {
      if (source != null) {
        existing.addSource(source);
      }
      return;
    }
    final resolvedLibrary =
        typeLibrary ?? (entry.imports.isNotEmpty ? entry.imports.first : null);
    final record = _TypeGraphEntry(
      name: typeName,
      kind: entry.kind,
      typeLibrary: resolvedLibrary,
      parser: entry.parser,
      usesEvaluator: entry.usesEvaluator ? true : null,
      outputType: entry.outputType,
      sources: source == null ? null : [source],
    );
    resolved[typeName] = record;
  }

  void _recordSkipped(
    String typeName, {
    String? reason,
    String? typeLibrary,
    String? source,
  }) {
    final existing = skipped[typeName];
    if (existing != null) {
      if (source != null) {
        existing.addSource(source);
      }
      return;
    }
    skipped[typeName] = _TypeGraphEntry(
      name: typeName,
      kind: null,
      typeLibrary: typeLibrary ?? _lookupTypeLibrary(typeName),
      reason: reason,
      sources: source == null ? null : [source],
    );
  }

  String? _lookupTypeLibrary(String typeName) {
    final base = _baseTypeName(typeName);
    final resolvedClass = classIndex[base];
    if (resolvedClass != null) {
      return resolvedClass.library;
    }
    final resolvedEnum = enumIndex[base];
    if (resolvedEnum != null) {
      return resolvedEnum.library;
    }
    return null;
  }
}

class _GeneratedSpec {
  _GeneratedSpec({
    required this.tag,
    required this.widget,
    required this.className,
    required this.returnType,
    required this.imports,
    required this.properties,
    required this.children,
  });

  final String tag;
  final String widget;
  final String className;
  final String returnType;
  final List<String> imports;
  final List<_GeneratedProperty> properties;
  final _GeneratedChild? children;
}

class _CallbackDropSpec {
  _CallbackDropSpec({
    required this.name,
    required this.type,
    required this.symbols,
    required this.imports,
  });

  final String name;
  final String type;
  final List<String> symbols;
  final List<String> imports;
}

class _ClassParserSpec {
  _ClassParserSpec({
    required this.name,
    required this.constructors,
    required this.constValues,
    required this.subtypeParsers,
    required this.usesEvaluator,
    required this.isGeneric,
    required this.library,
  });

  final String name;
  final List<_ClassConstructorSpec> constructors;
  final List<_ClassConstValue> constValues;
  final List<_SubtypeParserSpec> subtypeParsers;
  final bool usesEvaluator;
  final bool isGeneric;
  final String? library;
}

class _ClassConstructorSpec {
  _ClassConstructorSpec({
    required this.name,
    required this.positional,
    required this.named,
    required this.requiredPositional,
  });

  final String name;
  final List<_ClassParserField> positional;
  final List<_ClassParserField> named;
  final int requiredPositional;
}

class _ClassConstValue {
  _ClassConstValue({
    required this.key,
    required this.expression,
    required this.library,
  });

  final String key;
  final String expression;
  final String library;
}

class _SubtypeParserSpec {
  _SubtypeParserSpec({
    required this.keys,
    required this.parser,
    required this.usesEvaluator,
  });

  final List<String> keys;
  final String parser;
  final bool usesEvaluator;
}

class _ClassParserField {
  _ClassParserField({
    required this.name,
    required this.type,
    required this.parserOutputType,
    required this.parser,
    required this.usesEvaluator,
    required this.required,
    required this.nullable,
    this.defaultValue,
  });

  final String name;
  final String type;
  final String? parserOutputType;
  final String parser;
  final bool usesEvaluator;
  final bool required;
  final bool nullable;
  final String? defaultValue;
}

class _GeneratedProperty {
  _GeneratedProperty({
    required this.name,
    required this.type,
    required this.required,
    required this.positionalIndex,
    required this.parser,
    required this.parserOutputType,
    required this.typeLibrary,
    required this.nullable,
    required this.defaultValue,
    required this.usesEvaluator,
  });

  final String name;
  final String type;
  final bool required;
  final int? positionalIndex;
  final String? parser;
  final String? parserOutputType;
  final String? typeLibrary;
  final bool nullable;
  final String? defaultValue;
  final bool usesEvaluator;

  bool get isPositional => positionalIndex != null;
}

class _GeneratedChild {
  _GeneratedChild({required this.kind, required this.fallback});

  final String kind;
  final String fallback;
}

class _MappedType {
  const _MappedType(this.type, {this.parser, this.usesEvaluator = false});

  final String type;
  final String? parser;
  final bool usesEvaluator;
}

const List<String> _defaultLibraries = [
  'package:flutter/material.dart',
  'package:flutter/widgets.dart',
];

_TypeRegistry _buildPrimitiveRegistry() {
  final entries = <String, _TypeRegistryEntry>{
    'double': _TypeRegistryEntry(
      name: 'double',
      kind: 'primitive',
      parser: 'toDouble',
    ),
    'int': _TypeRegistryEntry(name: 'int', kind: 'primitive', parser: 'toInt'),
    'num': _TypeRegistryEntry(
      name: 'num',
      kind: 'primitive',
      parser: 'toDouble',
    ),
    'bool': _TypeRegistryEntry(
      name: 'bool',
      kind: 'primitive',
      parser: 'toBool',
    ),
    'String': _TypeRegistryEntry(
      name: 'String',
      kind: 'primitive',
      parser: 'toStringValue',
    ),
    'Widget': _TypeRegistryEntry(
      name: 'Widget',
      kind: 'primitive',
      parser: 'resolveWidget',
    ),
    'PreferredSizeWidget': _TypeRegistryEntry(
      name: 'PreferredSizeWidget',
      kind: 'primitive',
      parser: 'parsePreferredSizeWidget',
      outputType: 'Widget',
      imports: const ['package:flutter/widgets.dart'],
    ),
    'MaterialStatesController': _TypeRegistryEntry(
      name: 'MaterialStatesController',
      kind: 'primitive',
      parser: 'parseMaterialStatesController',
      imports: const ['package:flutter/material.dart'],
    ),
    'AsyncCallback': _TypeRegistryEntry(
      name: 'AsyncCallback',
      kind: 'callback',
      parser: 'parseAsyncCallback',
      usesEvaluator: true,
      imports: const ['package:flutter/foundation.dart'],
    ),
    'Map<DismissDirection, double>': _TypeRegistryEntry(
      name: 'Map<DismissDirection, double>',
      kind: 'primitive',
      parser: 'parseDismissThresholds',
      imports: const ['package:flutter/widgets.dart'],
    ),
    'Map<int, TableColumnWidth>': _TypeRegistryEntry(
      name: 'Map<int, TableColumnWidth>',
      kind: 'primitive',
      parser: 'parseTableColumnWidths',
      imports: const ['package:flutter/rendering.dart'],
    ),
    'List<Widget>': _TypeRegistryEntry(
      name: 'List<Widget>',
      kind: 'collection',
    ),
  };
  return _TypeRegistry(entries, const {});
}

_TypeRegistry _mergeRegistries(_TypeRegistry base, _TypeRegistry next) {
  final entries = <String, _TypeRegistryEntry>{...base.entries};
  for (final entry in next.entries.entries) {
    entries.putIfAbsent(entry.key, () => entry.value);
  }
  final aliases = <String, String>{...base.aliases};
  for (final alias in next.aliases.entries) {
    aliases.putIfAbsent(alias.key, () => alias.value);
  }
  return _TypeRegistry(entries, aliases);
}

_TypeRegistry _registryFromYaml(String raw) {
  final parsed = loadYaml(raw);
  if (parsed is! YamlMap) {
    return _TypeRegistry(const {}, const {});
  }
  final typesRaw = parsed['types'];
  if (typesRaw is! YamlList) {
    return _TypeRegistry(const {}, const {});
  }
  final entries = <String, _TypeRegistryEntry>{};
  final aliases = <String, String>{};
  for (final entry in typesRaw) {
    final registryEntry = _registryEntryFromYaml(entry);
    if (registryEntry == null) {
      continue;
    }
    entries[registryEntry.name] = registryEntry;
    for (final alias in registryEntry.aliases) {
      aliases[alias] = registryEntry.name;
    }
  }
  return _TypeRegistry(entries, aliases);
}

_TypeRegistry _registryFromMaps(List<Map<String, Object?>> maps) {
  final entries = <String, _TypeRegistryEntry>{};
  final aliases = <String, String>{};
  for (final entry in maps) {
    final registryEntry = _registryEntryFromMap(entry);
    if (registryEntry == null) {
      continue;
    }
    entries[registryEntry.name] = registryEntry;
    for (final alias in registryEntry.aliases) {
      aliases[alias] = registryEntry.name;
    }
  }
  return _TypeRegistry(entries, aliases);
}

List<Map<String, Object?>> _registryToMaps(_TypeRegistry registry) {
  final entries =
      registry.entries.values
          .map((entry) => _registryEntryToMap(entry))
          .toList()
        ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  return entries;
}

_TypeRegistryEntry? _registryEntryFromYaml(Object? entry) {
  if (entry is! YamlMap) {
    return null;
  }
  final map = <String, Object?>{};
  entry.nodes.forEach((key, value) {
    map[key.value.toString()] = _convertYaml(value.value);
  });
  return _registryEntryFromMap(map);
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

_TypeRegistryEntry? _registryEntryFromMap(Map<String, Object?> entry) {
  final name = entry['name']?.toString();
  final kind = entry['kind']?.toString();
  if (name == null || kind == null) {
    return null;
  }
  final parser = entry['parser']?.toString();
  final usesEvaluator = entry['usesEvaluator'] == true;
  final outputType = entry['output']?.toString();
  final aliasRaw = entry['aliases'];
  final aliasList = aliasRaw is List
      ? aliasRaw.map((alias) => alias.toString()).toList()
      : const <String>[];
  final dropRaw = entry['dropSymbols'];
  final dropSymbols = dropRaw is List
      ? dropRaw.map((symbol) => symbol.toString()).toList()
      : const <String>[];
  final importRaw = entry['imports'];
  final imports = importRaw is List
      ? importRaw.map((item) => item.toString()).toList()
      : const <String>[];
  final constructor = entry['constructor']?.toString();
  final fieldsRaw = entry['fields'];
  final fields = <_TypeRegistryField>[];
  if (fieldsRaw is List) {
    for (final field in fieldsRaw) {
      if (field is! Map) {
        continue;
      }
      final fieldName = field['name']?.toString();
      final fieldType = field['type']?.toString();
      if (fieldName == null || fieldType == null) {
        continue;
      }
      final defaultValue = field['default']?.toString();
      final requiredField = field['required'] == true;
      fields.add(
        _TypeRegistryField(
          name: fieldName,
          type: fieldType,
          defaultValue: defaultValue,
          required: requiredField,
        ),
      );
    }
  }
  final constructorsRaw = entry['constructors'];
  final constructors = <_TypeRegistryConstructor>[];
  if (constructorsRaw is List) {
    for (final constructorEntry in constructorsRaw) {
      if (constructorEntry is! Map) {
        continue;
      }
      final name = constructorEntry['name']?.toString() ?? '';
      final positional = _parseConstructorFields(
        constructorEntry['positional'],
      );
      final named = _parseConstructorFields(constructorEntry['named']);
      constructors.add(
        _TypeRegistryConstructor(
          name: name,
          positional: positional,
          named: named,
        ),
      );
    }
  }
  return _TypeRegistryEntry(
    name: name,
    kind: kind,
    parser: parser,
    usesEvaluator: usesEvaluator,
    outputType: outputType,
    aliases: aliasList,
    dropSymbols: dropSymbols,
    imports: imports,
    constructor: constructor,
    fields: fields,
    constructors: constructors,
  );
}

List<_TypeRegistryField> _parseConstructorFields(Object? raw) {
  if (raw is! List) {
    return const [];
  }
  final fields = <_TypeRegistryField>[];
  for (final entry in raw) {
    if (entry is! Map) {
      continue;
    }
    final fieldName = entry['name']?.toString();
    final fieldType = entry['type']?.toString();
    if (fieldName == null || fieldType == null) {
      continue;
    }
    final defaultValue = entry['default']?.toString();
    final requiredField = entry['required'] == true;
    fields.add(
      _TypeRegistryField(
        name: fieldName,
        type: fieldType,
        defaultValue: defaultValue,
        required: requiredField,
      ),
    );
  }
  return fields;
}

Map<String, Object?> _registryEntryToMap(_TypeRegistryEntry entry) {
  final data = <String, Object?>{'name': entry.name, 'kind': entry.kind};
  if (entry.parser != null) {
    data['parser'] = entry.parser!;
  }
  if (entry.usesEvaluator) {
    data['usesEvaluator'] = true;
  }
  if (entry.outputType != null) {
    data['output'] = entry.outputType;
  }
  if (entry.aliases.isNotEmpty) {
    data['aliases'] = entry.aliases;
  }
  if (entry.dropSymbols.isNotEmpty) {
    data['dropSymbols'] = entry.dropSymbols;
  }
  if (entry.imports.isNotEmpty) {
    data['imports'] = entry.imports;
  }
  if (entry.constructor != null && entry.constructor!.isNotEmpty) {
    data['constructor'] = entry.constructor!;
  }
  if (entry.fields.isNotEmpty) {
    data['fields'] = entry.fields
        .map(
          (field) => <String, Object?>{
            'name': field.name,
            'type': field.type,
            if (field.defaultValue != null) 'default': field.defaultValue,
            if (field.required) 'required': true,
          },
        )
        .toList();
  }
  if (entry.constructors.isNotEmpty) {
    data['constructors'] = entry.constructors
        .map(
          (ctor) => <String, Object?>{
            'name': ctor.name,
            if (ctor.positional.isNotEmpty)
              'positional': ctor.positional
                  .map(
                    (field) => <String, Object?>{
                      'name': field.name,
                      'type': field.type,
                      if (field.defaultValue != null)
                        'default': field.defaultValue,
                      if (field.required) 'required': true,
                    },
                  )
                  .toList(),
            if (ctor.named.isNotEmpty)
              'named': ctor.named
                  .map(
                    (field) => <String, Object?>{
                      'name': field.name,
                      'type': field.type,
                      if (field.defaultValue != null)
                        'default': field.defaultValue,
                      if (field.required) 'required': true,
                    },
                  )
                  .toList(),
          },
        )
        .toList();
  }
  return data;
}

String _normalizeTypeName(String typeName) {
  return typeName.endsWith('?')
      ? typeName.substring(0, typeName.length - 1)
      : typeName;
}

String _normalizeLookupKey(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

List<String> _splitTypeTokens(String value) {
  final cleaned = value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ' ');
  final matches = RegExp(r'[A-Z]?[a-z]+|[0-9]+')
      .allMatches(cleaned)
      .map((match) => match.group(0))
      .whereType<String>()
      .map((token) => token.toLowerCase())
      .where((token) => token.isNotEmpty)
      .toList();
  return matches;
}

Map<String, List<String>> _buildSubtypeKeyMap(
  String baseName,
  Iterable<String> subtypeNames,
) {
  final baseTokens = _splitTypeTokens(baseName).toSet();
  final candidates = <String, List<String>>{};
  final firstTokenCounts = <String, int>{};
  for (final name in subtypeNames) {
    final tokens = _splitTypeTokens(name);
    if (tokens.isEmpty) {
      continue;
    }
    final filtered = tokens
        .where((token) => !baseTokens.contains(token))
        .toList();
    final firstToken = (filtered.isNotEmpty ? filtered.first : tokens.first);
    firstTokenCounts[firstToken] = (firstTokenCounts[firstToken] ?? 0) + 1;
    candidates[name] = filtered.isNotEmpty ? filtered : tokens;
  }

  final usedKeys = <String>{};
  final keyMap = <String, List<String>>{};
  for (final entry in candidates.entries) {
    final name = entry.key;
    final tokens = entry.value;
    final keys = <String>[];

    void addKey(String raw) {
      final key = _normalizeLookupKey(raw);
      if (key.isEmpty || usedKeys.contains(key)) {
        return;
      }
      usedKeys.add(key);
      keys.add(key);
    }

    addKey(name);
    if (name.endsWith(baseName) && name.length > baseName.length) {
      addKey(name.substring(0, name.length - baseName.length));
    }
    if (tokens.isNotEmpty) {
      addKey(tokens.join());
    }
    final firstToken = tokens.first;
    if (firstTokenCounts[firstToken] == 1) {
      addKey(firstToken);
    }
    keyMap[name] = keys;
  }

  return keyMap;
}

String _typeDisplayName(DartType type) {
  String renderType(DartType arg) {
    if (arg is TypeParameterType) {
      final bound = arg.element.bound;
      if (bound != null) {
        return renderType(bound);
      }
      return 'Object?';
    }
    if (arg is InterfaceType) {
      final name = arg.element.name ?? arg.getDisplayString();
      if (arg.typeArguments.isNotEmpty) {
        final args = arg.typeArguments.map(renderType).join(', ');
        final base = '$name<$args>';
        return arg.nullabilitySuffix == NullabilitySuffix.question
            ? '$base?'
            : base;
      }
      return arg.nullabilitySuffix == NullabilitySuffix.question
          ? '$name?'
          : name;
    }
    return arg.getDisplayString(withNullability: true);
  }

  final alias = type.alias;
  if (alias != null) {
    final aliasName = alias.element.name;
    if (aliasName != null && aliasName.isNotEmpty) {
      if (alias.typeArguments.isNotEmpty) {
        final args = alias.typeArguments.map(renderType).join(', ');
        return '$aliasName<$args>';
      }
      return aliasName;
    }
  }
  return renderType(type);
}

String _baseTypeName(String typeName) {
  final index = typeName.indexOf('<');
  if (index == -1) {
    return typeName;
  }
  return typeName.substring(0, index);
}

String? _typeLibrary(DartType type) {
  Element? element;
  if (type is InterfaceType) {
    element = type.element;
  } else if (type is FunctionType) {
    element = type.element;
  } else if (type is TypeParameterType) {
    element = type.element;
  }
  final library = element?.library;
  if (library == null) {
    return null;
  }
  return library.firstFragment.source.uri.toString();
}

String? _normalizeDefaultValue(String? value) {
  if (value == null) {
    return null;
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed == 'null') {
    return null;
  }
  if (RegExp(r'\b_\w').hasMatch(trimmed)) {
    return null;
  }
  return trimmed;
}

String? _resolveDefaultValue(
  FormalParameterElement param,
  String className,
  Set<String> staticConstNames,
) {
  final raw = param.defaultValueCode;
  if (raw == null || raw.trim().isEmpty || raw.trim() == 'null') {
    return null;
  }
  final normalized = _normalizeDefaultValue(raw);
  if (normalized != null) {
    return _qualifyDefaultValue(staticConstNames, className, normalized);
  }
  final literal = _resolvePrivateDefaultLiteral(param, raw);
  if (literal == null) {
    return null;
  }
  return _qualifyDefaultValue(staticConstNames, className, literal);
}

String? _resolvePrivateDefaultLiteral(
  FormalParameterElement param,
  String raw,
) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed == 'null') {
    return null;
  }
  final library = param.library;
  if (library == null) {
    return null;
  }
  VariableElement? variable;
  if (trimmed.contains('.')) {
    final parts = trimmed.split('.');
    if (parts.length == 2) {
      final ownerName = parts.first.trim();
      final memberName = parts.last.trim();
      if (memberName.isNotEmpty) {
        ClassElement? owner;
        for (final element in library.classes) {
          if (element.name == ownerName) {
            owner = element;
            break;
          }
        }
        if (owner != null) {
          for (final field in owner.fields) {
            if (field.isStatic && field.isConst && field.name == memberName) {
              variable = field;
              break;
            }
          }
        }
      }
    }
  } else {
    for (final element in library.topLevelVariables) {
      if (element.isConst && element.name == trimmed) {
        variable = element;
        break;
      }
    }
  }
  if (variable == null) {
    return null;
  }
  final value = variable.computeConstantValue();
  return _dartObjectToLiteral(value);
}

String? _dartObjectToLiteral(DartObject? value) {
  if (value == null || !value.hasKnownValue || value.isNull) {
    return null;
  }
  final boolValue = value.toBoolValue();
  if (boolValue != null) {
    return boolValue ? 'true' : 'false';
  }
  final intValue = value.toIntValue();
  if (intValue != null) {
    return intValue.toString();
  }
  final doubleValue = value.toDoubleValue();
  if (doubleValue != null) {
    return doubleValue.toString();
  }
  final stringValue = value.toStringValue();
  if (stringValue != null) {
    final escaped = stringValue.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
    return "'$escaped'";
  }
  final variable = value.variable;
  if (variable != null) {
    final name = variable.name;
    if (name != null && name.isNotEmpty && !name.startsWith('_')) {
      final enclosing = variable.enclosingElement;
      if (enclosing is ClassElement) {
        return '${enclosing.name}.$name';
      }
      if (enclosing is EnumElement) {
        return '${enclosing.name}.$name';
      }
      return name;
    }
  }
  final invocation = value.constructorInvocation;
  if (invocation != null) {
    final ctor = invocation.constructor;
    final typeName = ctor.enclosingElement.name;
    if (typeName == null || typeName.isEmpty) {
      return null;
    }
    final parts = <String>[];
    for (final positional in invocation.positionalArguments) {
      final literal = _dartObjectToLiteral(positional);
      if (literal == null) {
        return null;
      }
      parts.add(literal);
    }
    for (final entry in invocation.namedArguments.entries) {
      final literal = _dartObjectToLiteral(entry.value);
      if (literal == null) {
        return null;
      }
      parts.add('${entry.key}: $literal');
    }
    final ctorName = ctor.name;
    final ctorSuffix = (ctorName == null || ctorName.isEmpty)
        ? ''
        : '.$ctorName';
    return '$typeName$ctorSuffix(${parts.join(', ')})';
  }
  return null;
}

String? _qualifyDefaultValue(
  Set<String> staticConstNames,
  String className,
  String? value,
) {
  if (value == null || value.isEmpty) {
    return value;
  }
  if (RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(value)) {
    if (staticConstNames.contains(value)) {
      return '$className.$value';
    }
    return value;
  }
  if (staticConstNames.isEmpty) {
    return value;
  }
  var updated = value;
  for (final name in staticConstNames) {
    if (name.isEmpty) {
      continue;
    }
    final pattern = RegExp(r'(?<!\.)\b' + RegExp.escape(name) + r'\b');
    updated = updated.replaceAll(pattern, '$className.$name');
  }
  return updated;
}

bool _isWidgetType(DartType type) {
  final display = type.getDisplayString();
  final normalized = display.endsWith('?')
      ? display.substring(0, display.length - 1)
      : display;
  return normalized == 'Widget' || normalized.endsWith('Widget');
}

bool _isWidgetList(DartType type) {
  if (type is InterfaceType && type.typeArguments.isNotEmpty) {
    final name = type.element.name;
    if (name == 'List' || name == 'Iterable') {
      return _isWidgetType(type.typeArguments.first);
    }
  }
  final display = type.getDisplayString();
  return display.startsWith('List<Widget') ||
      display.startsWith('Iterable<Widget');
}

bool _looksLikeWidgetTypeName(String typeName) {
  final normalized = _normalizeTypeName(typeName);
  if (normalized == 'Widget' || normalized.endsWith('Widget')) {
    return true;
  }
  return normalized.startsWith('List<Widget') ||
      normalized.startsWith('Iterable<Widget');
}

bool _isCollectionType(String? typeName) {
  if (typeName == null) {
    return false;
  }
  return typeName == 'List' ||
      typeName == 'Iterable' ||
      typeName == 'Set' ||
      typeName == 'Map';
}

bool _isWrapperType(String? typeName) {
  if (typeName == null) {
    return false;
  }
  return typeName == 'Animation';
}

String _toSnakeCase(String value) {
  final buffer = StringBuffer();
  for (var i = 0; i < value.length; i++) {
    final char = value[i];
    final isUpper = char.toUpperCase() == char && char.toLowerCase() != char;
    if (isUpper && i > 0) {
      buffer.write('_');
    }
    buffer.write(char.toLowerCase());
  }
  return buffer.toString();
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

  void _writeInlineOrIndented(StringBuffer buffer, Object? value, int indent) {
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
    if (RegExp(r'[:\n#]|^\s|\s$').hasMatch(text)) {
      return "'$escaped'";
    }
    return text;
  }

  String _indent(int size) => ' ' * size;
}

String _renderGeneratedTags(
  List<_GeneratedSpec> specs, {
  required bool includeTypeParsers,
  required Set<String> evaluatorParsers,
}) {
  final buffer = StringBuffer();
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.');
  buffer.writeln('// Generated by widget_spec_builder.');
  buffer.writeln('// ignore_for_file: deprecated_member_use');
  buffer.writeln();

  final importSet = <String>{
    'package:flutter/widgets.dart',
    'package:liquify/parser.dart',
    'package:liquify_flutter/src/tags/tag_helpers.dart',
    'package:liquify_flutter/src/tags/widget_tag_base.dart',
  };
  if (includeTypeParsers) {
    importSet.add('package:liquify_flutter/src/generated/type_parsers.dart');
  }
  for (final spec in specs) {
    importSet.addAll(spec.imports);
  }
  final imports = importSet.toList()..sort();
  if (imports.contains('package:flutter/material.dart')) {
    imports.remove('package:flutter/widgets.dart');
  }
  for (final entry in imports) {
    buffer.writeln("import '$entry';");
  }
  buffer.writeln();

  for (final spec in specs) {
    buffer.writeln(_renderGeneratedTag(spec, evaluatorParsers));
    buffer.writeln();
  }
  return buffer.toString();
}

String _renderGeneratedTag(_GeneratedSpec spec, Set<String> evaluatorParsers) {
  final buffer = StringBuffer();
  final className = spec.className;
  final configName = '_${className}Config';
  final buildName = '_build${className}Widget';
  final supportsChildren = spec.children != null;

  buffer.writeln(
    'class $className extends WidgetTagBase '
    'with ${supportsChildren ? 'CustomTagParser, ' : ''}AsyncTag {',
  );
  buffer.writeln('  $className(super.content, super.filters);\n');

  buffer.writeln('  @override');
  buffer.writeln(
    '  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {',
  );
  buffer.writeln('    final config = _parseConfig(evaluator);');
  if (supportsChildren) {
    buffer.writeln('    final children = captureChildrenSync(evaluator);');
  } else {
    buffer.writeln('    const children = <Widget>[];');
  }
  buffer.writeln('    buffer.write($buildName(config, children));');
  buffer.writeln('  }\n');

  buffer.writeln('  @override');
  buffer.writeln(
    '  Future<dynamic> evaluateWithContextAsync(Evaluator evaluator, Buffer buffer) async {',
  );
  buffer.writeln('    final config = _parseConfig(evaluator);');
  if (supportsChildren) {
    buffer.writeln(
      '    final children = await captureChildrenAsync(evaluator);',
    );
  } else {
    buffer.writeln('    const children = <Widget>[];');
  }
  buffer.writeln('    buffer.write($buildName(config, children));');
  buffer.writeln('  }\n');

  if (supportsChildren) {
    buffer.writeln('  @override');
    buffer.writeln('  Parser parser() {');
    buffer.writeln('    final start = tagStart() &');
    buffer.writeln("        string('${spec.tag}').trim() &");
    buffer.writeln('        ref0(tagContent).optional().trim() &');
    buffer.writeln('        ref0(filter).star().trim() &');
    buffer.writeln('        tagEnd();');
    buffer.writeln(
      "    final endTag = tagStart() & string('end${spec.tag}').trim() & tagEnd();",
    );
    buffer.writeln(
      '    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {',
    );
    buffer.writeln(
      '      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);',
    );
    buffer.writeln('      final filters = (values[3] as List).cast<Filter>();');
    buffer.writeln('      final nonFilterContent =');
    buffer.writeln(
      '          content.where((node) => node is! Filter).toList();',
    );
    buffer.writeln('      return Tag(');
    buffer.writeln("        '${spec.tag}',");
    buffer.writeln('        nonFilterContent,');
    buffer.writeln('        filters: filters,');
    buffer.writeln('        body: values[5].cast<ASTNode>(),');
    buffer.writeln('      );');
    buffer.writeln('    });');
    buffer.writeln('  }\n');
  }

  buffer.writeln('  $configName _parseConfig(Evaluator evaluator) {');
  buffer.writeln('    final config = $configName();');
  if (spec.properties.isEmpty) {
    buffer.writeln('    for (final arg in namedArgs) {');
    buffer.writeln(
      '      handleUnknownArg(\'${spec.tag}\', arg.identifier.name);',
    );
    buffer.writeln('    }');
  } else {
    buffer.writeln('    for (final arg in namedArgs) {');
    buffer.writeln('      final name = arg.identifier.name;');
    buffer.writeln('      final value = evaluator.evaluate(arg.value);');
    buffer.writeln('      switch (name) {');
    for (final prop in spec.properties) {
      buffer.writeln("        case '${prop.name}':");
      buffer.writeln(
        '          config.${prop.name} = ${_parseExpression(prop, 'value', evaluatorParsers)};',
      );
      buffer.writeln('          break;');
    }
    buffer.writeln('        default:');
    buffer.writeln("          handleUnknownArg('${spec.tag}', name);");
    buffer.writeln('          break;');
    buffer.writeln('      }');
    buffer.writeln('    }');
  }
  for (final prop in spec.properties.where((p) => p.required)) {
    buffer.writeln('    if (config.${prop.name} == null) {');
    buffer.writeln(
      "      throw Exception('${spec.tag} tag requires \"${prop.name}\"');",
    );
    buffer.writeln('    }');
  }
  buffer.writeln('    return config;');
  buffer.writeln('  }');
  buffer.writeln('}');

  buffer.writeln('\nclass $configName {');
  for (final prop in spec.properties) {
    buffer.writeln('  ${prop.type}? ${prop.name};');
  }
  buffer.writeln('}\n');

  buffer.writeln(
    '${spec.returnType} $buildName($configName config, List<Widget> children) {',
  );
  final positionalProps =
      spec.properties.where((prop) => prop.isPositional).toList()..sort(
        (a, b) => (a.positionalIndex ?? 0).compareTo(b.positionalIndex ?? 0),
      );
  final namedProps = spec.properties.where((prop) => !prop.isPositional);
  if (spec.children != null && spec.children!.kind == 'single') {
    buffer.writeln('  final child = children.isNotEmpty');
    buffer.writeln('      ? wrapChildren(children)');
    buffer.writeln('      : ${_childFallback(spec.children!)};');
  }
  buffer.writeln('  return ${spec.widget}(');
  for (final prop in positionalProps) {
    var valueExpr = 'config.${prop.name}';
    if (prop.defaultValue != null) {
      valueExpr = '$valueExpr ?? ${prop.defaultValue}';
    } else if (!prop.nullable) {
      valueExpr = '$valueExpr!';
    }
    buffer.writeln('    $valueExpr,');
  }
  for (final prop in namedProps) {
    var valueExpr = 'config.${prop.name}';
    if (prop.defaultValue != null) {
      valueExpr = '$valueExpr ?? ${prop.defaultValue}';
    } else if (!prop.nullable) {
      valueExpr = '$valueExpr!';
    }
    buffer.writeln('    ${prop.name}: $valueExpr,');
  }
  if (spec.children != null) {
    if (spec.children!.kind == 'single') {
      buffer.writeln('    child: child,');
    } else if (spec.children!.kind == 'list') {
      buffer.writeln('    children: children,');
    }
  }
  buffer.writeln('  );');
  buffer.writeln('}');

  return buffer.toString();
}

String _parseExpression(
  _GeneratedProperty prop,
  String valueVar,
  Set<String> evaluatorParsers,
) {
  if (prop.parser != null && prop.parser!.isNotEmpty) {
    final usesEvaluator =
        prop.usesEvaluator ||
        (prop.parser != null && evaluatorParsers.contains(prop.parser));
    final parsed = usesEvaluator
        ? '${prop.parser}(evaluator, $valueVar)'
        : '${prop.parser}($valueVar)';
    if (prop.parserOutputType != null &&
        prop.parserOutputType!.isNotEmpty &&
        prop.parserOutputType != prop.type) {
      return '($parsed as ${prop.type}?)';
    }
    return parsed;
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

String _childFallback(_GeneratedChild spec) {
  switch (spec.fallback) {
    case 'shrink':
      return 'const SizedBox.shrink()';
    default:
      return 'null';
  }
}

String _renderGeneratedRegistry(List<_GeneratedSpec> specs) {
  final buffer = StringBuffer();
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.');
  buffer.writeln('// Generated by widget_spec_builder.');
  buffer.writeln(
    '// ignore_for_file: unnecessary_non_null_assertion, no_leading_underscores_for_local_identifiers, prefer_is_empty, prefer_is_not_empty',
  );
  buffer.writeln();
  buffer.writeln("import 'package:liquify/parser.dart';");
  buffer.writeln("import 'widget_tags.dart';");
  buffer.writeln();
  buffer.writeln(
    'void registerGeneratedWidgetTags(Environment? environment) {',
  );
  buffer.writeln('  final existing = TagRegistry.tags.toSet();');
  for (final spec in specs) {
    buffer.writeln("  if (!existing.contains('${spec.tag}')) {");
    buffer.writeln(
      "    _registerGeneratedTag('${spec.tag}', (content, filters) => ${spec.className}(content, filters), environment);",
    );
    buffer.writeln('  }');
  }
  buffer.writeln('}');
  buffer.writeln();
  buffer.writeln('void _registerGeneratedTag(');
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

String _renderGeneratedTests(List<_GeneratedSpec> specs) {
  final buffer = StringBuffer();
  buffer.writeln("import 'dart:typed_data';");
  buffer.writeln("import 'package:flutter/material.dart';");
  buffer.writeln("import 'package:flutter_test/flutter_test.dart';");
  buffer.writeln("import '../test_utils.dart';");
  buffer.writeln();
  buffer.writeln('void main() {');
  const skipTags = {
    'bottom_navigation_bar',
    'bottom_sheet',
    'navigation_bar',
    'navigation_bar_destination',
    'navigation_destination',
    'navigation_drawer_destination',
    'navigation_rail',
    'navigation_rail_destination',
    'paginated_data_table',
    'padding',
    'popup_menu_divider',
    'popup_menu_item',
    'snack_bar_action',
    'sliver_app_bar',
    'sliver_fill_remaining',
    'sliver_grid',
    'sliver_list',
    'sliver_padding',
    'sliver_persistent_header',
    'sliver_to_box_adapter',
  };
  for (final spec in specs) {
    if (skipTags.contains(spec.tag)) {
      continue;
    }
    final testTemplate = _testTemplate(spec);
    buffer.writeln("  testWidgets('${spec.tag} renders', (tester) async {");
    buffer.writeln('    await pumpTemplate(');
    buffer.writeln('      tester,');
    buffer.writeln("      '''");
    buffer.writeln(testTemplate.template);
    buffer.writeln("      '''");
    if (testTemplate.data.isNotEmpty) {
      buffer.writeln('      ,data: {');
      testTemplate.data.forEach((key, value) {
        buffer.writeln("        '$key': $value,");
      });
      buffer.writeln('      }');
    }
    buffer.writeln('    );');
    if (spec.tag == 'form_field') {
      buffer.writeln(
        '    expect(find.byWidgetPredicate((widget) => widget is FormField<String>), findsWidgets);',
      );
    } else {
      buffer.writeln('    expect(find.byType(${spec.widget}), findsWidgets);');
    }
    buffer.writeln('  });');
  }
  buffer.writeln('}');
  return buffer.toString();
}

class _TestTemplateResult {
  _TestTemplateResult(this.template, this.data);

  final String template;
  final Map<String, String> data;
}

_TestTemplateResult _testTemplate(_GeneratedSpec spec) {
  final requiredArgs = _requiredArgsForSpec(spec);
  final argString = requiredArgs.args.isEmpty
      ? ''
      : ' ${requiredArgs.args.join(' ')}';
  if (spec.tag.startsWith('sliver_')) {
    return _TestTemplateResult(
      '{% custom_scroll_view %}'
      '{% ${spec.tag}$argString %}{% end${spec.tag} %}'
      '{% endcustom_scroll_view %}',
      requiredArgs.data,
    );
  }
  switch (spec.tag) {
    case 'colored_box':
      return _TestTemplateResult(
        '{% colored_box$argString %}'
        '{% text value: "Sample" %}'
        '{% endcolored_box %}',
        requiredArgs.data,
      );
    case 'expanded':
      return _TestTemplateResult(
        '{% row %}'
        '{% expanded$argString %}'
        '{% text value: "Sample" %}'
        '{% endexpanded %}'
        '{% endrow %}',
        requiredArgs.data,
      );
    case 'flexible':
      return _TestTemplateResult(
        '{% row %}'
        '{% flexible$argString %}'
        '{% text value: "Sample" %}'
        '{% endflexible %}'
        '{% endrow %}',
        requiredArgs.data,
      );
    case 'spacer':
      return _TestTemplateResult(
        '{% row %}'
        '{% spacer$argString %}{% endspacer %}'
        '{% endrow %}',
        requiredArgs.data,
      );
    case 'page_view':
      return _TestTemplateResult(
        '{% page_view$argString %}'
        '{% text value: "Page" %}'
        '{% endpage_view %}',
        requiredArgs.data,
      );
    case 'data_table':
      {
        final data = <String, String>{
          ...requiredArgs.data,
          'columns': 'const [\'Name\']',
          'rows': 'const [[\'Alice\']]',
        };
        return _TestTemplateResult(
          '{% data_table columns: columns rows: rows %}{% enddata_table %}',
          data,
        );
      }
    case 'form_field':
      return _TestTemplateResult(
        '{% form_field$argString %}'
        '{% text value: "Sample" %}'
        '{% endform_field %}',
        requiredArgs.data,
      );
    case 'grid':
    case 'grid_view':
      return _TestTemplateResult(
        '{% ${spec.tag} columns: 2 %}'
        '{% text value: "Item" %}'
        '{% end${spec.tag} %}',
        requiredArgs.data,
      );
    case 'icon_button':
      return _TestTemplateResult(
        '{% icon_button icon: "add" %}{% endicon_button %}',
        requiredArgs.data,
      );
    case 'icon':
      return _TestTemplateResult(
        '{% icon icon: "add" %}{% endicon %}',
        requiredArgs.data,
      );
    case 'image':
      {
        final data = <String, String>{
          ...requiredArgs.data,
          'bytes':
              'Uint8List.fromList(const <int>['
              '0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A,'
              '0x00,0x00,0x00,0x0D,0x49,0x48,0x44,0x52,'
              '0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,'
              '0x08,0x06,0x00,0x00,0x00,0x1F,0x15,0xC4,'
              '0x89,0x00,0x00,0x00,0x0A,0x49,0x44,0x41,'
              '0x54,0x78,0x9C,0x63,0x00,0x01,0x00,0x00,'
              '0x05,0x00,0x01,0x0D,0x0A,0x2D,0xB4,0x00,'
              '0x00,0x00,0x00,0x49,0x45,0x4E,0x44,0xAE,'
              '0x42,0x60,0x82'
              '])',
        };
        return _TestTemplateResult(
          '{% image bytes: bytes width: 1 height: 1 %}{% endimage %}',
          data,
        );
      }
    case 'navigation_rail':
      return _TestTemplateResult(
        '{% navigation_rail$argString %}'
        '{% navigation_destination label: "Home" icon: "home" %}'
        '{% endnavigation_rail %}',
        requiredArgs.data,
      );
    case 'positioned':
      return _TestTemplateResult(
        '{% stack %}'
        '{% positioned left: 0 top: 0 %}'
        '{% text value: "Sample" %}'
        '{% endpositioned %}'
        '{% endstack %}',
        requiredArgs.data,
      );
    case 'animated_positioned':
      return _TestTemplateResult(
        '{% stack %}'
        '{% animated_positioned$argString left: 0 top: 0 %}'
        '{% text value: "Sample" %}'
        '{% endanimated_positioned %}'
        '{% endstack %}',
        requiredArgs.data,
      );
    case 'sized_box':
      return _TestTemplateResult(
        '{% sized_box width: 120 height: 80 %}'
        '{% endsized_box %}',
        requiredArgs.data,
      );
    case 'sized_overflow_box':
      return _TestTemplateResult(
        '{% sized_overflow_box$argString %}'
        '{% text value: "Sample" %}'
        '{% endsized_overflow_box %}',
        requiredArgs.data,
      );
    case 'ignore_pointer':
      return _TestTemplateResult(
        '{% ignore_pointer ignoring: true %}'
        '{% text value: "Sample" %}'
        '{% endignore_pointer %}',
        requiredArgs.data,
      );
    case 'tooltip':
      return _TestTemplateResult(
        '{% tooltip message: "Hint" %}'
        '{% text value: "Hover" %}'
        '{% endtooltip %}',
        requiredArgs.data,
      );
    case 'snack_bar_action':
      return _TestTemplateResult(
        '{% snack_bar content: "Sample" %}'
        '{% snack_bar_action$argString %}'
        '{% endsnack_bar_action %}'
        '{% endsnack_bar %}',
        requiredArgs.data,
      );
    case 'popup_menu_item':
      return _TestTemplateResult(
        '{% popup_menu %}'
        '{% popup_menu_item$argString %}{% endpopup_menu_item %}'
        '{% endpopup_menu %}',
        requiredArgs.data,
      );
    default:
      return _TestTemplateResult(
        '{% ${spec.tag}$argString %}{% end${spec.tag} %}',
        requiredArgs.data,
      );
  }
}

class _RequiredArgsResult {
  _RequiredArgsResult(this.args, this.data);

  final List<String> args;
  final Map<String, String> data;
}

class _TestArgValue {
  _TestArgValue(this.templateValue, {this.dataValue});

  final String templateValue;
  final String? dataValue;
}

_RequiredArgsResult _requiredArgsForSpec(_GeneratedSpec spec) {
  final args = <String>[];
  final data = <String, String>{};
  for (final prop in spec.properties) {
    if (!prop.required) {
      continue;
    }
    final value = _defaultValueForType(prop.type, prop.name);
    if (value != null) {
      args.add('${prop.name}: ${value.templateValue}');
      if (value.dataValue != null) {
        data[prop.name] = value.dataValue!;
      }
    }
  }
  return _RequiredArgsResult(args, data);
}

_TestArgValue? _defaultValueForType(String type, String name) {
  if (type.startsWith('ValueChanged<')) {
    return _TestArgValue(name, dataValue: '(dynamic _) {}');
  }
  switch (type) {
    case 'double':
    case 'num':
      return _TestArgValue('1');
    case 'int':
      return _TestArgValue('1');
    case 'bool':
      return _TestArgValue('true');
    case 'String':
      return _TestArgValue('"Sample"');
    case 'Color':
      return _TestArgValue('"#FF0000"');
    case 'AlignmentGeometry':
      return _TestArgValue('"center"');
    case 'Axis':
      return _TestArgValue('"horizontal"');
    case 'TextDirection':
      return _TestArgValue('"ltr"');
    case 'TextBaseline':
      return _TestArgValue('"alphabetic"');
    case 'Matrix4':
      return _TestArgValue('"1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1"');
    case 'Offset':
      return _TestArgValue('"0.1,0.1"');
    case 'Duration':
      return _TestArgValue('"200ms"');
    case 'Curve':
      return _TestArgValue('"easeInOut"');
    case 'DateTime':
      return _TestArgValue('"2024-01-01"');
    case 'Animation<double>':
      return _TestArgValue(
        name,
        dataValue: 'const AlwaysStoppedAnimation<double>(1.0)',
      );
    case 'Decoration':
      return _TestArgValue('"#FF0000"');
    case 'Object':
    case 'Object?':
      return _TestArgValue('"sample"');
    case 'BoxConstraints':
      return _TestArgValue(
        name,
        dataValue:
            'const BoxConstraints(minWidth: 0, maxWidth: 100, minHeight: 0, maxHeight: 100)',
      );
    case 'EdgeInsets':
    case 'EdgeInsetsGeometry':
      return _TestArgValue('8');
    case 'IconThemeData':
      return _TestArgValue(name, dataValue: 'const IconThemeData(size: 16)');
    case 'Size':
      return _TestArgValue('"20,20"');
    case 'TextStyle':
      return _TestArgValue(name, dataValue: 'const TextStyle(fontSize: 14)');
    case 'VoidCallback':
      return _TestArgValue(name, dataValue: 'TapActionDrop(() {})');
    case 'List<BottomNavigationBarItem>':
      return _TestArgValue(
        name,
        dataValue:
            '[const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home")]',
      );
    case 'List<DropdownMenuItem<Object?>>':
      return _TestArgValue(
        name,
        dataValue:
            '[const DropdownMenuItem(value: "Sample", child: Text("Sample"))]',
      );
    case 'PopupMenuItemBuilder<Object?>':
      return _TestArgValue(
        name,
        dataValue:
            '(BuildContext context) => [const PopupMenuItem(value: "Sample", child: Text("Sample"))]',
      );
    case 'List<ButtonSegment<Object?>>':
      return _TestArgValue(
        name,
        dataValue:
            '[ButtonSegment(value: "Sample", label: const Text("Sample"))]',
      );
    case 'Set<Object?>':
      return _TestArgValue(name, dataValue: '<Object?>{"Sample"}');
    case 'Widget':
      return _TestArgValue('"Sample"');
    case 'StackFit':
      return _TestArgValue('"loose"');
    case 'FlexFit':
      return _TestArgValue('"loose"');
    case 'OverflowBoxFit':
      return _TestArgValue('"max"');
  }
  return null;
}

String _generatedEnumParserName(String enumName) {
  return 'parseGenerated$enumName';
}

String _generatedClassParserName(String className) {
  return 'parseGenerated$className';
}

String _renderTypeParsers(
  List<_ResolvedEnum> enums,
  List<_ClassParserSpec> classParsers,
  List<_CollectionParserSpec> collectionParsers,
  List<_WrapperParserSpec> wrapperParsers,
  List<_MissingParserSpec> missingParsers,
  Set<String> evaluatorParsers,
) {
  final buffer = StringBuffer();
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.');
  buffer.writeln('// Generated by widget_spec_builder.');
  buffer.writeln(
    '// ignore_for_file: unnecessary_non_null_assertion, no_leading_underscores_for_local_identifiers, prefer_is_empty, prefer_is_not_empty',
  );
  buffer.writeln();

  final importSet = <String>{};
  for (final resolvedEnum in enums) {
    importSet.add(resolvedEnum.library);
  }
  final usesEvaluator =
      evaluatorParsers.isNotEmpty ||
      collectionParsers.any((parser) => parser.usesEvaluator) ||
      wrapperParsers.any((parser) => parser.usesEvaluator);
  if (usesEvaluator) {
    importSet.add('package:liquify/parser.dart');
  }
  if (classParsers.isNotEmpty || collectionParsers.isNotEmpty) {
    importSet.add('package:liquify_flutter/src/tags/tag_helpers.dart');
    for (final spec in classParsers) {
      final library = spec.library;
      if (library != null && library.isNotEmpty) {
        importSet.add(library);
      }
      for (final constValue in spec.constValues) {
        if (constValue.library.isNotEmpty) {
          importSet.add(constValue.library);
        }
      }
    }
  }
  for (final spec in collectionParsers) {
    importSet.addAll(spec.imports);
  }
  for (final spec in wrapperParsers) {
    importSet.addAll(spec.imports);
  }

  final needsMath = _needsMathImport(classParsers);
  if (needsMath) {
    importSet.remove('dart:math');
  }
  final imports = importSet.toList()..sort();
  if (needsMath) {
    buffer.writeln("import 'dart:math' as math;");
  }
  for (final entry in imports) {
    buffer.writeln("import '$entry';");
  }
  if (imports.isNotEmpty || needsMath) {
    buffer.writeln();
  }

  for (final resolvedEnum in enums) {
    final name = resolvedEnum.element.name ?? '';
    if (name.isEmpty) {
      continue;
    }
    buffer.writeln('$name? ${_generatedEnumParserName(name)}(Object? value) {');
    buffer.writeln('  if (value is $name) {');
    buffer.writeln('    return value;');
    buffer.writeln('  }');
    buffer.writeln('  if (value is String) {');
    buffer.writeln('    final normalized = _normalizeTypeKey(value);');
    buffer.writeln('    if (normalized.isEmpty) {');
    buffer.writeln('      return null;');
    buffer.writeln('    }');
    buffer.writeln('    for (final entry in $name.values) {');
    buffer.writeln('      if (_normalizeTypeKey(entry.name) == normalized) {');
    buffer.writeln('        return entry;');
    buffer.writeln('      }');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln('  if (value is int) {');
    buffer.writeln('    final index = value;');
    buffer.writeln('    if (index >= 0 && index < $name.values.length) {');
    buffer.writeln('      return $name.values[index];');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln('  return null;');
    buffer.writeln('}');
    buffer.writeln();
  }

  for (final spec in classParsers) {
    buffer.writeln(_renderClassParser(spec, evaluatorParsers));
    buffer.writeln();
  }

  for (final spec in collectionParsers) {
    buffer.writeln(_renderCollectionParser(spec, evaluatorParsers));
    buffer.writeln();
  }

  for (final spec in wrapperParsers) {
    buffer.writeln(_renderWrapperParser(spec, evaluatorParsers));
    buffer.writeln();
  }

  if (missingParsers.isNotEmpty) {
    for (final spec in missingParsers) {
      buffer.writeln(_renderMissingParser(spec));
      buffer.writeln();
    }
  }

  buffer.writeln('Object? _splitCommaSeparated(Object? value) {');
  buffer.writeln('  if (value is String && value.contains(\',\')) {');
  buffer.writeln('    final parts = value');
  buffer.writeln('        .split(\',\')');
  buffer.writeln('        .map((entry) => entry.trim())');
  buffer.writeln('        .where((entry) => entry.isNotEmpty)');
  buffer.writeln('        .toList();');
  buffer.writeln('    if (parts.isNotEmpty) {');
  buffer.writeln('      return parts;');
  buffer.writeln('    }');
  buffer.writeln('  }');
  buffer.writeln('  return value;');
  buffer.writeln('}');
  buffer.writeln();

  buffer.writeln('String _normalizeTypeKey(Object? value) {');
  buffer.writeln('  if (value == null) {');
  buffer.writeln('    return \'\';');
  buffer.writeln('  }');
  buffer.writeln('  return value');
  buffer.writeln('      .toString()');
  buffer.writeln('      .trim()');
  buffer.writeln('      .toLowerCase()');
  buffer.writeln('      .replaceAll(RegExp(r\'[^a-z0-9]\'), \'\');');
  buffer.writeln('}');
  buffer.writeln();
  buffer.writeln('bool _matchesConstructorKeys(');
  buffer.writeln('  Map<String, Object?> map,');
  buffer.writeln('  List<String> allowed,');
  buffer.writeln('  List<String> required,');
  buffer.writeln(') {');
  buffer.writeln('  for (final entry in map.keys) {');
  buffer.writeln('    if (!allowed.contains(entry)) {');
  buffer.writeln('      return false;');
  buffer.writeln('    }');
  buffer.writeln('  }');
  buffer.writeln('  for (final entry in required) {');
  buffer.writeln('    if (!map.containsKey(entry)) {');
  buffer.writeln('      return false;');
  buffer.writeln('    }');
  buffer.writeln('  }');
  buffer.writeln('  return true;');
  buffer.writeln('}');
  buffer.writeln();
  buffer.writeln('int? _normalizeColorInt(int? value) {');
  buffer.writeln('  if (value == null) {');
  buffer.writeln('    return null;');
  buffer.writeln('  }');
  buffer.writeln('  if (value >= 0 && value <= 0xFFFFFF) {');
  buffer.writeln('    return 0xFF000000 | value;');
  buffer.writeln('  }');
  buffer.writeln('  return value;');
  buffer.writeln('}');

  return buffer.toString();
}

bool _needsMathImport(List<_ClassParserSpec> classParsers) {
  bool hasMathDefault(String? value) =>
      value != null && value.contains('math.');
  for (final spec in classParsers) {
    for (final ctor in spec.constructors) {
      for (final field in ctor.positional) {
        if (hasMathDefault(field.defaultValue)) {
          return true;
        }
      }
      for (final field in ctor.named) {
        if (hasMathDefault(field.defaultValue)) {
          return true;
        }
      }
    }
  }
  return false;
}

Set<String> _expandEvaluatorParsers(
  Set<String> base,
  List<_ClassParserSpec> classParsers,
  List<_CollectionParserSpec> collectionParsers,
  List<_WrapperParserSpec> wrapperParsers,
) {
  final expanded = <String>{...base};
  var changed = true;
  while (changed) {
    changed = false;
    for (final spec in classParsers) {
      final parserName = _generatedClassParserName(spec.name);
      if (expanded.contains(parserName)) {
        continue;
      }
      final needsEvaluator =
          spec.usesEvaluator ||
          spec.subtypeParsers.any(
            (parser) => expanded.contains(parser.parser),
          ) ||
          spec.constructors.any(
            (ctor) =>
                ctor.positional.any(
                  (field) => expanded.contains(field.parser),
                ) ||
                ctor.named.any((field) => expanded.contains(field.parser)),
          );
      if (needsEvaluator && expanded.add(parserName)) {
        changed = true;
      }
    }
    for (final spec in collectionParsers) {
      if (!expanded.contains(spec.name) &&
          (spec.usesEvaluator || expanded.contains(spec.elementParser))) {
        if (expanded.add(spec.name)) {
          changed = true;
        }
      }
    }
    for (final spec in wrapperParsers) {
      if (!expanded.contains(spec.name) &&
          (spec.usesEvaluator || expanded.contains(spec.elementParser))) {
        if (expanded.add(spec.name)) {
          changed = true;
        }
      }
    }
  }
  return expanded;
}

String _renderParserAliases(
  _TypeRegistry registry,
  Set<String> evaluatorParsers,
) {
  final buffer = StringBuffer();
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.');
  buffer.writeln('// Generated by widget_spec_builder.');
  buffer.writeln();

  final aliases =
      <
        ({String alias, String target, String returnType, bool usesEvaluator})
      >[];
  for (final entry in registry.entries.values) {
    final parser = entry.parser;
    if (parser == null || !parser.startsWith('parseGenerated')) {
      continue;
    }
    final aliasName = 'parse${parser.substring('parseGenerated'.length)}';
    final returnType = entry.outputType ?? entry.name;
    if (_containsTypeParameter(returnType)) {
      continue;
    }
    final usesEvaluator = evaluatorParsers.contains(parser);
    aliases.add((
      alias: aliasName,
      target: parser,
      returnType: returnType,
      usesEvaluator: usesEvaluator,
    ));
  }
  aliases.sort((a, b) => a.alias.compareTo(b.alias));

  final importSet = <String>{};
  if (aliases.any((alias) => alias.usesEvaluator)) {
    importSet.add('package:liquify/parser.dart');
  }
  for (final entry in registry.entries.values) {
    final parser = entry.parser;
    if (parser == null || !parser.startsWith('parseGenerated')) {
      continue;
    }
    if (entry.imports.isNotEmpty) {
      importSet.addAll(entry.imports);
    }
  }
  final imports = importSet.toList()..sort();
  for (final entry in imports) {
    buffer.writeln("import '$entry';");
  }
  buffer.writeln("import 'type_parsers.dart';");
  buffer.writeln();

  for (final alias in aliases) {
    if (alias.usesEvaluator) {
      buffer.writeln(
        '${alias.returnType}? ${alias.alias}(Evaluator evaluator, Object? value) {',
      );
      buffer.writeln('  return ${alias.target}(evaluator, value);');
    } else {
      buffer.writeln('${alias.returnType}? ${alias.alias}(Object? value) {');
      buffer.writeln('  return ${alias.target}(value);');
    }
    buffer.writeln('}');
    buffer.writeln();
  }

  return buffer.toString();
}

String _renderTypeFilters(
  _TypeRegistry registry,
  Set<String> evaluatorParsers,
) {
  final filters = <({String name, String parser, String returnType})>[];
  final used = <String>{};

  for (final entry in registry.entries.values) {
    final parser = entry.parser;
    if (parser == null || entry.usesEvaluator) {
      continue;
    }
    if (evaluatorParsers.contains(parser)) {
      continue;
    }

    final names = <String>{};
    final primary = _filterNameForType(entry.name);
    if (primary.isNotEmpty) {
      names.add(primary);
    }
    for (final alias in entry.aliases) {
      final aliasName = _filterNameForType(alias);
      if (aliasName.isNotEmpty) {
        names.add(aliasName);
      }
    }
    for (final name in names) {
      if (!used.add(name)) {
        continue;
      }
      filters.add((
        name: name,
        parser: parser,
        returnType: entry.outputType ?? entry.name,
      ));
    }
  }

  filters.sort((a, b) => a.name.compareTo(b.name));

  final buffer = StringBuffer();
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.');
  buffer.writeln('// Generated by widget_spec_builder.');
  buffer.writeln();
  buffer.writeln("import 'package:liquify/liquify.dart';");
  buffer.writeln("import '../tags/tag_helpers.dart';");
  buffer.writeln("import 'type_parsers.dart';");
  buffer.writeln();
  buffer.writeln(
    'void registerGeneratedTypeFilters(Environment environment) {',
  );
  for (final filter in filters) {
    buffer.writeln(
      "  environment.registerLocalFilter('${filter.name}', (value, args, namedArgs) => _parseFilterValue(value, args, namedArgs, ${filter.parser}));",
    );
  }
  buffer.writeln('}');
  buffer.writeln();
  buffer.writeln(
    'dynamic _parseFilterValue(Object? value, List<dynamic> args, Map<String, dynamic> namedArgs, dynamic Function(Object?) parser) {',
  );
  buffer.writeln('  if (namedArgs.isNotEmpty) {');
  buffer.writeln('    final parsed = parser(namedArgs);');
  buffer.writeln('    if (parsed != null) {');
  buffer.writeln('      return parsed;');
  buffer.writeln('    }');
  buffer.writeln(
    '    if (!namedArgs.containsKey(\'constructor\') && !namedArgs.containsKey(\'type\')) {',
  );
  buffer.writeln(
    '      final wrapped = <String, dynamic>{\'constructor\': \'new\'};',
  );
  buffer.writeln('      wrapped.addAll(namedArgs);');
  buffer.writeln('      final fallback = parser(wrapped);');
  buffer.writeln('      if (fallback != null) {');
  buffer.writeln('        return fallback;');
  buffer.writeln('      }');
  buffer.writeln('    }');
  buffer.writeln('  }');
  buffer.writeln('  if (value != null) {');
  buffer.writeln('    return parser(value);');
  buffer.writeln('  }');
  buffer.writeln('  if (args.isNotEmpty) {');
  buffer.writeln('    return parser(args.first);');
  buffer.writeln('  }');
  buffer.writeln('  return null;');
  buffer.writeln('}');
  buffer.writeln();

  return buffer.toString();
}

String _filterNameForType(String typeName) {
  final tokens = _splitTypeTokens(typeName);
  if (tokens.isEmpty) {
    return '';
  }
  return tokens.join('_');
}

bool _containsTypeParameter(String typeName) {
  if (RegExp(r'^[A-Z][A-Z0-9_]*\??$').hasMatch(typeName)) {
    return true;
  }
  return RegExp(r'(<|,)\s*[A-Z][A-Z0-9_]*\s*\??\s*(,|>)').hasMatch(typeName);
}

String _sanitizeTypeName(String typeName) {
  if (!_containsTypeParameter(typeName)) {
    return typeName;
  }
  if (RegExp(r'^[A-Z][A-Z0-9_]*\??$').hasMatch(typeName)) {
    return 'Object?';
  }
  return typeName.replaceAllMapped(
    RegExp(r'(<|,)\s*([A-Z][A-Z0-9_]*)\s*\??(?=\s*(,|>))'),
    (match) => '${match.group(1)} Object?',
  );
}

_GeneratedParserSets _collectGeneratedParserSets(
  List<_ResolvedEnum> enums,
  List<_ClassParserSpec> classParsers,
  List<_CollectionParserSpec> collectionParsers,
  List<_WrapperParserSpec> wrapperParsers,
) {
  final value = <String>{};
  final evaluator = <String>{};

  for (final resolvedEnum in enums) {
    final name = resolvedEnum.element.name;
    if (name == null || name.isEmpty) {
      continue;
    }
    value.add(_generatedEnumParserName(name));
  }
  for (final spec in classParsers) {
    final parserName = _generatedClassParserName(spec.name);
    if (spec.usesEvaluator) {
      evaluator.add(parserName);
    } else {
      value.add(parserName);
    }
  }
  for (final spec in collectionParsers) {
    if (spec.usesEvaluator) {
      evaluator.add(spec.name);
    } else {
      value.add(spec.name);
    }
  }
  for (final spec in wrapperParsers) {
    if (spec.usesEvaluator) {
      evaluator.add(spec.name);
    } else {
      value.add(spec.name);
    }
  }

  return _GeneratedParserSets(value, evaluator);
}

class _GeneratedParserSets {
  _GeneratedParserSets(this.value, this.evaluator);

  final Set<String> value;
  final Set<String> evaluator;
}

class _MissingParserSpec {
  _MissingParserSpec({
    required this.name,
    required this.returnType,
    required this.usesEvaluator,
  });

  final String name;
  final String returnType;
  final bool usesEvaluator;
}

List<_MissingParserSpec> _collectMissingParserSpecs(
  _TypeRegistry registry,
  _GeneratedParserSets generatedParsers,
) {
  final missing = <_MissingParserSpec>[];
  for (final entry in registry.entries.values) {
    final parser = entry.parser;
    if (parser == null || !parser.startsWith('parseGenerated')) {
      continue;
    }
    if (generatedParsers.value.contains(parser) ||
        generatedParsers.evaluator.contains(parser)) {
      continue;
    }
    final usesEvaluator = entry.usesEvaluator;
    var returnType = entry.outputType ?? entry.name;
    if (_containsTypeParameter(returnType)) {
      returnType = 'dynamic';
    }
    missing.add(
      _MissingParserSpec(
        name: parser,
        returnType: returnType,
        usesEvaluator: usesEvaluator,
      ),
    );
  }
  missing.sort((a, b) => a.name.compareTo(b.name));
  return missing;
}

String _renderMissingParser(_MissingParserSpec spec) {
  final signature = spec.usesEvaluator
      ? '${spec.returnType}? ${spec.name}(Evaluator evaluator, Object? value)'
      : '${spec.returnType}? ${spec.name}(Object? value)';
  return '$signature {\n  return null;\n}';
}

String _renderGeneratedTypeRegistry(
  _TypeRegistry registry,
  Set<String> evaluatorParsers,
) {
  final entries = registry.entries.values.toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  final buffer = StringBuffer();
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.');
  buffer.writeln('// Generated by widget_spec_builder.');
  buffer.writeln('// ignore_for_file: unnecessary_const');
  buffer.writeln();
  buffer.writeln("import 'package:liquify/parser.dart';");
  buffer.writeln(
    "import 'package:liquify_flutter/src/generated/type_parsers.dart';",
  );
  buffer.writeln("import 'package:liquify_flutter/src/tags/tag_helpers.dart';");
  buffer.writeln();
  buffer.writeln(
    'typedef GeneratedValueParser = Object? Function(Object? value);',
  );
  buffer.writeln(
    'typedef GeneratedEvaluatorParser = Object? Function(Evaluator evaluator, Object? value);',
  );
  buffer.writeln();
  buffer.writeln('class GeneratedTypeField {');
  buffer.writeln('  const GeneratedTypeField({');
  buffer.writeln('    required this.name,');
  buffer.writeln('    required this.type,');
  buffer.writeln('    this.defaultValue,');
  buffer.writeln('    this.required = false,');
  buffer.writeln('  });');
  buffer.writeln('  final String name;');
  buffer.writeln('  final String type;');
  buffer.writeln('  final String? defaultValue;');
  buffer.writeln('  final bool required;');
  buffer.writeln('}');
  buffer.writeln();
  buffer.writeln('class GeneratedTypeEntry {');
  buffer.writeln('  const GeneratedTypeEntry({');
  buffer.writeln('    required this.name,');
  buffer.writeln('    required this.kind,');
  buffer.writeln('    this.parserName,');
  buffer.writeln('    this.usesEvaluator = false,');
  buffer.writeln('    this.outputType,');
  buffer.writeln('    this.aliases = const [],');
  buffer.writeln('    this.dropSymbols = const [],');
  buffer.writeln('    this.imports = const [],');
  buffer.writeln('    this.constructorName,');
  buffer.writeln('    this.fields = const [],');
  buffer.writeln('  });');
  buffer.writeln('  final String name;');
  buffer.writeln('  final String kind;');
  buffer.writeln('  final String? parserName;');
  buffer.writeln('  final bool usesEvaluator;');
  buffer.writeln('  final String? outputType;');
  buffer.writeln('  final List<String> aliases;');
  buffer.writeln('  final List<String> dropSymbols;');
  buffer.writeln('  final List<String> imports;');
  buffer.writeln('  final String? constructorName;');
  buffer.writeln('  final List<GeneratedTypeField> fields;');
  buffer.writeln('}');
  buffer.writeln();

  String renderStringList(List<String> values) {
    if (values.isEmpty) {
      return 'const []';
    }
    final entries = values
        .map((value) => "'${value.replaceAll("'", "\\'")}'")
        .join(', ');
    return 'const [$entries]';
  }

  String renderFields(List<_TypeRegistryField> fields) {
    if (fields.isEmpty) {
      return 'const []';
    }
    final entries = fields
        .map((field) {
          final defaultValue = field.defaultValue == null
              ? 'null'
              : "'${field.defaultValue!.replaceAll("'", "\\'")}'";
          return 'GeneratedTypeField(name: '
              "'${field.name}', "
              "type: '${field.type}', "
              'defaultValue: $defaultValue, '
              'required: ${field.required ? 'true' : 'false'})';
        })
        .join(', ');
    return 'const [$entries]';
  }

  buffer.writeln('const List<GeneratedTypeEntry> generatedTypeEntries = [');
  for (final entry in entries) {
    final effectiveUsesEvaluator =
        entry.usesEvaluator ||
        (entry.parser != null && evaluatorParsers.contains(entry.parser));
    buffer.writeln('  GeneratedTypeEntry(');
    buffer.writeln("    name: '${entry.name}',");
    buffer.writeln("    kind: '${entry.kind}',");
    if (entry.parser != null) {
      buffer.writeln("    parserName: '${entry.parser}',");
    }
    if (effectiveUsesEvaluator) {
      buffer.writeln('    usesEvaluator: true,');
    }
    if (entry.outputType != null) {
      buffer.writeln("    outputType: '${entry.outputType}',");
    }
    if (entry.aliases.isNotEmpty) {
      buffer.writeln('    aliases: ${renderStringList(entry.aliases)},');
    }
    if (entry.dropSymbols.isNotEmpty) {
      buffer.writeln(
        '    dropSymbols: ${renderStringList(entry.dropSymbols)},',
      );
    }
    if (entry.imports.isNotEmpty) {
      buffer.writeln('    imports: ${renderStringList(entry.imports)},');
    }
    if (entry.constructor != null && entry.constructor!.isNotEmpty) {
      buffer.writeln("    constructorName: '${entry.constructor}',");
    }
    if (entry.fields.isNotEmpty) {
      buffer.writeln('    fields: ${renderFields(entry.fields)},');
    }
    buffer.writeln('  ),');
  }
  buffer.writeln('];');
  buffer.writeln();
  buffer.writeln(
    'final Map<String, GeneratedTypeEntry> generatedTypeRegistry = {',
  );
  for (var i = 0; i < entries.length; i++) {
    final entry = entries[i];
    buffer.writeln("  '${entry.name}': generatedTypeEntries[$i],");
  }
  buffer.writeln('};');
  buffer.writeln();

  final valueParsers = <String>{};
  final evaluatorParserNames = <String>{};
  for (final entry in entries) {
    final parser = entry.parser;
    if (parser == null || parser.isEmpty) {
      continue;
    }
    final effectiveUsesEvaluator =
        entry.usesEvaluator || evaluatorParsers.contains(parser);
    if (effectiveUsesEvaluator) {
      evaluatorParserNames.add(parser);
    } else {
      valueParsers.add(parser);
    }
  }

  buffer.writeln(
    'final Map<String, GeneratedValueParser> generatedValueParsers = {',
  );
  for (final parser in valueParsers.toList()..sort()) {
    buffer.writeln("  '$parser': $parser,");
  }
  buffer.writeln('};');
  buffer.writeln();
  buffer.writeln(
    'final Map<String, GeneratedEvaluatorParser> generatedEvaluatorParsers = {',
  );
  for (final parser in evaluatorParserNames.toList()..sort()) {
    buffer.writeln("  '$parser': $parser,");
  }
  buffer.writeln('};');

  return buffer.toString();
}

String _renderStringListLiteral(List<String> values) {
  if (values.isEmpty) {
    return 'const []';
  }
  final entries = values
      .map((value) => "'${value.replaceAll("'", "\\'")}'")
      .join(', ');
  return 'const [$entries]';
}

String _renderClassParser(_ClassParserSpec spec, Set<String> evaluatorParsers) {
  final buffer = StringBuffer();
  final className = spec.name;
  final parserName = _generatedClassParserName(className);
  final returnType = spec.isGeneric ? 'dynamic' : className;
  final isObject = className == 'Object';
  final needsEvaluator =
      spec.usesEvaluator ||
      spec.subtypeParsers.any(
        (parser) => evaluatorParsers.contains(parser.parser),
      ) ||
      spec.constructors.any(
        (ctor) =>
            ctor.positional.any(
              (field) => evaluatorParsers.contains(field.parser),
            ) ||
            ctor.named.any((field) => evaluatorParsers.contains(field.parser)),
      );
  final signature = needsEvaluator
      ? '$returnType? $parserName(Evaluator evaluator, Object? value)'
      : '$returnType? $parserName(Object? value)';
  final supportsCommaSplit = spec.constructors.any(
    (ctor) => ctor.positional.length > 1,
  );
  final inputVar = supportsCommaSplit ? 'normalizedValue' : 'value';
  final constMapName = '_${parserName}ConstLookup';
  bool hasDefault(_ClassParserField field) =>
      field.defaultValue != null && field.defaultValue!.isNotEmpty;

  String constructorCall(_ClassConstructorSpec ctor) {
    final name = ctor.name.trim();
    if (name.isEmpty || name == 'default') {
      return className;
    }
    return '$className.$name';
  }

  String renderMapCall(
    _ClassConstructorSpec ctor,
    String mapVar, {
    String indent = '      ',
  }) {
    final buffer = StringBuffer();
    var index = 0;
    String fieldVar() => '_p${index++}';
    final fieldVars = <_ClassParserField, String>{};

    for (final field in ctor.positional) {
      final varName = fieldVar();
      fieldVars[field] = varName;
      final expr = "$mapVar['${field.name}']";
      final parsed = _renderClassFieldParse(
        field,
        expr,
        ownerClassName: className,
        evaluatorParsers: evaluatorParsers,
      );
      buffer.writeln('$indent final $varName = $parsed;');
      if (field.required || (!field.nullable && !hasDefault(field))) {
        buffer.writeln('$indent if ($varName == null) {');
        buffer.writeln('$indent  return null;');
        buffer.writeln('$indent }');
      }
    }

    for (final field in ctor.named) {
      final varName = fieldVar();
      fieldVars[field] = varName;
      final expr = "$mapVar['${field.name}']";
      final parsed = _renderClassFieldParse(
        field,
        expr,
        ownerClassName: className,
        evaluatorParsers: evaluatorParsers,
      );
      buffer.writeln('$indent final $varName = $parsed;');
      if (field.required || (!field.nullable && !hasDefault(field))) {
        buffer.writeln('$indent if ($varName == null) {');
        buffer.writeln('$indent  return null;');
        buffer.writeln('$indent }');
      }
    }

    final namedGroups = <String, List<_ClassParserField>>{};
    for (final field in ctor.named) {
      namedGroups
          .putIfAbsent(field.name, () => <_ClassParserField>[])
          .add(field);
    }
    final mergedVars = <_ClassParserField, String>{};
    final skipFields = <_ClassParserField>{};
    for (final entry in namedGroups.entries) {
      final group = entry.value;
      if (group.length <= 1) {
        continue;
      }
      for (var i = 0; i < group.length - 1; i++) {
        skipFields.add(group[i]);
      }
      final mergedVar = fieldVar();
      final parts = group.map((field) => fieldVars[field] ?? 'null').toList();
      var expr = parts.last;
      for (var i = parts.length - 2; i >= 0; i--) {
        expr = '$expr ?? ${parts[i]}';
      }
      buffer.writeln('$indent final $mergedVar = $expr;');
      mergedVars[group.last] = mergedVar;
    }

    buffer.writeln('$indent return ${constructorCall(ctor)}(');
    index = 0;
    for (final field in ctor.positional) {
      final varName = '_p${index++}';
      final valueExpr = _renderFieldValueExpression(field, varName);
      buffer.writeln('$indent  $valueExpr,');
    }
    for (final field in ctor.named) {
      if (skipFields.contains(field)) {
        index++;
        continue;
      }
      final varName = '_p${index++}';
      final mergedVar = mergedVars[field];
      final valueExpr = _renderFieldValueExpression(
        field,
        mergedVar ?? varName,
      );
      buffer.writeln('$indent  ${field.name}: $valueExpr,');
    }
    buffer.writeln('$indent);');
    return buffer.toString();
  }

  String renderListCall(
    _ClassConstructorSpec ctor,
    String listVar, {
    String indent = '      ',
  }) {
    final buffer = StringBuffer();
    var index = 0;
    for (var i = 0; i < ctor.positional.length; i++) {
      final field = ctor.positional[i];
      final varName = '_p${index++}';
      final expr = '($listVar.length > $i ? $listVar[$i] : null)';
      final parsed = _renderClassFieldParse(
        field,
        expr,
        ownerClassName: className,
        evaluatorParsers: evaluatorParsers,
      );
      buffer.writeln('$indent final $varName = $parsed;');
      if (field.required || (!field.nullable && !hasDefault(field))) {
        buffer.writeln('$indent if ($varName == null) {');
        buffer.writeln('$indent  return null;');
        buffer.writeln('$indent }');
      }
    }
    buffer.writeln('$indent return ${constructorCall(ctor)}(');
    index = 0;
    for (final field in ctor.positional) {
      final varName = '_p${index++}';
      final valueExpr = _renderFieldValueExpression(field, varName);
      buffer.writeln('$indent  $valueExpr,');
    }
    buffer.writeln('$indent);');
    return buffer.toString();
  }

  String renderScalarCall(
    _ClassConstructorSpec ctor,
    String valueExpr, {
    String indent = '      ',
  }) {
    final field = ctor.positional.first;
    final parsed = _renderClassFieldParse(
      field,
      valueExpr,
      ownerClassName: className,
      evaluatorParsers: evaluatorParsers,
    );
    final varName = '_p0';
    final buffer = StringBuffer();
    buffer.writeln('$indent final $varName = $parsed;');
    if (field.required || (!field.nullable && !hasDefault(field))) {
      buffer.writeln('$indent if ($varName == null) {');
      buffer.writeln('$indent  return null;');
      buffer.writeln('$indent }');
    }
    final value = _renderFieldValueExpression(field, varName);
    buffer.writeln('$indent return ${constructorCall(ctor)}($value);');
    return buffer.toString();
  }

  String renderPayloadParse(
    _ClassConstructorSpec ctor,
    String payloadVar, {
    String indent = '      ',
  }) {
    final buffer = StringBuffer();
    final namedKeys = [
      ...ctor.positional.map((field) => field.name),
      ...ctor.named.map((field) => field.name),
    ];
    final requiredKeys = [
      ...ctor.positional.where((field) => field.required).map((f) => f.name),
      ...ctor.named.where((field) => field.required).map((f) => f.name),
    ];
    final allowedLiteral = _renderStringListLiteral(namedKeys);
    final requiredLiteral = _renderStringListLiteral(requiredKeys);

    buffer.writeln('$indent if ($payloadVar is Map) {');
    buffer.writeln('$indent  final payloadMap = <String, Object?>{};');
    buffer.writeln(
      '$indent  $payloadVar.forEach((key, val) { payloadMap[key.toString()] = val; });',
    );
    buffer.writeln(
      '$indent  if (_matchesConstructorKeys(payloadMap, $allowedLiteral, $requiredLiteral)) {',
    );
    buffer.write(renderMapCall(ctor, 'payloadMap', indent: '$indent    '));
    buffer.writeln('$indent  }');
    buffer.writeln('$indent }');

    if (ctor.positional.isNotEmpty) {
      buffer.writeln('$indent if ($payloadVar is Iterable) {');
      buffer.writeln('$indent  final items = $payloadVar.toList();');
      buffer.writeln(
        '$indent  if (items.length >= ${ctor.requiredPositional}) {',
      );
      buffer.write(renderListCall(ctor, 'items', indent: '$indent    '));
      buffer.writeln('$indent  }');
      buffer.writeln('$indent }');
      if (ctor.positional.length == 1 && ctor.requiredPositional <= 1) {
        buffer.writeln(
          '$indent if ($payloadVar != null && $payloadVar is! Map && $payloadVar is! Iterable) {',
        );
        buffer.write(renderScalarCall(ctor, payloadVar, indent: '$indent  '));
        buffer.writeln('$indent }');
      }
    }
    buffer.writeln('$indent return null;');
    return buffer.toString();
  }

  String renderSubtypeDispatch(String mapVar, {String indent = '    '}) {
    if (spec.subtypeParsers.isEmpty) {
      return '';
    }
    final buffer = StringBuffer();
    buffer.writeln('$indent final subtypeTagValue = $mapVar[\'type\'];');
    buffer.writeln('$indent if (subtypeTagValue is String) {');
    buffer.writeln(
      '$indent  final normalizedSubtype = _normalizeTypeKey(subtypeTagValue);',
    );
    buffer.writeln(
      '$indent  final payload = $mapVar.containsKey(\'args\')'
      " ? $mapVar['args'] : $mapVar.containsKey('values') ? $mapVar['values'] : $mapVar;",
    );
    buffer.writeln('$indent  Object? normalizedPayload = payload;');
    buffer.writeln('$indent  if (payload is Map) {');
    buffer.writeln('$indent    final payloadMap = <String, Object?>{};');
    buffer.writeln(
      '$indent    payload.forEach((key, val) { payloadMap[key.toString()] = val; });',
    );
    buffer.writeln('$indent    payloadMap.remove(\'type\');');
    buffer.writeln('$indent    normalizedPayload = payloadMap;');
    buffer.writeln('$indent  }');
    buffer.writeln('$indent  switch (normalizedSubtype) {');
    for (final subtype in spec.subtypeParsers) {
      for (final key in subtype.keys) {
        buffer.writeln('$indent    case \'$key\':');
      }
      final needsEvaluator =
          subtype.usesEvaluator || evaluatorParsers.contains(subtype.parser);
      final call = needsEvaluator
          ? '${subtype.parser}(evaluator, normalizedPayload)'
          : '${subtype.parser}(normalizedPayload)';
      buffer.writeln('$indent      return $call;');
    }
    buffer.writeln('$indent  }');
    buffer.writeln('$indent }');

    buffer.writeln(
      '$indent final subtypeConstructorValue = $mapVar[\'constructor\'];',
    );
    buffer.writeln('$indent if (subtypeConstructorValue is String) {');
    buffer.writeln(
      '$indent  final normalizedSubtype = _normalizeTypeKey(subtypeConstructorValue);',
    );
    buffer.writeln(
      '$indent  final payload = $mapVar.containsKey(\'args\')'
      " ? $mapVar['args'] : $mapVar.containsKey('values') ? $mapVar['values'] : $mapVar;",
    );
    buffer.writeln('$indent  Object? normalizedPayload = payload;');
    buffer.writeln('$indent  if (payload is Map) {');
    buffer.writeln('$indent    final payloadMap = <String, Object?>{};');
    buffer.writeln(
      '$indent    payload.forEach((key, val) { payloadMap[key.toString()] = val; });',
    );
    buffer.writeln('$indent    payloadMap.remove(\'constructor\');');
    buffer.writeln('$indent    normalizedPayload = payloadMap;');
    buffer.writeln('$indent  }');
    buffer.writeln('$indent  switch (normalizedSubtype) {');
    for (final subtype in spec.subtypeParsers) {
      for (final key in subtype.keys) {
        buffer.writeln('$indent    case \'$key\':');
      }
      final needsEvaluator =
          subtype.usesEvaluator || evaluatorParsers.contains(subtype.parser);
      final call = needsEvaluator
          ? '${subtype.parser}(evaluator, normalizedPayload)'
          : '${subtype.parser}(normalizedPayload)';
      buffer.writeln('$indent      return $call;');
    }
    buffer.writeln('$indent  }');
    buffer.writeln('$indent }');

    return buffer.toString();
  }

  if (spec.constValues.isNotEmpty) {
    buffer.writeln('const Map<String, $className> $constMapName = {');
    for (final entry in spec.constValues) {
      buffer.writeln("  '${entry.key}': ${entry.expression},");
    }
    buffer.writeln('};');
    buffer.writeln();
  }

  buffer.writeln('$signature {');
  if (supportsCommaSplit) {
    buffer.writeln('  final $inputVar = _splitCommaSeparated(value);');
  }
  if (!isObject) {
    buffer.writeln('  if (value is $className) {');
    buffer.writeln('    return value;');
    buffer.writeln('  }');
  }
  if (spec.constValues.isNotEmpty) {
    buffer.writeln('  if ($inputVar is String) {');
    buffer.writeln('    final normalized = _normalizeTypeKey($inputVar);');
    buffer.writeln('    final match = $constMapName[normalized];');
    buffer.writeln('    if (match != null) {');
    buffer.writeln('      return match;');
    buffer.writeln('    }');
    buffer.writeln('  }');
  }

  if (className == 'Duration') {
    buffer.writeln('  if ($inputVar is num) {');
    buffer.writeln('    return Duration(milliseconds: $inputVar.round());');
    buffer.writeln('  }');
    buffer.writeln('  if ($inputVar is String) {');
    buffer.writeln('    final trimmed = $inputVar.trim().toLowerCase();');
    buffer.writeln('    if (trimmed.isNotEmpty) {');
    buffer.writeln('      if (trimmed.endsWith(\'ms\')) {');
    buffer.writeln(
      '        final parsed = double.tryParse(trimmed.substring(0, trimmed.length - 2).trim());',
    );
    buffer.writeln(
      '        if (parsed != null) { return Duration(milliseconds: parsed.round()); }',
    );
    buffer.writeln('      } else if (trimmed.endsWith(\'s\')) {');
    buffer.writeln(
      '        final parsed = double.tryParse(trimmed.substring(0, trimmed.length - 1).trim());',
    );
    buffer.writeln(
      '        if (parsed != null) { return Duration(milliseconds: (parsed * 1000).round()); }',
    );
    buffer.writeln('      }');
    buffer.writeln('    }');
    buffer.writeln('  }');
  } else if (className == 'DateTime') {
    buffer.writeln('  if ($inputVar is String) {');
    buffer.writeln('    final parsed = DateTime.tryParse($inputVar.trim());');
    buffer.writeln('    if (parsed != null) {');
    buffer.writeln('      return parsed;');
    buffer.writeln('    }');
    buffer.writeln('  }');
  } else if (className == 'TimeOfDay') {
    buffer.writeln('  if ($inputVar is String) {');
    buffer.writeln('    final text = $inputVar.trim();');
    buffer.writeln('    final parts = text.split(\':\');');
    buffer.writeln('    if (parts.length >= 2) {');
    buffer.writeln('      final hour = int.tryParse(parts[0]);');
    buffer.writeln('      final minute = int.tryParse(parts[1]);');
    buffer.writeln('      if (hour != null && minute != null) {');
    buffer.writeln('        return TimeOfDay(hour: hour, minute: minute);');
    buffer.writeln('      }');
    buffer.writeln('    }');
    buffer.writeln('  }');
  }

  if (spec.constructors.isNotEmpty || spec.subtypeParsers.isNotEmpty) {
    buffer.writeln('  if ($inputVar is Map) {');
    buffer.writeln('    final map = <String, Object?>{};');
    buffer.writeln(
      '    $inputVar.forEach((key, val) { map[key.toString()] = val; });',
    );
    final subtypeDispatch = renderSubtypeDispatch('map', indent: '    ');
    if (subtypeDispatch.isNotEmpty) {
      buffer.writeln(subtypeDispatch);
    }
    if (spec.constructors.isNotEmpty) {
      buffer.writeln(
        "    final constructorValue = map.remove('constructor') ?? map.remove('type');",
      );

      buffer.writeln('    if (constructorValue is String) {');
      buffer.writeln('      switch (_normalizeTypeKey(constructorValue)) {');
      for (final ctor in spec.constructors) {
        final ctorKey = _normalizeLookupKey(
          ctor.name.isEmpty ? 'default' : ctor.name,
        );
        if (ctorKey.isEmpty) {
          continue;
        }
        buffer.writeln("        case '$ctorKey': {");
        buffer.writeln(
          '          final payload = map.containsKey(\'args\')'
          " ? map['args'] : map.containsKey('values') ? map['values'] : map;",
        );
        buffer.write(renderPayloadParse(ctor, 'payload', indent: '          '));
        buffer.writeln('        }');
      }
      buffer.writeln('      }');
      buffer.writeln('    }');

      buffer.writeln('    if (map.length == 1) {');
      buffer.writeln('      final key = map.keys.first;');
      buffer.writeln('      final normalized = _normalizeTypeKey(key);');
      buffer.writeln('      final payload = map.values.first;');
      for (final ctor in spec.constructors) {
        final ctorKey = _normalizeLookupKey(
          ctor.name.isEmpty ? 'default' : ctor.name,
        );
        if (ctorKey.isEmpty) {
          continue;
        }
        buffer.writeln("      if (normalized == '$ctorKey') {");
        buffer.write(renderPayloadParse(ctor, 'payload', indent: '        '));
        buffer.writeln('      }');
      }
      buffer.writeln('    }');

      for (final ctor in spec.constructors.where((c) => c.positional.isEmpty)) {
        final allowed = _renderStringListLiteral(
          ctor.named.map((f) => f.name).toList(),
        );
        final required = _renderStringListLiteral(
          ctor.named.where((f) => f.required).map((f) => f.name).toList(),
        );
        buffer.writeln(
          '    if (_matchesConstructorKeys(map, $allowed, $required)) {',
        );
        buffer.write(renderMapCall(ctor, 'map', indent: '      '));
        buffer.writeln('    }');
      }
    }
    buffer.writeln('  }');

    final positionalConstructors =
        spec.constructors.where((ctor) => ctor.positional.isNotEmpty).toList()
          ..sort((a, b) {
            final required = b.requiredPositional.compareTo(
              a.requiredPositional,
            );
            if (required != 0) {
              return required;
            }
            return b.positional.length.compareTo(a.positional.length);
          });

    if (positionalConstructors.isNotEmpty) {
      buffer.writeln('  if ($inputVar is Iterable) {');
      buffer.writeln('    final items = $inputVar.toList();');
      for (final ctor in positionalConstructors) {
        buffer.writeln('    if (items.length >= ${ctor.requiredPositional}) {');
        buffer.write(renderListCall(ctor, 'items', indent: '      '));
        buffer.writeln('    }');
      }
      buffer.writeln('  }');
    }

    final scalarConstructors = positionalConstructors
        .where(
          (ctor) => ctor.positional.length == 1 && ctor.requiredPositional <= 1,
        )
        .toList();
    if (scalarConstructors.isNotEmpty) {
      final ctor = scalarConstructors.first;
      buffer.writeln(
        '  if ($inputVar != null && $inputVar is! Map && $inputVar is! Iterable) {',
      );
      buffer.write(renderScalarCall(ctor, inputVar, indent: '    '));
      buffer.writeln('  }');
    }
  }

  if (isObject) {
    buffer.writeln('  return value;');
  } else {
    buffer.writeln('  return null;');
  }
  buffer.writeln('}');

  return buffer.toString();
}

List<_CollectionParserSpec> _collectCollectionParsers(_TypeRegistry registry) {
  final specs = <_CollectionParserSpec>[];
  for (final entry in registry.entries.values) {
    final info = _parseCollectionType(entry.name);
    if (info == null) {
      continue;
    }
    final normalizedElementType = _normalizeTypeName(info.elementType);
    final lookupElementType = _containsTypeParameter(normalizedElementType)
        ? _baseTypeName(normalizedElementType)
        : normalizedElementType;
    final elementEntry = registry.lookup(
      lookupElementType,
      fullTypeName: lookupElementType,
    );
    if (elementEntry == null || elementEntry.parser == null) {
      continue;
    }
    final parserName =
        entry.parser ??
        _generatedCollectionParserName(info.base, info.elementType);
    final rawElementType =
        elementEntry.outputType ?? _normalizeTypeName(info.elementType);
    final elementType = _containsTypeParameter(rawElementType)
        ? _baseTypeName(rawElementType)
        : rawElementType;
    final imports = <String>{};
    if (elementEntry.imports.isNotEmpty) {
      imports.addAll(elementEntry.imports);
    }
    specs.add(
      _CollectionParserSpec(
        name: parserName,
        collectionType: info.base,
        elementType: elementType,
        elementParser: elementEntry.parser!,
        usesEvaluator: elementEntry.usesEvaluator,
        imports: imports.toList()..sort(),
      ),
    );
  }
  specs.sort((a, b) => a.name.compareTo(b.name));
  return specs;
}

String _renderCollectionParser(
  _CollectionParserSpec spec,
  Set<String> evaluatorParsers,
) {
  final buffer = StringBuffer();
  final needsEvaluator =
      spec.usesEvaluator || evaluatorParsers.contains(spec.elementParser);
  final signature = needsEvaluator
      ? '${spec.collectionType}<${spec.elementType}>? ${spec.name}(Evaluator evaluator, Object? value)'
      : '${spec.collectionType}<${spec.elementType}>? ${spec.name}(Object? value)';
  String parserCall(String expr) => needsEvaluator
      ? '${spec.elementParser}(evaluator, $expr)'
      : '${spec.elementParser}($expr)';
  final collectionLiteral = spec.collectionType == 'Set'
      ? '<${spec.elementType}>{}'
      : '<${spec.elementType}>[]';
  final returnCollection = spec.collectionType == 'Set'
      ? '{parsed}'
      : '[parsed]';

  buffer.writeln('$signature {');
  buffer.writeln('  if (value == null) {');
  buffer.writeln('    return null;');
  buffer.writeln('  }');
  if (spec.elementType == 'String') {
    buffer.writeln('  if (value is String && value.contains(\',\')) {');
    buffer.writeln('    final parts = value');
    buffer.writeln('        .split(\',\')');
    buffer.writeln('        .map((entry) => entry.trim())');
    buffer.writeln('        .where((entry) => entry.isNotEmpty)');
    buffer.writeln('        .toList();');
    buffer.writeln('    if (parts.isNotEmpty) {');
    buffer.writeln('      return parts;');
    buffer.writeln('    }');
    buffer.writeln('  }');
  }
  buffer.writeln(
    '  if (value is ${spec.collectionType}<${spec.elementType}>) {',
  );
  buffer.writeln('    return value;');
  buffer.writeln('  }');
  buffer.writeln('  if (value is Iterable) {');
  buffer.writeln('    final items = $collectionLiteral;');
  buffer.writeln('    for (final entry in value) {');
  buffer.writeln('      final parsed = ${parserCall('entry')};');
  buffer.writeln('      if (parsed != null) {');
  buffer.writeln('        items.add(parsed);');
  buffer.writeln('      }');
  buffer.writeln('    }');
  buffer.writeln('    return items.isEmpty ? null : items;');
  buffer.writeln('  }');
  buffer.writeln('  final parsed = ${parserCall('value')};');
  buffer.writeln('  if (parsed == null) {');
  buffer.writeln('    return null;');
  buffer.writeln('  }');
  buffer.writeln('  return $returnCollection;');
  buffer.writeln('}');
  return buffer.toString();
}

List<_WrapperParserSpec> _collectWrapperParsers(_TypeRegistry registry) {
  final specs = <_WrapperParserSpec>[];
  for (final entry in registry.entries.values) {
    if (entry.kind != 'wrapper') {
      continue;
    }
    final info = _parseWrapperType(entry.name);
    if (info == null) {
      continue;
    }
    final normalizedElementType = _normalizeTypeName(info.elementType);
    final lookupElementType = _containsTypeParameter(normalizedElementType)
        ? _baseTypeName(normalizedElementType)
        : normalizedElementType;
    final elementEntry = registry.lookup(
      lookupElementType,
      fullTypeName: lookupElementType,
    );
    if (elementEntry == null || elementEntry.parser == null) {
      continue;
    }
    final parserName =
        entry.parser ??
        _generatedWrapperParserName(info.base, info.elementType);
    final rawElementType =
        elementEntry.outputType ?? _normalizeTypeName(info.elementType);
    final elementType = _containsTypeParameter(rawElementType)
        ? _baseTypeName(rawElementType)
        : rawElementType;
    final imports = <String>{};
    if (elementEntry.imports.isNotEmpty) {
      imports.addAll(elementEntry.imports);
    }
    specs.add(
      _WrapperParserSpec(
        name: parserName,
        wrapperType: info.base,
        elementType: elementType,
        elementParser: elementEntry.parser!,
        usesEvaluator: elementEntry.usesEvaluator,
        imports: imports.toList()..sort(),
      ),
    );
  }
  specs.sort((a, b) => a.name.compareTo(b.name));
  return specs;
}

String _renderWrapperParser(
  _WrapperParserSpec spec,
  Set<String> evaluatorParsers,
) {
  final buffer = StringBuffer();
  final needsEvaluator =
      spec.usesEvaluator || evaluatorParsers.contains(spec.elementParser);
  final signature = needsEvaluator
      ? '${spec.wrapperType}<${spec.elementType}>? ${spec.name}(Evaluator evaluator, Object? value)'
      : '${spec.wrapperType}<${spec.elementType}>? ${spec.name}(Object? value)';
  String parserCall(String expr) => needsEvaluator
      ? '${spec.elementParser}(evaluator, $expr)'
      : '${spec.elementParser}($expr)';

  buffer.writeln('$signature {');
  buffer.writeln('  if (value == null) {');
  buffer.writeln('    return null;');
  buffer.writeln('  }');
  buffer.writeln('  if (value is ${spec.wrapperType}<${spec.elementType}>) {');
  buffer.writeln('    return value;');
  buffer.writeln('  }');
  buffer.writeln('  final parsed = ${parserCall('value')};');
  buffer.writeln('  if (parsed == null) {');
  buffer.writeln('    return null;');
  buffer.writeln('  }');
  buffer.writeln(
    '  return AlwaysStoppedAnimation<${spec.elementType}>(parsed);',
  );
  buffer.writeln('}');
  return buffer.toString();
}

String _renderClassFieldParse(
  _ClassParserField field,
  String valueExpr, {
  String? ownerClassName,
  required Set<String> evaluatorParsers,
}) {
  final usesEvaluator =
      field.usesEvaluator || evaluatorParsers.contains(field.parser);
  var parsed = usesEvaluator
      ? '${field.parser}(evaluator, $valueExpr)'
      : '${field.parser}($valueExpr)';
  if (ownerClassName == 'Color' && field.name == 'value') {
    return '_normalizeColorInt($parsed)';
  }
  if (field.parserOutputType != null &&
      field.parserOutputType!.isNotEmpty &&
      field.parserOutputType != field.type) {
    parsed = '($parsed as ${field.type}?)';
  }
  return parsed;
}

String _renderFieldValueExpression(_ClassParserField field, String varName) {
  var expr = varName;
  if (field.defaultValue != null && field.defaultValue!.isNotEmpty) {
    expr = '$varName ?? ${field.defaultValue}';
  }
  if (!field.nullable) {
    expr = '($expr)!';
  }
  return expr;
}

String _renderCallbackDrops(List<_CallbackDropSpec> specs) {
  final buffer = StringBuffer();
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.');
  buffer.writeln('// Generated by widget_spec_builder.');
  buffer.writeln();
  if (specs.isEmpty) {
    return buffer.toString();
  }
  final importSet = <String>{
    'package:liquify/liquify.dart',
    'package:flutter/widgets.dart',
  };
  for (final spec in specs) {
    if (spec.imports.isNotEmpty) {
      importSet.addAll(spec.imports);
    }
  }
  final imports = importSet.toList()..sort();
  for (final entry in imports) {
    buffer.writeln("import '$entry';");
  }
  buffer.writeln();

  for (final spec in specs) {
    final className = _callbackDropClassName(spec.name);
    buffer.writeln('class $className extends Drop {');
    buffer.writeln('  $className(this.callback) {');
    if (spec.symbols.isNotEmpty) {
      final symbols = spec.symbols.map((value) => '#$value').join(', ');
      buffer.writeln('    invokable = const [$symbols];');
    }
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  final ${spec.type} callback;');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  dynamic invoke(Symbol symbol) {');
    buffer.writeln('    callback();');
    buffer.writeln('    return null;');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();
  }
  return buffer.toString();
}

String _callbackDropClassName(String name) {
  final sanitized = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  return 'Generated${sanitized}Drop';
}

List<Map<String, Object?>> _buildRegistryBootstrap({
  required _TypeGraph typeGraph,
  required _TypeRegistry registry,
  required Map<String, _ResolvedClass> classIndex,
  required Map<String, _ResolvedEnum> enumIndex,
  required Map<String, _ResolvedAlias> typedefIndex,
  required List<_ConstFieldSpec> constIndex,
}) {
  final suggestions = <Map<String, Object?>>[];
  final existingNames = <String>{
    ...registry.entries.keys,
    ...registry.aliases.keys,
  };
  final seen = <String>{};

  final queue = Queue<String>();
  final skippedEntries = typeGraph.skipped.values.toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  for (final entry in skippedEntries) {
    if (entry.reason == 'widget_type') {
      continue;
    }
    queue.add(entry.name);
  }

  void enqueueTypeName(String typeName) {
    if (typeName.isEmpty) {
      return;
    }
    final normalized = _normalizeTypeName(typeName);
    if (_looksLikeWidgetTypeName(normalized)) {
      return;
    }
    queue.add(normalized);
  }

  void enqueueConstructorTypes(ClassElement element) {
    for (final constructor in element.constructors) {
      for (final param in constructor.formalParameters) {
        if (_isWidgetType(param.type) || _isWidgetList(param.type)) {
          continue;
        }
        final typeName = _normalizeTypeName(_typeDisplayName(param.type));
        enqueueTypeName(typeName);
      }
    }
  }

  while (queue.isNotEmpty) {
    final rawName = queue.removeFirst();
    if (rawName.isEmpty) {
      continue;
    }
    final normalizedName = _normalizeTypeName(rawName);

    final wrapperInfo = _parseWrapperType(normalizedName);
    if (wrapperInfo != null) {
      final key = normalizedName;
      if (!existingNames.contains(key) && !seen.contains(key)) {
        final suggestion = _buildWrapperSuggestion(
          key,
          wrapperInfo,
          classIndex,
          enumIndex,
        );
        if (suggestion != null) {
          suggestions.add(suggestion);
          seen.add(key);
        }
      }
      enqueueTypeName(wrapperInfo.elementType);
      continue;
    }

    final collectionInfo = _parseCollectionType(normalizedName);
    if (collectionInfo != null) {
      final key = normalizedName;
      if (!existingNames.contains(key) && !seen.contains(key)) {
        final suggestion = _buildCollectionSuggestion(
          key,
          collectionInfo,
          classIndex,
          enumIndex,
        );
        if (suggestion != null) {
          suggestions.add(suggestion);
          seen.add(key);
        }
      }
      if (collectionInfo.base != 'Map') {
        enqueueTypeName(collectionInfo.elementType);
      }
      continue;
    }

    final baseName = _baseTypeName(normalizedName);
    if (existingNames.contains(baseName) || seen.contains(baseName)) {
      continue;
    }

    final resolvedEnum = enumIndex[baseName];
    if (resolvedEnum != null) {
      suggestions.add(_buildEnumSuggestion(baseName, resolvedEnum.library));
      seen.add(baseName);
      continue;
    }

    final resolvedAlias = typedefIndex[baseName];
    if (resolvedAlias != null) {
      final callbackSuggestion = _buildCallbackSuggestion(
        resolvedAlias.element,
        resolvedAlias.library,
      );
      if (callbackSuggestion != null) {
        suggestions.add(callbackSuggestion);
        seen.add(baseName);
        continue;
      }
    }

    final resolvedClass = classIndex[baseName];
    if (resolvedClass != null) {
      final classSuggestion = _buildClassSuggestion(
        resolvedClass.element,
        resolvedClass.library,
        constIndex,
        classIndex,
      );
      if (classSuggestion != null) {
        suggestions.add(classSuggestion);
        seen.add(baseName);
        if (resolvedClass.element.isAbstract) {
          final subtypes = _collectConcreteSubtypes(
            resolvedClass.element,
            classIndex,
          );
          for (final subtype in subtypes) {
            enqueueTypeName(subtype.element.name ?? '');
          }
        }
        enqueueConstructorTypes(resolvedClass.element);
        continue;
      }
    }

    if (_looksLikeFunctionType(normalizedName) &&
        !seen.contains(normalizedName)) {
      final callbackSuggestion = _buildFunctionSignatureSuggestion(
        normalizedName,
      );
      if (callbackSuggestion != null) {
        suggestions.add(callbackSuggestion);
        seen.add(normalizedName);
      }
    }
  }

  return suggestions;
}

Map<String, Object?> _buildEnumSuggestion(String name, String library) {
  final entry = <String, Object?>{
    'name': name,
    'kind': 'enum',
    'parser': _generatedEnumParserName(name),
  };
  if (library.isNotEmpty && !library.startsWith('dart:core')) {
    entry['imports'] = [library];
  }
  return entry;
}

Map<String, Object?>? _buildCallbackSuggestion(
  TypeAliasElement alias,
  String library,
) {
  final aliased = alias.aliasedType;
  if (aliased is! FunctionType) {
    return null;
  }
  final parserSpec = _suggestCallbackParser(aliased);
  final entry = <String, Object?>{'name': alias.name ?? '', 'kind': 'callback'};
  if (library.isNotEmpty && !library.startsWith('dart:core')) {
    entry['imports'] = [library];
  }
  if (parserSpec != null) {
    entry['parser'] = parserSpec.parser;
    if (parserSpec.usesEvaluator) {
      entry['usesEvaluator'] = true;
    }
    if (parserSpec.dropSymbols.isNotEmpty) {
      entry['dropSymbols'] = parserSpec.dropSymbols;
    }
    if (parserSpec.outputType != null) {
      entry['output'] = parserSpec.outputType;
    }
  }
  return entry;
}

Map<String, Object?>? _buildFunctionSignatureSuggestion(String name) {
  final trimmedName = name.trim();
  final entry = <String, Object?>{'name': trimmedName, 'kind': 'callback'};
  if (trimmedName.isEmpty) {
    return entry;
  }
  final match = RegExp(r'^(.+?)\s+Function\((.*)\)$').firstMatch(trimmedName);
  if (match == null) {
    return entry;
  }
  final rawReturn = match.group(1)?.trim() ?? '';
  var rawParams = match.group(2)?.trim() ?? '';
  final hasNamedParams = rawParams.contains('{') || rawParams.contains('[');
  if (hasNamedParams) {
    entry['parser'] = 'resolveCallbackValue';
    entry['usesEvaluator'] = true;
    entry['output'] = 'Function';
    return entry;
  }
  if (rawParams.isEmpty) {
    rawParams = '';
  }
  final paramTypes = rawParams.isEmpty
      ? const <String>[]
      : _splitFunctionParamTypes(rawParams);
  final parserSpec = _suggestCallbackParserFromSignature(rawReturn, paramTypes);
  if (parserSpec != null) {
    entry['parser'] = parserSpec.parser;
    if (parserSpec.usesEvaluator) {
      entry['usesEvaluator'] = true;
    }
    if (parserSpec.dropSymbols.isNotEmpty) {
      entry['dropSymbols'] = parserSpec.dropSymbols;
    }
    if (parserSpec.outputType != null) {
      entry['output'] = parserSpec.outputType;
    }
  }
  return entry;
}

List<String> _splitFunctionParamTypes(String rawParams) {
  final params = <String>[];
  final buffer = StringBuffer();
  var depth = 0;
  for (var i = 0; i < rawParams.length; i++) {
    final char = rawParams[i];
    if (char == '<') {
      depth++;
    } else if (char == '>') {
      if (depth > 0) depth--;
    } else if (char == ',' && depth == 0) {
      params.add(_stripParamName(buffer.toString()));
      buffer.clear();
      continue;
    }
    buffer.write(char);
  }
  final tail = buffer.toString().trim();
  if (tail.isNotEmpty) {
    params.add(_stripParamName(tail));
  }
  return params;
}

String _stripParamName(String raw) {
  final trimmed = raw.trim();
  final match = RegExp(r'^(.+?)\s+[A-Za-z_][A-Za-z0-9_]*$').firstMatch(trimmed);
  if (match != null) {
    return match.group(1)!.trim();
  }
  return trimmed;
}

_CallbackParserSpec? _suggestCallbackParserFromSignature(
  String returnTypeRaw,
  List<String> paramTypes,
) {
  final returnType = _normalizeTypeName(returnTypeRaw);
  final returnsVoid = returnType == 'void';
  final returnsBool = returnType == 'bool';
  final returnsWidget = returnType == 'Widget';
  final returnsWidgetList =
      returnType == 'List<Widget>' || returnType == 'List<Widget?>';
  final returnsFutureBool =
      returnType == 'Future<bool>' || returnType == 'Future<bool?>';

  if (paramTypes.isEmpty) {
    if (returnsFutureBool) {
      return _CallbackParserSpec(
        parser: 'resolveFutureBoolCallback0',
        usesEvaluator: true,
        outputType: 'Future<bool> Function()',
      );
    }
    if (!returnsVoid) {
      return _CallbackParserSpec(
        parser: 'resolveGenericCallback0',
        usesEvaluator: true,
        outputType: 'Object? Function()',
      );
    }
    return _CallbackParserSpec(
      parser: 'resolveActionCallback',
      usesEvaluator: true,
      dropSymbols: const ['tap', 'clicked'],
    );
  }

  if (paramTypes.length == 1) {
    final rawParam = paramTypes.first;
    final isNullable = rawParam.trim().endsWith('?');
    final paramType = _normalizeTypeName(rawParam);
    if (returnsWidget && paramType == 'BuildContext') {
      return _CallbackParserSpec(
        parser: 'resolveWidgetBuilderCallback',
        usesEvaluator: true,
      );
    }
    if (returnsWidgetList && paramType == 'BuildContext') {
      return _CallbackParserSpec(
        parser: 'resolveWidgetListBuilderCallback',
        usesEvaluator: true,
      );
    }
    if (returnsFutureBool) {
      return _CallbackParserSpec(
        parser: 'resolveFutureBoolCallback1',
        usesEvaluator: true,
        outputType: 'Future<bool?> Function(Object?)',
      );
    }
    if (returnsBool) {
      return _CallbackParserSpec(
        parser: 'resolveBoolPredicateCallback',
        usesEvaluator: true,
      );
    }
    if (returnsVoid) {
      if (isNullable) {
        return _CallbackParserSpec(
          parser: 'resolveGenericValueChanged',
          usesEvaluator: true,
        );
      }
      switch (paramType) {
        case 'bool':
          return _CallbackParserSpec(
            parser: 'resolveBoolActionCallback',
            usesEvaluator: true,
          );
        case 'String':
          return _CallbackParserSpec(
            parser: 'resolveStringActionCallback',
            usesEvaluator: true,
          );
        case 'double':
          return _CallbackParserSpec(
            parser: 'resolveDoubleActionCallback',
            usesEvaluator: true,
          );
        case 'int':
          return _CallbackParserSpec(
            parser: 'resolveIntActionCallback',
            usesEvaluator: true,
          );
        case 'Set<int>':
          return _CallbackParserSpec(
            parser: 'resolveIntSetActionCallback',
            usesEvaluator: true,
          );
      }
      return _CallbackParserSpec(
        parser: 'resolveGenericValueChanged',
        usesEvaluator: true,
      );
    }
    if (paramType == 'BuildContext') {
      return _CallbackParserSpec(
        parser: 'resolveBuildContextCallback',
        usesEvaluator: true,
        outputType: 'Object? Function(BuildContext)',
      );
    }
    return _CallbackParserSpec(
      parser: 'resolveGenericCallback1',
      usesEvaluator: true,
      outputType: 'Object? Function(Object?)',
    );
  }

  if (paramTypes.length == 2) {
    final paramA = _normalizeTypeName(paramTypes[0]);
    final paramB = _normalizeTypeName(paramTypes[1]);
    if (returnsWidget && paramA == 'BuildContext') {
      return _CallbackParserSpec(
        parser: 'resolveWidgetBuilder2Callback',
        usesEvaluator: true,
        outputType: 'Widget Function(BuildContext, Object?)',
      );
    }
    if (returnsWidgetList && paramA == 'BuildContext') {
      return _CallbackParserSpec(
        parser: 'resolveWidgetListBuilder2Callback',
        usesEvaluator: true,
        outputType: 'List<Widget> Function(BuildContext, Object?)',
      );
    }
    if (returnsVoid) {
      if (paramA == 'int' && paramB == 'int') {
        return _CallbackParserSpec(
          parser: 'resolveReorderActionCallback',
          usesEvaluator: true,
        );
      }
      if (paramA == 'int' && paramB == 'bool') {
        return _CallbackParserSpec(
          parser: 'resolveSortActionCallback',
          usesEvaluator: true,
        );
      }
      return _CallbackParserSpec(
        parser: 'resolveGenericActionCallback2',
        usesEvaluator: true,
        outputType: 'void Function(Object?, Object?)',
      );
    }
    if (paramA == 'BuildContext') {
      return _CallbackParserSpec(
        parser: 'resolveBuildContextCallback2',
        usesEvaluator: true,
        outputType: 'Object? Function(BuildContext, Object?)',
      );
    }
    return _CallbackParserSpec(
      parser: 'resolveGenericCallback2',
      usesEvaluator: true,
      outputType: 'Object? Function(Object?, Object?)',
    );
  }

  return _CallbackParserSpec(
    parser: 'resolveCallbackValue',
    usesEvaluator: true,
    outputType: 'Function',
  );
}

Map<String, Object?>? _buildClassSuggestion(
  ClassElement element,
  String library,
  List<_ConstFieldSpec> constIndex,
  Map<String, _ResolvedClass> classIndex,
) {
  final className = element.name ?? '';
  if (className.isEmpty) {
    return null;
  }
  final staticConstNames = element.fields
      .where((field) => field.isStatic && field.isConst && !field.isPrivate)
      .map((field) => field.name ?? '')
      .where((name) => name.isNotEmpty)
      .toSet();

  final constructors = <Map<String, Object?>>[];
  for (final constructor in element.constructors) {
    if (constructor.isPrivate) {
      continue;
    }
    final positional = <Map<String, Object?>>[];
    final named = <Map<String, Object?>>[];
    for (final param in constructor.formalParameters) {
      final paramName = param.name;
      if (paramName == null || paramName.isEmpty) {
        continue;
      }
      final typeName = _normalizeTypeName(_typeDisplayName(param.type));
      final field = <String, Object?>{'name': paramName, 'type': typeName};
      final defaultValue = _resolveDefaultValue(
        param,
        className,
        staticConstNames,
      );
      if (defaultValue != null) {
        field['default'] = defaultValue;
      }
      if (param.isRequiredNamed || param.isRequiredPositional) {
        field['required'] = true;
      }
      if (param.isPositional) {
        positional.add(field);
      } else if (param.isNamed) {
        named.add(field);
      }
    }
    constructors.add(<String, Object?>{
      'name': constructor.name ?? '',
      if (positional.isNotEmpty) 'positional': positional,
      if (named.isNotEmpty) 'named': named,
    });
  }

  final hasConstLookup = _classHasConstLookup(element, constIndex);
  final hasSubtypeLookup =
      element.isAbstract && _classHasSubtypeLookup(element, classIndex);
  if (constructors.isEmpty && !hasConstLookup && !hasSubtypeLookup) {
    return null;
  }

  final entry = <String, Object?>{
    'name': className,
    'kind': 'class',
    'parser': _generatedClassParserName(className),
  };

  final legacyConstructor =
      element.unnamedConstructor ??
      (element.constructors.isNotEmpty ? element.constructors.first : null);
  if (legacyConstructor != null) {
    final legacyFields = <Map<String, Object?>>[];
    for (final param in legacyConstructor.formalParameters) {
      if (!param.isNamed) {
        continue;
      }
      final paramName = param.name;
      if (paramName == null || paramName.isEmpty) {
        continue;
      }
      final typeName = _normalizeTypeName(_typeDisplayName(param.type));
      final field = <String, Object?>{'name': paramName, 'type': typeName};
      final defaultValue = _resolveDefaultValue(
        param,
        className,
        staticConstNames,
      );
      if (defaultValue != null) {
        field['default'] = defaultValue;
      }
      if (param.isRequiredNamed) {
        field['required'] = true;
      }
      legacyFields.add(field);
    }
    if (legacyFields.isNotEmpty) {
      final legacyName = legacyConstructor.name ?? '';
      entry['constructor'] = legacyName.isEmpty ? 'default' : legacyName;
      entry['fields'] = legacyFields;
    }
  }

  if (constructors.isNotEmpty) {
    entry['constructors'] = constructors;
  }
  if (library.isNotEmpty && !library.startsWith('dart:core')) {
    entry['imports'] = [library];
  }
  return entry;
}

bool _classHasConstLookup(
  ClassElement element,
  List<_ConstFieldSpec> constIndex,
) {
  final typeSystem = element.library.typeSystem;
  final targetType = element.thisType;
  for (final field in constIndex) {
    if (typeSystem.isAssignableTo(field.type, targetType)) {
      return true;
    }
  }
  return false;
}

bool _classHasSubtypeLookup(
  ClassElement element,
  Map<String, _ResolvedClass> classIndex,
) {
  if (!element.isAbstract) {
    return false;
  }
  final typeSystem = element.library.typeSystem;
  final targetType = element.thisType;
  for (final entry in classIndex.values) {
    final candidate = entry.element;
    if (candidate.name == null ||
        candidate.name == element.name ||
        candidate.name!.startsWith('_')) {
      continue;
    }
    if (candidate.isAbstract) {
      continue;
    }
    if (typeSystem.isAssignableTo(candidate.thisType, targetType)) {
      return true;
    }
  }
  return false;
}

Map<String, Object?>? _buildCollectionSuggestion(
  String typeName,
  _CollectionTypeInfo info,
  Map<String, _ResolvedClass> classIndex,
  Map<String, _ResolvedEnum> enumIndex,
) {
  if (info.base == 'Map') {
    return null;
  }
  final parserName = _generatedCollectionParserName(
    info.base,
    info.elementType,
  );
  final entry = <String, Object?>{
    'name': typeName,
    'kind': 'collection',
    'parser': parserName,
  };
  final elementBase = _baseTypeName(info.elementType);
  final resolvedClass = classIndex[elementBase];
  if (resolvedClass != null &&
      resolvedClass.library.isNotEmpty &&
      !resolvedClass.library.startsWith('dart:core')) {
    entry['imports'] = [resolvedClass.library];
    return entry;
  }
  final resolvedEnum = enumIndex[elementBase];
  if (resolvedEnum != null &&
      resolvedEnum.library.isNotEmpty &&
      !resolvedEnum.library.startsWith('dart:core')) {
    entry['imports'] = [resolvedEnum.library];
  }
  return entry;
}

Map<String, Object?>? _buildWrapperSuggestion(
  String typeName,
  _WrapperTypeInfo info,
  Map<String, _ResolvedClass> classIndex,
  Map<String, _ResolvedEnum> enumIndex,
) {
  final parserName = _generatedWrapperParserName(info.base, info.elementType);
  final entry = <String, Object?>{
    'name': typeName,
    'kind': 'wrapper',
    'parser': parserName,
    'outputType': typeName,
  };
  final imports = <String>{};
  final baseClass = classIndex[info.base];
  if (baseClass != null &&
      baseClass.library.isNotEmpty &&
      !baseClass.library.startsWith('dart:core')) {
    imports.add(baseClass.library);
  }
  final elementBase = _baseTypeName(info.elementType);
  final resolvedClass = classIndex[elementBase];
  if (resolvedClass != null &&
      resolvedClass.library.isNotEmpty &&
      !resolvedClass.library.startsWith('dart:core')) {
    imports.add(resolvedClass.library);
  }
  final resolvedEnum = enumIndex[elementBase];
  if (resolvedEnum != null &&
      resolvedEnum.library.isNotEmpty &&
      !resolvedEnum.library.startsWith('dart:core')) {
    imports.add(resolvedEnum.library);
  }
  if (imports.isNotEmpty) {
    entry['imports'] = imports.toList()..sort();
  }
  return entry;
}

_CollectionTypeInfo? _parseCollectionType(String typeName) {
  final start = typeName.indexOf('<');
  final end = typeName.lastIndexOf('>');
  if (start == -1 || end == -1 || end <= start + 1) {
    return null;
  }
  final base = typeName.substring(0, start).trim();
  if (!_isCollectionType(base)) {
    return null;
  }
  final elementType = typeName.substring(start + 1, end).trim();
  if (elementType.isEmpty) {
    return null;
  }
  return _CollectionTypeInfo(base: base, elementType: elementType);
}

_WrapperTypeInfo? _parseWrapperType(String typeName) {
  final start = typeName.indexOf('<');
  final end = typeName.lastIndexOf('>');
  if (start == -1 || end == -1 || end <= start + 1) {
    return null;
  }
  final base = typeName.substring(0, start).trim();
  if (!_isWrapperType(base)) {
    return null;
  }
  final elementType = typeName.substring(start + 1, end).trim();
  if (elementType.isEmpty) {
    return null;
  }
  return _WrapperTypeInfo(base: base, elementType: elementType);
}

String _generatedCollectionParserName(String base, String elementType) {
  final sanitized = elementType.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  final suffix = sanitized.isEmpty
      ? 'Value'
      : '${sanitized[0].toUpperCase()}${sanitized.substring(1)}';
  return 'parseGenerated${base}Of$suffix';
}

String _generatedWrapperParserName(String base, String elementType) {
  final sanitized = elementType.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  final suffix = sanitized.isEmpty
      ? 'Value'
      : '${sanitized[0].toUpperCase()}${sanitized.substring(1)}';
  return 'parseGenerated${base}Of$suffix';
}

bool _looksLikeFunctionType(String name) {
  return name.startsWith('void Function') || name.contains(' Function(');
}

class _CallbackParserSpec {
  _CallbackParserSpec({
    required this.parser,
    required this.usesEvaluator,
    this.dropSymbols = const [],
    this.outputType,
  });

  final String parser;
  final bool usesEvaluator;
  final List<String> dropSymbols;
  final String? outputType;
}

_CallbackParserSpec? _suggestCallbackParser(FunctionType functionType) {
  final params = functionType.formalParameters.toList();
  final returnType = _normalizeTypeName(
    _typeDisplayName(functionType.returnType),
  );
  final returnsVoid = returnType == 'void';
  final returnsBool = returnType == 'bool';
  final returnsWidget = returnType == 'Widget';
  final returnsWidgetList =
      returnType == 'List<Widget>' || returnType == 'List<Widget?>';
  final returnsFutureBool =
      returnType == 'Future<bool>' || returnType == 'Future<bool?>';
  final hasNamedParams = params.any((param) => param.isNamed);

  if (hasNamedParams) {
    return _CallbackParserSpec(
      parser: 'resolveCallbackValue',
      usesEvaluator: true,
      outputType: 'Function',
    );
  }

  if (params.isEmpty) {
    if (returnsFutureBool) {
      return _CallbackParserSpec(
        parser: 'resolveFutureBoolCallback0',
        usesEvaluator: true,
        outputType: 'Future<bool> Function()',
      );
    }
    if (!returnsVoid) {
      return _CallbackParserSpec(
        parser: 'resolveGenericCallback0',
        usesEvaluator: true,
        outputType: 'Object? Function()',
      );
    }
    return _CallbackParserSpec(
      parser: 'resolveActionCallback',
      usesEvaluator: true,
      dropSymbols: const ['tap', 'clicked'],
    );
  }

  if (params.length == 1) {
    final param = params.first;
    final paramType = _normalizeTypeName(_typeDisplayName(param.type));
    final isNullable =
        param.type.nullabilitySuffix == NullabilitySuffix.question;
    if (returnsWidget && paramType == 'BuildContext') {
      return _CallbackParserSpec(
        parser: 'resolveWidgetBuilderCallback',
        usesEvaluator: true,
      );
    }
    if (returnsWidgetList && paramType == 'BuildContext') {
      return _CallbackParserSpec(
        parser: 'resolveWidgetListBuilderCallback',
        usesEvaluator: true,
      );
    }
    if (returnsFutureBool) {
      return _CallbackParserSpec(
        parser: 'resolveFutureBoolCallback1',
        usesEvaluator: true,
        outputType: 'Future<bool?> Function(Object?)',
      );
    }
    if (returnsBool) {
      return _CallbackParserSpec(
        parser: 'resolveBoolPredicateCallback',
        usesEvaluator: true,
      );
    }
    if (returnsVoid) {
      if (isNullable) {
        return _CallbackParserSpec(
          parser: 'resolveGenericValueChanged',
          usesEvaluator: true,
        );
      }
      switch (paramType) {
        case 'bool':
          return _CallbackParserSpec(
            parser: 'resolveBoolActionCallback',
            usesEvaluator: true,
          );
        case 'String':
          return _CallbackParserSpec(
            parser: 'resolveStringActionCallback',
            usesEvaluator: true,
          );
        case 'double':
          return _CallbackParserSpec(
            parser: 'resolveDoubleActionCallback',
            usesEvaluator: true,
          );
        case 'int':
          return _CallbackParserSpec(
            parser: 'resolveIntActionCallback',
            usesEvaluator: true,
          );
        case 'Set<int>':
          return _CallbackParserSpec(
            parser: 'resolveIntSetActionCallback',
            usesEvaluator: true,
          );
      }
      return _CallbackParserSpec(
        parser: 'resolveGenericValueChanged',
        usesEvaluator: true,
      );
    }
    if (paramType == 'BuildContext') {
      return _CallbackParserSpec(
        parser: 'resolveBuildContextCallback',
        usesEvaluator: true,
        outputType: 'Object? Function(BuildContext)',
      );
    }
    return _CallbackParserSpec(
      parser: 'resolveGenericCallback1',
      usesEvaluator: true,
      outputType: 'Object? Function(Object?)',
    );
  }

  if (params.length == 2) {
    final paramA = _normalizeTypeName(_typeDisplayName(params[0].type));
    final paramB = _normalizeTypeName(_typeDisplayName(params[1].type));
    if (returnsWidget && paramA == 'BuildContext') {
      return _CallbackParserSpec(
        parser: 'resolveWidgetBuilder2Callback',
        usesEvaluator: true,
        outputType: 'Widget Function(BuildContext, Object?)',
      );
    }
    if (returnsWidgetList && paramA == 'BuildContext') {
      return _CallbackParserSpec(
        parser: 'resolveWidgetListBuilder2Callback',
        usesEvaluator: true,
        outputType: 'List<Widget> Function(BuildContext, Object?)',
      );
    }
    if (returnsVoid) {
      if (paramA == 'int' && paramB == 'int') {
        return _CallbackParserSpec(
          parser: 'resolveReorderActionCallback',
          usesEvaluator: true,
        );
      }
      if (paramA == 'int' && paramB == 'bool') {
        return _CallbackParserSpec(
          parser: 'resolveSortActionCallback',
          usesEvaluator: true,
        );
      }
      return _CallbackParserSpec(
        parser: 'resolveGenericActionCallback2',
        usesEvaluator: true,
        outputType: 'void Function(Object?, Object?)',
      );
    }
    if (paramA == 'BuildContext') {
      return _CallbackParserSpec(
        parser: 'resolveBuildContextCallback2',
        usesEvaluator: true,
        outputType: 'Object? Function(BuildContext, Object?)',
      );
    }
    return _CallbackParserSpec(
      parser: 'resolveGenericCallback2',
      usesEvaluator: true,
      outputType: 'Object? Function(Object?, Object?)',
    );
  }

  return _CallbackParserSpec(
    parser: 'resolveCallbackValue',
    usesEvaluator: true,
    outputType: 'Function',
  );
}
