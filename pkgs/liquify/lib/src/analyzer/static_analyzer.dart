import 'package:liquify/parser.dart';
import 'package:liquify/src/util.dart';
import 'template_analyzer.dart';

/// Represents a variable reference in a template
class VariableReference {
  final String name;
  final String templatePath;
  final int lineNumber;
  final bool isAssignment;
  final bool isRead;

  VariableReference({
    required this.name,
    required this.templatePath,
    required this.lineNumber,
    required this.isAssignment,
    required this.isRead,
  });

  @override
  String toString() =>
      '$name (${isAssignment ? "assigned" : "read"} at $templatePath:$lineNumber)';
}

/// Represents a filter usage in a template
class FilterUsage {
  final String name;
  final String templatePath;
  final int lineNumber;
  final List<String> arguments;

  FilterUsage({
    required this.name,
    required this.templatePath,
    required this.lineNumber,
    required this.arguments,
  });

  @override
  String toString() =>
      '$name(${arguments.join(", ")}) at $templatePath:$lineNumber';
}

/// Result of static analysis for a template
class StaticAnalysisResult {
  final String templatePath;
  final Set<String> declaredVariables;
  final Set<String> usedVariables;
  final Set<String> undefinedVariables;
  final List<VariableReference> variableReferences;
  final List<FilterUsage> filterUsages;
  final Map<String, List<String>> variableDependencies;
  final List<String> layoutDependencies;

  StaticAnalysisResult({
    required this.templatePath,
    required this.declaredVariables,
    required this.usedVariables,
    required this.undefinedVariables,
    required this.variableReferences,
    required this.filterUsages,
    required this.variableDependencies,
    required this.layoutDependencies,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Static Analysis for $templatePath:');
    buffer.writeln('Declared variables: ${declaredVariables.join(", ")}');
    buffer.writeln('Used variables: ${usedVariables.join(", ")}');
    if (undefinedVariables.isNotEmpty) {
      buffer.writeln(
          'Potentially undefined variables: ${undefinedVariables.join(", ")}');
    }
    if (layoutDependencies.isNotEmpty) {
      buffer.writeln('Layout dependencies: ${layoutDependencies.join(" -> ")}');
    }
    if (filterUsages.isNotEmpty) {
      buffer.writeln('Filter usages:');
      for (final filter in filterUsages) {
        buffer.writeln('  $filter');
      }
    }
    if (variableDependencies.isNotEmpty) {
      buffer.writeln('Variable dependencies:');
      variableDependencies.forEach((variable, deps) {
        buffer.writeln('  $variable depends on: ${deps.join(", ")}');
      });
    }
    return buffer.toString();
  }
}

/// Static analyzer for Liquid templates
class LiquidStaticAnalyzer {
  final TemplateAnalyzer _templateAnalyzer;
  final Logger _logger = Logger('StaticAnalyzer');

  LiquidStaticAnalyzer(this._templateAnalyzer);

  /// Analyzes a template and its dependencies for variable usage and other static properties
  Future<StaticAnalysisResult> analyzeTemplate(String templatePath) async {
    _logger.info('Starting static analysis of $templatePath');

    // First, use template analyzer to resolve layouts and includes
    final templateAnalysis =
        _templateAnalyzer.analyzeTemplate(templatePath).last;
    final structure = templateAnalysis.structures[templatePath];

    if (structure == null) {
      throw Exception('Template structure not found for $templatePath');
    }

    final declaredVariables = <String>{};
    final usedVariables = <String>{};
    final variableReferences = <VariableReference>[];
    final filterUsages = <FilterUsage>[];
    final variableDependencies = <String, List<String>>{};
    final layoutDependencies = <String>[];

    // Track layout dependencies
    var current = structure;
    while (current.parent != null) {
      layoutDependencies.add(current.parent!.templatePath);
      current = current.parent!;
    }

    // Analyze the AST
    for (final node in structure.nodes) {
      _analyzeASTNode(
        node,
        templatePath,
        declaredVariables,
        usedVariables,
        variableReferences,
        filterUsages,
        variableDependencies,
      );
    }

    // Calculate undefined variables (used but not declared)
    final undefinedVariables = usedVariables.difference(declaredVariables);

    return StaticAnalysisResult(
      templatePath: templatePath,
      declaredVariables: declaredVariables,
      usedVariables: usedVariables,
      undefinedVariables: undefinedVariables,
      variableReferences: variableReferences,
      filterUsages: filterUsages,
      variableDependencies: variableDependencies,
      layoutDependencies: layoutDependencies.reversed.toList(),
    );
  }

