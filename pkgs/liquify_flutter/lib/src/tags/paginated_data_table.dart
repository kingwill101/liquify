import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'data_table_helpers.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class PaginatedDataTableTag extends WidgetTagBase with AsyncTag {
  PaginatedDataTableTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final columns = buildDataColumns(
      evaluator,
      config.columns,
      tagName: 'paginated_data_table',
      actionValue: config.action,
    );
    final rows = buildDataRows(
      evaluator,
      config.rows,
      tagName: 'paginated_data_table',
      actionValue: config.rowAction ?? config.action,
    );
    final source = config.source ?? _ListDataTableSource(rows);
    buffer.write(_buildTable(config, columns, source));
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
      tagName: 'paginated_data_table',
      actionValue: config.action,
    );
    final rows = buildDataRows(
      evaluator,
      config.rows,
      tagName: 'paginated_data_table',
      actionValue: config.rowAction ?? config.action,
    );
    final source = config.source ?? _ListDataTableSource(rows);
    buffer.write(_buildTable(config, columns, source));
  }

  _PaginatedDataTableConfig _parseConfig(Evaluator evaluator) {
    final config = _PaginatedDataTableConfig();
    Object? onSelectAllValue;
    Object? onRowsPerPageValue;
    Object? onPageChangedValue;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'header':
          config.header = _resolveHeader(value);
          break;
        case 'actions':
          config.actions = _resolveActions(value);
          break;
        case 'columns':
          config.columns = value;
          break;
        case 'rows':
          config.rows = value;
          break;
        case 'source':
          if (value is DataTableSource) {
            config.source = value;
          }
          break;
        case 'sortColumnIndex':
          config.sortColumnIndex = toInt(value);
          break;
        case 'sortAscending':
          config.sortAscending = toBool(value);
          break;
        case 'onSelectAll':
          onSelectAllValue = value;
          break;
        case 'dataRowHeight':
          config.dataRowHeight = toDouble(value);
          break;
        case 'dataRowMinHeight':
          config.dataRowMinHeight = toDouble(value);
          break;
        case 'dataRowMaxHeight':
          config.dataRowMaxHeight = toDouble(value);
          break;
        case 'headingRowHeight':
          config.headingRowHeight = toDouble(value);
          break;
        case 'horizontalMargin':
          config.horizontalMargin = toDouble(value);
          break;
        case 'columnSpacing':
          config.columnSpacing = toDouble(value);
          break;
        case 'showCheckboxColumn':
          config.showCheckboxColumn = toBool(value);
          break;
        case 'showFirstLastButtons':
          config.showFirstLastButtons = toBool(value);
          break;
        case 'initialFirstRowIndex':
          config.initialFirstRowIndex = toInt(value);
          break;
        case 'onPageChanged':
          onPageChangedValue = value;
          break;
        case 'rowsPerPage':
          config.rowsPerPage = toInt(value);
          break;
        case 'availableRowsPerPage':
          config.availableRowsPerPage = _parseRowsPerPage(value);
          break;
        case 'onRowsPerPageChanged':
          onRowsPerPageValue = value;
          break;
        case 'dragStartBehavior':
          config.dragStartBehavior = parseDragStartBehavior(value);
          break;
        case 'arrowHeadColor':
          config.arrowHeadColor = parseColor(value);
          break;
        case 'checkboxHorizontalMargin':
          config.checkboxHorizontalMargin = toDouble(value);
          break;
        case 'controller':
          if (value is ScrollController) {
            config.controller = value;
          }
          break;
        case 'primary':
          config.primary = toBool(value);
          break;
        case 'headingRowColor':
          config.headingRowColor = toWidgetStateColor(value);
          break;
        case 'dividerThickness':
          config.dividerThickness = toDouble(value);
          break;
        case 'showEmptyRows':
          config.showEmptyRows = toBool(value);
          break;
        case 'action':
          config.action = value?.toString();
          break;
        case 'rowAction':
          config.rowAction = value?.toString();
          break;
        default:
          handleUnknownArg('paginated_data_table', name);
          break;
      }
    }

    final actionName = config.action;
    final selectAllEvent = buildWidgetEvent(
      tag: 'paginated_data_table',
      id: 'paginated_data_table',
      key: 'paginated_data_table',
      action: actionName,
      event: 'select_all',
    );
    final selectAllAction = onSelectAllValue ?? actionName;
    final selectAllCallback = _resolveNullableBoolActionCallback(
      evaluator,
      selectAllAction,
      event: selectAllEvent,
      actionValue: selectAllAction is String ? selectAllAction : actionName,
    );
    config.onSelectAll = selectAllCallback == null
        ? null
        : (value) {
            selectAllEvent['value'] = value;
            selectAllCallback(value);
          };

    final rowsPerPageEvent = buildWidgetEvent(
      tag: 'paginated_data_table',
      id: 'paginated_data_table',
      key: 'paginated_data_table',
      action: actionName,
      event: 'rows_per_page',
    );
    final rowsPerPageAction = onRowsPerPageValue ?? actionName;
    final rowsPerPageCallback = _resolveNullableIntActionCallback(
      evaluator,
      rowsPerPageAction,
      event: rowsPerPageEvent,
      actionValue: rowsPerPageAction is String ? rowsPerPageAction : actionName,
    );
    config.onRowsPerPageChanged = rowsPerPageCallback == null
        ? null
        : (value) {
            rowsPerPageEvent['value'] = value;
            rowsPerPageCallback(value);
          };

    final pageEvent = buildWidgetEvent(
      tag: 'paginated_data_table',
      id: 'paginated_data_table',
      key: 'paginated_data_table',
      action: actionName,
      event: 'page_changed',
    );
    final pageAction = onPageChangedValue ?? actionName;
    final pageCallback = _resolveNullableIntActionCallback(
      evaluator,
      pageAction,
      event: pageEvent,
      actionValue: pageAction is String ? pageAction : actionName,
    );
    config.onPageChanged = pageCallback == null
        ? null
        : (value) {
            pageEvent['value'] = value;
            pageCallback(value);
          };

    return config;
  }
}

