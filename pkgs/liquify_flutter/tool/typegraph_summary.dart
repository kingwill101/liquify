import 'dart:convert';
import 'dart:io';

void main() {
  final reportFile = File('tool/tag_specs/generated/widgets.report.json');
  if (!reportFile.existsSync()) {
    stderr.writeln('Missing report file: ${reportFile.path}');
    exit(1);
  }
  final data =
      jsonDecode(reportFile.readAsStringSync()) as Map<String, dynamic>;
  final widgets = (data['widgets'] as List<dynamic>? ?? [])
      .cast<Map<String, dynamic>>();
  final totalProps = widgets
      .map((widget) => (widget['properties'] as List? ?? []).length)
      .fold<int>(0, (sum, count) => sum + count);
  final totalSkipped = widgets
      .map((widget) => (widget['skipped'] as List? ?? []).length)
      .fold<int>(0, (sum, count) => sum + count);

  stdout.writeln('widgets ${widgets.length}');
  stdout.writeln('properties $totalProps');
  stdout.writeln('skipped $totalSkipped');
  stdout.writeln(
    'generatedTags ${(data['generatedTags'] as List? ?? []).length}',
  );
  stdout.writeln(
    'generatedDrops ${(data['generatedDrops'] as List? ?? []).length}',
  );
}