  void _analyzeASTNode(
    ASTNode node,
    String templatePath,
    Set<String> declaredVariables,
    Set<String> usedVariables,
    List<VariableReference> variableReferences,
    List<FilterUsage> filterUsages,
    Map<String, List<String>> variableDependencies,
  ) {
    if (node is Variable) {
      _analyzeVariableNode(
        node,
        templatePath,
        declaredVariables,
        usedVariables,
        variableReferences,
        filterUsages,
        variableDependencies,
      );
    } else if (node is FilteredExpression) {
      _analyzeFilteredExpression(
        node,
        templatePath,
        declaredVariables,
        usedVariables,
        variableReferences,
        filterUsages,
        variableDependencies,
      );
    } else if (node is Tag) {
      _analyzeTagNode(
        node,
        templatePath,
        declaredVariables,
        usedVariables,
        variableReferences,
        filterUsages,
        variableDependencies,
      );

      // Process tag body recursively
      for (final bodyNode in node.body) {
        _analyzeASTNode(
          bodyNode,
          templatePath,
          declaredVariables,
          usedVariables,
          variableReferences,
          filterUsages,
          variableDependencies,
        );
      }
    }

    // Process any child nodes
    if (node is Document) {
      for (final child in node.children) {
        _analyzeASTNode(
          child,
          templatePath,
          declaredVariables,
          usedVariables,
          variableReferences,
          filterUsages,
          variableDependencies,
        );
      }
    }
  }

  void _analyzeVariableNode(
    Variable variable,
    String templatePath,
    Set<String> declaredVariables,
    Set<String> usedVariables,
    List<VariableReference> variableReferences,
    List<FilterUsage> filterUsages,
    Map<String, List<String>> variableDependencies,
  ) {
    usedVariables.add(variable.name);

    variableReferences.add(VariableReference(
      name: variable.name,
      templatePath: templatePath,
      lineNumber: 0,
      isAssignment: false,
      isRead: true,
    ));

    // Process the expression for dependencies
    if (variable.expression is Variable) {
      final deps = variableDependencies[variable.name] ?? [];
      deps.add((variable.expression as Variable).name);
      variableDependencies[variable.name] = deps;
      usedVariables.add((variable.expression as Variable).name);
    }
  }

  void _analyzeFilteredExpression(
    FilteredExpression expr,
    String templatePath,
    Set<String> declaredVariables,
    Set<String> usedVariables,
    List<VariableReference> variableReferences,
    List<FilterUsage> filterUsages,
    Map<String, List<String>> variableDependencies,
  ) {
    // First analyze the base expression
    _analyzeASTNode(
      expr.expression,
      templatePath,
      declaredVariables,
      usedVariables,
      variableReferences,
      filterUsages,
      variableDependencies,
    );

    // Then analyze each filter
    for (final filter in expr.filters) {
      filterUsages.add(FilterUsage(
        name: filter.name.name,
        templatePath: templatePath,
        lineNumber: 0,
        arguments: filter.arguments.map((arg) => arg.toString()).toList(),
      ));

      // Track variable dependencies through filter arguments
      for (final arg in filter.arguments) {
        if (arg is Variable) {
          if (expr.expression is Variable) {
            final baseVarName = (expr.expression as Variable).name;
            final deps = variableDependencies[baseVarName] ?? [];
            deps.add(arg.name);
            variableDependencies[baseVarName] = deps;
          }
          usedVariables.add(arg.name);
        }
      }
    }
  }

  void _analyzeTagNode(
    Tag tag,
    String templatePath,
    Set<String> declaredVariables,
    Set<String> usedVariables,
    List<VariableReference> variableReferences,
    List<FilterUsage> filterUsages,
    Map<String, List<String>> variableDependencies,
  ) {
    switch (tag.name) {
      case 'assign':
        final assignContent =
            tag.content.firstWhere((n) => n is Identifier) as Identifier;
        final varName = assignContent.name;
        declaredVariables.add(varName);
        variableReferences.add(VariableReference(
          name: varName,
          templatePath: templatePath,
          lineNumber: 0,
          isAssignment: true,
          isRead: false,
        ));

        // Process the assigned value for dependencies
        for (final node in tag.content) {
          if (node is Variable) {
            final deps = variableDependencies[varName] ?? [];
            deps.add(node.name);
            variableDependencies[varName] = deps;
            usedVariables.add(node.name);
          }
        }
        break;

      case 'capture':
        final captureContent =
            tag.content.firstWhere((n) => n is Identifier) as Identifier;
        final varName = captureContent.name;
        declaredVariables.add(varName);
        variableReferences.add(VariableReference(
          name: varName,
          templatePath: templatePath,
          lineNumber: 0,
          isAssignment: true,
          isRead: false,
        ));
        break;

      case 'for':
        final loopVar = (tag.content[0] as Identifier).name;
        final collection = (tag.content[2] as Variable).name;

        declaredVariables.add(loopVar);
        usedVariables.add(collection);

        variableReferences.add(VariableReference(
          name: loopVar,
          templatePath: templatePath,
          lineNumber: 0,
          isAssignment: true,
          isRead: false,
        ));

        variableReferences.add(VariableReference(
          name: collection,
          templatePath: templatePath,
          lineNumber: 0,
          isAssignment: false,
          isRead: true,
        ));
        break;
    }
  }
}
