import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class TableTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  TableTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final rows = _resolveRows(evaluator, config.rows);
    buffer.write(_buildTable(config, rows));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final rows = _resolveRows(evaluator, config.rows);
    buffer.write(_buildTable(config, rows));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('table').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endtable').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'table',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _TableConfig _parseConfig(Evaluator evaluator) {
    final config = _TableConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'rows':
          config.rows = value;
          break;
        case 'columnWidths':
          config.columnWidths = parseTableColumnWidths(value);
          break;
        case 'defaultColumnWidth':
          config.defaultColumnWidth = parseTableColumnWidth(value);
          break;
        case 'border':
          config.border = parseTableBorder(value);
          break;
        case 'defaultVerticalAlignment':
          config.defaultVerticalAlignment = parseTableCellVerticalAlignment(
            value,
          );
          break;
        case 'textDirection':
          config.textDirection = parseTextDirection(value);
          break;
        case 'textBaseline':
          config.textBaseline = parseTextBaseline(value);
          break;
        default:
          handleUnknownArg('table', name);
          break;
      }
    }
    return config;
  }

  List<TableRow> _resolveRows(Evaluator evaluator, Object? value) {
    if (value is Iterable) {
      return _rowsFromIterable(evaluator, value);
    }
    final children = captureChildrenSync(evaluator);
    if (children.isNotEmpty) {
      return [TableRow(children: children)];
    }
    return const [];
  }

  List<TableRow> _rowsFromIterable(Evaluator evaluator, Iterable value) {
    final rows = <TableRow>[];
    for (final entry in value) {
      if (entry is TableRow) {
        rows.add(entry);
        continue;
      }
      if (entry is Map) {
        final cells = _resolveCellWidgets(entry['cells'] ?? entry['children']);
        final decoration = parseDecoration(evaluator, entry['decoration']);
        if (cells.isNotEmpty) {
          rows.add(TableRow(children: cells, decoration: decoration));
        }
        continue;
      }
      if (entry is Iterable) {
        final cells = _resolveCellWidgets(entry);
        if (cells.isNotEmpty) {
          rows.add(TableRow(children: cells));
        }
      }
    }
    return rows;
  }

  List<Widget> _resolveCellWidgets(Object? value) {
    if (value is Iterable) {
      return value.map(_cellToWidget).toList();
    }
    if (value == null) {
      return const [];
    }
    return [_cellToWidget(value)];
  }

  Widget _cellToWidget(Object? value) {
    if (value is Widget) {
      return value;
    }
    if (value == null) {
      return const SizedBox.shrink();
    }
    return Text(value.toString());
  }
}

class _TableConfig {
  Object? rows;
  Map<int, TableColumnWidth>? columnWidths;
  TableColumnWidth? defaultColumnWidth;
  TableBorder? border;
  TableCellVerticalAlignment? defaultVerticalAlignment;
  TextDirection? textDirection;
  TextBaseline? textBaseline;
}

Table _buildTable(_TableConfig config, List<TableRow> rows) {
  return Table(
    columnWidths: config.columnWidths,
    defaultColumnWidth: config.defaultColumnWidth ?? const FlexColumnWidth(1.0),
    textDirection: config.textDirection,
    border: config.border,
    defaultVerticalAlignment:
        config.defaultVerticalAlignment ?? TableCellVerticalAlignment.middle,
    textBaseline: config.textBaseline,
    children: rows,
  );
}
