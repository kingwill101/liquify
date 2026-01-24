import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('type graph report includes resolved and generated entries', () {
    final reportFile = File('tool/tag_specs/generated/widgets.report.json');
    expect(reportFile.existsSync(), isTrue);

    final data = jsonDecode(reportFile.readAsStringSync())
        as Map<String, dynamic>;
    final typeGraph = data['typeGraph'] as Map<String, dynamic>;
    final resolved = (typeGraph['resolved'] as List)
        .cast<Map<String, dynamic>>();
    final generatedDrops = (data['generatedDrops'] as List)
        .cast<String>();
    final widgets = (data['widgets'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final totalSkipped = widgets
        .map((widget) => (widget['skipped'] as List? ?? []).length)
        .fold<int>(0, (sum, count) => sum + count);

    expect(resolved.any((entry) => entry['type'] == 'BoxConstraints'), isTrue);
    expect(
      generatedDrops.contains('GeneratedGestureTapCallbackDrop'),
      isTrue,
    );
    // Some properties are skipped when their default values aren't representable
    // Currently: Autocomplete.fieldViewBuilder, Scaffold.bottomSheetScrimBuilder
    expect(totalSkipped, lessThanOrEqualTo(2));

    final generated = File('tool/type_registry.generated.yaml');
    expect(generated.existsSync(), isTrue);
    expect(generated.readAsStringSync().contains('types:'), isTrue);

    final merged = File('tool/type_registry.yaml');
    expect(merged.existsSync(), isTrue);
    expect(merged.readAsStringSync().contains('types:'), isTrue);
  });
}
