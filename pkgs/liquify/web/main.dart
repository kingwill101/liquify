import 'dart:convert';

import 'package:liquify/liquify.dart';
import 'package:web/web.dart';

Future<void> main() async {
  final templateInput =
      document.getElementById('templateInput') as HTMLTextAreaElement;
  final dataInput = document.getElementById('dataInput') as HTMLTextAreaElement;
  final output = document.getElementById('output') as HTMLDivElement;
  final autoRender = document.getElementById('autoRender') as HTMLInputElement;
  final renderBtn = document.getElementById('renderBtn') as HTMLButtonElement;
  final renderTime = document.getElementById('renderTime') as HTMLSpanElement;

  Future<void> doRender() async {
    final start = DateTime.now().microsecondsSinceEpoch;
    try {
      final tmpl = templateInput.value;
      final dataStr = dataInput.value;
      final Map<String, dynamic> data = dataStr.trim().isNotEmpty
          ? jsonDecode(dataStr) as Map<String, dynamic>
          : const {};

      final template = Template.parse(tmpl, data: data);
      final result = template.render();

      output.textContent = result;
      output.className = 'output-content';
      final elapsed = (DateTime.now().microsecondsSinceEpoch - start) / 1000;
      renderTime.textContent = '${elapsed.toStringAsFixed(1)}ms';
    } catch (e) {
      output.textContent = 'Error: $e';
      output.className = 'output-content error';
      renderTime.textContent = '';
    }
  }

  templateInput.onInput.listen((_) async {
    if (autoRender.checked) await doRender();
  });
  dataInput.onInput.listen((_) async {
    if (autoRender.checked) await doRender();
  });
  renderBtn.onClick.listen((_) async => await doRender());

  await doRender();
}
