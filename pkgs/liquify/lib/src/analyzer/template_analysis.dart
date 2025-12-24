import 'template_structure.dart';

/// Represents the results of analyzing a Liquid template and its inheritance chain.
///
/// TemplateAnalysis collects information about:
/// * The structures of all templates in the inheritance chain
/// * Any warnings or errors encountered during analysis
/// * The relationships between templates
///
/// This class is typically used as the return value from template analysis
/// operations and provides access to the complete analysis results.
class TemplateAnalysis {
  /// Map of template paths to their analyzed structures.
  ///
  /// The keys are the paths to the templates (relative to the root),
  /// and the values are the [TemplateStructure] objects containing
  /// the analysis results for each template.
  ///
  /// This includes both the main template being analyzed and any
  /// parent templates it extends or includes.
  final Map<String, TemplateStructure> structures;

  /// List of warnings generated during template analysis.
  ///
  /// Warnings might include:
  /// * Missing template files
  /// * Invalid block structures
  /// * Inheritance issues
  /// * Other non-fatal problems encountered during analysis
  final List<String> warnings;

  /// Creates a new template analysis result.
  ///
  /// Initializes empty maps and lists for collecting analysis results.
  /// The analysis will be populated as the template and its inheritance
  /// chain are processed.
  TemplateAnalysis()
      : structures = {},
        warnings = [];

  /// Converts the analysis results to a JSON-compatible map.
  ///
  /// This is useful for:
  /// * Debugging template analysis
  /// * Serializing analysis results
  /// * Generating reports
  ///
  /// Returns a map containing:
  /// * warnings: List of warning messages
  /// * structures: Map of template paths to their structures
  Map<String, dynamic> toJson() {
    return {
      'warnings': warnings,
      'structures': structures,
    };
  }
}