class _PaginatedDataTableConfig {
  Widget? header;
  List<Widget>? actions;
  Object? columns;
  Object? rows;
  DataTableSource? source;
  int? sortColumnIndex;
  bool? sortAscending;
  ValueSetter<bool?>? onSelectAll;
  double? dataRowHeight;
  double? dataRowMinHeight;
  double? dataRowMaxHeight;
  double? headingRowHeight;
  double? horizontalMargin;
  double? columnSpacing;
  bool? showCheckboxColumn;
  bool? showFirstLastButtons;
  int? initialFirstRowIndex;
  ValueChanged<int>? onPageChanged;
  int? rowsPerPage;
  List<int>? availableRowsPerPage;
  ValueChanged<int?>? onRowsPerPageChanged;
  DragStartBehavior? dragStartBehavior;
  Color? arrowHeadColor;
  double? checkboxHorizontalMargin;
  ScrollController? controller;
  bool? primary;
  WidgetStateProperty<Color?>? headingRowColor;
  double? dividerThickness;
  bool? showEmptyRows;
  String? action;
  String? rowAction;
}

PaginatedDataTable _buildTable(
  _PaginatedDataTableConfig config,
  List<DataColumn> columns,
  DataTableSource source,
) {
  final rowsPerPage =
      config.rowsPerPage ?? PaginatedDataTable.defaultRowsPerPage;
  final availableRows =
      config.availableRowsPerPage ??
      <int>[
        PaginatedDataTable.defaultRowsPerPage,
        PaginatedDataTable.defaultRowsPerPage * 2,
        PaginatedDataTable.defaultRowsPerPage * 5,
        PaginatedDataTable.defaultRowsPerPage * 10,
      ];
  final dataRowMinHeight = config.dataRowMinHeight ?? config.dataRowHeight;
  final dataRowMaxHeight = config.dataRowMaxHeight ?? config.dataRowHeight;
  final header =
      config.header ??
      (config.actions == null || config.actions!.isEmpty
          ? null
          : const Text(''));
  return PaginatedDataTable(
    header: header,
    actions: config.actions,
    columns: columns,
    sortColumnIndex: config.sortColumnIndex,
    sortAscending: config.sortAscending ?? true,
    onSelectAll: config.onSelectAll,
    dataRowMinHeight: dataRowMinHeight,
    dataRowMaxHeight: dataRowMaxHeight,
    headingRowHeight: config.headingRowHeight ?? 56,
    horizontalMargin: config.horizontalMargin ?? 24,
    columnSpacing: config.columnSpacing ?? 56,
    showCheckboxColumn: config.showCheckboxColumn ?? true,
    showFirstLastButtons: config.showFirstLastButtons ?? false,
    initialFirstRowIndex: config.initialFirstRowIndex ?? 0,
    onPageChanged: config.onPageChanged,
    rowsPerPage: rowsPerPage,
    availableRowsPerPage: availableRows,
    onRowsPerPageChanged: config.onRowsPerPageChanged,
    dragStartBehavior: config.dragStartBehavior ?? DragStartBehavior.start,
    arrowHeadColor: config.arrowHeadColor,
    source: source,
    checkboxHorizontalMargin: config.checkboxHorizontalMargin,
    controller: config.controller,
    primary: config.primary,
    headingRowColor: config.headingRowColor,
    dividerThickness: config.dividerThickness,
    showEmptyRows: config.showEmptyRows ?? true,
  );
}

