import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class AboutDialogTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  AboutDialogTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildDialog(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildDialog(config, children));
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('about_dialog').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endabout_dialog').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'about_dialog',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _AboutDialogConfig _parseConfig(Evaluator evaluator) {
    final config = _AboutDialogConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'applicationName':
          config.applicationName = value?.toString();
          break;
        case 'applicationVersion':
          config.applicationVersion = value?.toString();
          break;
        case 'applicationLegalese':
          config.applicationLegalese = value?.toString();
          break;
        case 'applicationIcon':
          config.applicationIcon =
              value is Widget ? value : resolveIconWidget(value);
          break;
        default:
          handleUnknownArg('about_dialog', name);
          break;
      }
    }
    return config;
  }
}

class _AboutDialogConfig {
  String? applicationName;
  String? applicationVersion;
  String? applicationLegalese;
  Widget? applicationIcon;
}

Widget _buildDialog(
  _AboutDialogConfig config,
  List<Widget> children,
) {
  return AboutDialog(
    applicationName: config.applicationName,
    applicationVersion: config.applicationVersion,
    applicationLegalese: config.applicationLegalese,
    applicationIcon: config.applicationIcon,
    children: children.isEmpty ? null : children,
  );
}
