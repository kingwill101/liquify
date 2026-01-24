// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';

List<DataColumn> buildDataColumns(
  Evaluator evaluator,
  Object? value, {
  required String tagName,
  String? actionValue,
}) {
  final raw = value is Iterable ? value : const [];
  final columns = <DataColumn>[];
  var index = 0;
  for (final entry in raw) {
    if (entry is DataColumn) {
      columns.add(entry);
      index++;
      continue;
    }
    if (entry is Map) {
      final labelValue = entry['label'] ?? entry['title'] ?? entry['text'];
      final label = resolveTextWidget(labelValue) ?? const Text('');
      final numeric = toBool(entry['numeric']) ?? false;
      final tooltip = entry['tooltip']?.toString();
      final onSortValue = entry['onSort'] ?? actionValue;
      final event = buildWidgetEvent(
        tag: tagName,
        id: tagName,
        key: tagName,
        action: onSortValue is String ? onSortValue : actionValue,
        event: 'sort',
        props: {
          'columnIndex': index,
          'label': labelValue,
        },
      );
      final onSort = resolveSortActionCallback(
        evaluator,
        onSortValue,
        event: event,
        actionValue: onSortValue is String ? onSortValue : actionValue,
      );
      columns.add(DataColumn(
        label: label,
        numeric: numeric,
        tooltip: tooltip,
        onSort: onSort,
      ));
      index++;
      continue;
    }
    final label = resolveTextWidget(entry) ?? const Text('');
    columns.add(DataColumn(label: label));
    index++;
  }
  return columns;
}

List<DataRow> buildDataRows(
  Evaluator evaluator,
  Object? value, {
  required String tagName,
  String? actionValue,
}) {
  final raw = value is Iterable ? value : const [];
  final rows = <DataRow>[];
  var index = 0;
  for (final entry in raw) {
    if (entry is DataRow) {
      rows.add(entry);
      index++;
      continue;
    }
    if (entry is Map) {
      final cellsValue = entry['cells'] ?? entry['values'] ?? entry['children'];
      final cells = _buildCells(evaluator, cellsValue, tagName, actionValue, index);
      if (cells.isEmpty) {
        index++;
        continue;
      }
      final selected = toBool(entry['selected']) ?? false;
      final color = _resolveRowColor(entry['color']);
      final rowKey = _resolveKey(entry['key'] ?? entry['id'] ?? index);
      final onSelectValue = entry['onSelectChanged'] ?? entry['action'] ?? actionValue;
      final event = buildWidgetEvent(
        tag: tagName,
        id: tagName,
        key: tagName,
        action: onSelectValue is String ? onSelectValue : actionValue,
        event: 'row_selected',
        props: {
          'rowIndex': index,
          'row': entry,
        },
      );
      final onSelect = resolveBoolActionCallback(
        evaluator,
        onSelectValue,
        event: event,
        actionValue: onSelectValue is String ? onSelectValue : actionValue,
      );
      final resolvedOnSelect = onSelect == null
          ? null
          : (value) {
              event['value'] = value;
              onSelect(value);
            };
      rows.add(DataRow(
        key: rowKey,
        selected: selected,
        onSelectChanged: resolvedOnSelect,
        color: color,
        cells: cells,
      ));
      index++;
      continue;
    }
    if (entry is Iterable) {
      final cells = _buildCells(evaluator, entry, tagName, actionValue, index);
      if (cells.isNotEmpty) {
        rows.add(DataRow(cells: cells));
      }
      index++;
      continue;
    }
    index++;
  }
  return rows;
}

List<DataCell> _buildCells(
  Evaluator evaluator,
  Object? value,
  String tagName,
  String? actionValue,
  int rowIndex,
) {
  if (value is Iterable) {
    final cells = <DataCell>[];
    var columnIndex = 0;
    for (final entry in value) {
      cells.add(_buildCell(evaluator, entry, tagName, actionValue, rowIndex, columnIndex));
      columnIndex++;
    }
    return cells;
  }
  if (value == null) {
    return const [];
  }
  return [
    _buildCell(evaluator, value, tagName, actionValue, rowIndex, 0),
  ];
}

DataCell _buildCell(
  Evaluator evaluator,
  Object? value,
  String tagName,
  String? actionValue,
  int rowIndex,
  int columnIndex,
) {
  if (value is DataCell) {
    return value;
  }
  if (value is Map) {
    final childValue = value['child'] ?? value['value'] ?? value['text'];
    final child = resolveTextWidget(childValue) ?? const SizedBox.shrink();
    final placeholder = toBool(value['placeholder']) ?? false;
    final showEditIcon = toBool(value['showEditIcon']) ?? false;
    final onTapValue = value['onTap'] ?? value['action'] ?? actionValue;
    final event = buildWidgetEvent(
      tag: tagName,
      id: tagName,
      key: tagName,
      action: onTapValue is String ? onTapValue : actionValue,
      event: 'cell_tap',
      props: {
        'rowIndex': rowIndex,
        'columnIndex': columnIndex,
      },
    );
    final onTap = resolveActionCallback(
      evaluator,
      onTapValue,
      event: event,
      actionValue: onTapValue is String ? onTapValue : actionValue,
    );
    return DataCell(
      child,
      placeholder: placeholder,
      showEditIcon: showEditIcon,
      onTap: onTap,
    );
  }
  final child = resolveTextWidget(value) ?? const SizedBox.shrink();
  return DataCell(child);
}

MaterialStateProperty<Color?>? _resolveRowColor(Object? value) {
  return toWidgetStateColor(value);
}

LocalKey? _resolveKey(Object? value) {
  if (value == null) {
    return null;
  }
  return ValueKey(value);
}
