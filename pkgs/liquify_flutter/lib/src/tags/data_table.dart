import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'data_table_helpers.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class DataTableTag extends WidgetTagBase with AsyncTag {
  DataTableTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final columns = buildDataColumns(
      evaluator,
      config.columns,
      tagName: 'data_table',
      actionValue: config.action,
    );
    final rows = buildDataRows(
      evaluator,
      config.rows,
      tagName: 'data_table',
      actionValue: config.rowAction ?? config.action,
    );
    buffer.write(_buildDataTable(config, columns, rows));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final columns = buildDataColumns(
      evaluator,
      config.columns,
      tagName: 'data_table',
      actionValue: config.action,
    );
    final rows = buildDataRows(
      evaluator,
      config.rows,
      tagName: 'data_table',
      actionValue: config.rowAction ?? config.action,
    );
    buffer.write(_buildDataTable(config, columns, rows));
  }

  _DataTableConfig _parseConfig(Evaluator evaluator) {
    final config = _DataTableConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'columns':
          config.columns = value;
          break;
        case 'rows':
          config.rows = value;
          break;
        case 'sortColumnIndex':
          config.sortColumnIndex = toInt(value);
          break;
        case 'sortAscending':
          config.sortAscending = toBool(value);
          break;
        case 'headingRowColor':
          config.headingRowColor = toWidgetStateColor(value);
          break;
        case 'dataRowColor':
          config.dataRowColor = toWidgetStateColor(value);
          break;
        case 'headingRowHeight':
          config.headingRowHeight = toDouble(value);
          break;
        case 'dataRowMinHeight':
          config.dataRowMinHeight = toDouble(value);
          break;
        case 'dataRowMaxHeight':
          config.dataRowMaxHeight = toDouble(value);
          break;
        case 'dividerThickness':
          config.dividerThickness = toDouble(value);
          break;
        case 'showCheckboxColumn':
          config.showCheckboxColumn = toBool(value);
          break;
        case 'showBottomBorder':
          config.showBottomBorder = toBool(value);
          break;
        case 'horizontalMargin':
          config.horizontalMargin = toDouble(value);
          break;
        case 'columnSpacing':
          config.columnSpacing = toDouble(value);
          break;
        case 'checkboxHorizontalMargin':
          config.checkboxHorizontalMargin = toDouble(value);
          break;
        case 'dataTextStyle':
          config.dataTextStyle = parseTextStyle(value);
          break;
        case 'headingTextStyle':
          config.headingTextStyle = parseTextStyle(value);
          break;
        case 'decoration':
          config.decoration = parseDecoration(evaluator, value);
          break;
        case 'border':
          config.border = parseTableBorder(value);
          break;
        case 'clipBehavior':
          config.clipBehavior = parseClip(value);
          break;
        case 'action':
          config.action = value?.toString();
          break;
        case 'rowAction':
          config.rowAction = value?.toString();
          break;
        default:
          handleUnknownArg('data_table', name);
          break;
      }
    }
    return config;
  }
}

class _DataTableConfig {
  Object? columns;
  Object? rows;
  int? sortColumnIndex;
  bool? sortAscending;
  WidgetStateProperty<Color?>? headingRowColor;
  WidgetStateProperty<Color?>? dataRowColor;
  double? headingRowHeight;
  double? dataRowMinHeight;
  double? dataRowMaxHeight;
  double? dividerThickness;
  bool? showCheckboxColumn;
  bool? showBottomBorder;
  double? horizontalMargin;
  double? columnSpacing;
  double? checkboxHorizontalMargin;
  TextStyle? dataTextStyle;
  TextStyle? headingTextStyle;
  Decoration? decoration;
  TableBorder? border;
  Clip? clipBehavior;
  String? action;
  String? rowAction;
}

DataTable _buildDataTable(
  _DataTableConfig config,
  List<DataColumn> columns,
  List<DataRow> rows,
) {
  return DataTable(
    columns: columns,
    rows: rows,
    sortColumnIndex: config.sortColumnIndex,
    sortAscending: config.sortAscending ?? true,
    headingRowColor: config.headingRowColor,
    dataRowColor: config.dataRowColor,
    headingRowHeight: config.headingRowHeight,
    dataRowMinHeight: config.dataRowMinHeight,
    dataRowMaxHeight: config.dataRowMaxHeight,
    dividerThickness: config.dividerThickness,
    showCheckboxColumn: config.showCheckboxColumn ?? true,
    showBottomBorder: config.showBottomBorder ?? false,
    horizontalMargin: config.horizontalMargin,
    columnSpacing: config.columnSpacing,
    checkboxHorizontalMargin: config.checkboxHorizontalMargin,
    dataTextStyle: config.dataTextStyle,
    headingTextStyle: config.headingTextStyle,
    decoration: config.decoration,
    border: config.border,
    clipBehavior: config.clipBehavior ?? Clip.none,
  );
}