class _ListDataTableSource extends DataTableSource {
  _ListDataTableSource(this.rows);

  final List<DataRow> rows;

  @override
  DataRow? getRow(int index) {
    if (index < 0 || index >= rows.length) {
      return null;
    }
    return rows[index];
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => rows.length;

  @override
  int get selectedRowCount {
    var count = 0;
    for (final row in rows) {
      if (row.selected == true) {
        count++;
      }
    }
    return count;
  }
}

Widget? _resolveHeader(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is Widget) {
    return value;
  }
  return resolveTextWidget(value);
}

List<Widget>? _resolveActions(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is Iterable) {
    final widgets = <Widget>[];
    for (final entry in value) {
      final widget = _resolveActionWidget(entry);
      if (widget != null) {
        widgets.add(widget);
      }
    }
    return widgets.isEmpty ? null : widgets;
  }
  final widget = _resolveActionWidget(value);
  return widget == null ? null : [widget];
}

Widget? _resolveActionWidget(Object? value) {
  if (value is Widget) {
    return value;
  }
  final icon = resolveIconWidget(value);
  if (icon != null) {
    return icon;
  }
  final text = resolveTextWidget(value);
  return text;
}

ValueSetter<bool?>? _resolveNullableBoolActionCallback(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}) {
  if (value is ValueSetter<bool?>) {
    return value;
  }
  if (value is ValueChanged<bool>) {
    return (flag) {
      if (flag == null) {
        return;
      }
      value(flag);
    };
  }
  final resolved = resolveBoolActionCallback(
    evaluator,
    value,
    event: event,
    actionValue: actionValue,
  );
  if (resolved == null) {
    return null;
  }
  return (flag) {
    if (flag == null) {
      return;
    }
    resolved(flag);
  };
}

ValueChanged<int?>? _resolveNullableIntActionCallback(
  Evaluator evaluator,
  Object? value, {
  Map<String, dynamic>? event,
  String? actionValue,
}) {
  if (value is ValueChanged<int?>) {
    return value;
  }
  if (value is ValueChanged<int>) {
    return (next) {
      if (next == null) {
        return;
      }
      value(next);
    };
  }
  final resolved = resolveIntActionCallback(
    evaluator,
    value,
    event: event,
    actionValue: actionValue,
  );
  if (resolved == null) {
    return null;
  }
  return (next) {
    if (next == null) {
      return;
    }
    resolved(next);
  };
}

List<int>? _parseRowsPerPage(Object? value) {
  if (value is Iterable) {
    final rows = <int>[];
    for (final entry in value) {
      final parsed = toInt(entry);
      if (parsed != null) {
        rows.add(parsed);
      }
    }
    return rows.isEmpty ? null : rows;
  }
  return null;
}
