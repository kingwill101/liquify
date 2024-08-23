import 'package:liquify/src/tag.dart';

class TableRowLoopObject {
  final int length;
  final TableRowLoopObject? parentloop;
  final int cols;
  int index;
  int index0;
  int rindex;
  int rindex0;
  bool first;
  bool last;
  int row;
  int col;
  int col0;
  bool colFirst;
  bool colLast;

  TableRowLoopObject({
    required this.length,
    required this.cols,
    this.parentloop,
    this.index = 1,
    this.index0 = 0,
    this.row = 1,
    this.col = 1,
    this.col0 = 0,
    this.colFirst = true,
    this.colLast = false,
  })  : rindex = length,
        rindex0 = length - 1,
        first = true,
        last = length == 1;

  void increment() {
    index++;
    index0++;
    rindex--;
    rindex0--;

    first = false;
    last = index == length;

    col++;
    col0++;
    colFirst = col == 1;
    colLast = col == cols;
  }

  Map<String, dynamic> toMap() {
    return {
      'length': length,
      'parentloop': parentloop?.toMap(),
      'index': index,
      'index0': index0,
      'rindex': rindex,
      'rindex0': rindex0,
      'first': first,
      'last': last,
      'row': row,
      'col': col,
      'col0': col0,
      'col_first': colFirst,
      'col_last': colLast,
    };
  }

  TableRowLoopObject.fromJson(Map<String, dynamic> json)
      : length = json['length'],
        cols = json['cols'],
        parentloop = json['parentloop'] != null
            ? TableRowLoopObject.fromJson(json['parentloop'])
            : null,
        index = json['index'],
        index0 = json['index0'],
        rindex = json['rindex'],
        rindex0 = json['rindex0'],
        first = json['first'],
        last = json['last'],
        row = json['row'],
        col = json['col'],
        col0 = json['col0'],
        colFirst = json['col_first'],
        colLast = json['col_last'];
}

class TableRowTag extends AbstractTag with CustomTagParser {
  late Identifier accessor;
  late List<dynamic> iterable;
  int? limit;
  int? offset;
  bool reversed = false;
  int cols = 0;

  TableRowTag(super.content, super.filters);

  @override
  void preprocess(Evaluator evaluator) {
    if (content.isEmpty || content.first is! BinaryOperation) {
      throw Exception('TableRowTag requires a binary operation.');
    }

    final binaryOperation = content.first as BinaryOperation;
    if (binaryOperation.operator != 'in') {
      throw Exception('TableRowTag requires an "in" binary operation.');
    }

    final left = binaryOperation.left;
    final right = binaryOperation.right;

    if (left is! Identifier) {
      throw Exception(
          'TableRowTag requires an identifier on the left side of "in".');
    }

    accessor = left;

    if (right is BinaryOperation && right.operator == '..') {
      iterable = evaluator.evaluate(right);
    } else if (right is MemberAccess || right is Identifier) {
      iterable = evaluator.evaluate(right) ?? [];
    } else {
      throw Exception('Unsupported argument');
    }

    // Process filters for limit, offset, cols, and reversed
    for (final arg in namedArgs) {
      if (arg.identifier.name == 'limit') {
        limit = evaluator.evaluate(arg.value);
      } else if (arg.identifier.name == 'offset') {
        offset = evaluator.evaluate(arg.value);
      } else if (arg.identifier.name == 'cols') {
        cols = evaluator.evaluate(arg.value) as int;
      }
    }

    for (final arg in args) {
      if (arg.name == 'reversed') {
        reversed = true;
      }
    }

    // Apply offset
    if (offset != null) {
      iterable = iterable.skip(offset!).toList();
    }

    // Apply limit
    if (limit != null) {
      iterable = iterable.take(limit!).toList();
    }

    // Apply reversed
    if (reversed) {
      iterable = iterable.reversed.toList();
    }
    // If cols is not set, default to the length of the iterable
    if (cols == 0) {
      cols = iterable.length;
    }
  }

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    if (iterable.isEmpty) return;
    final parentLoop =
        evaluator.context.getVariable('tablerowloop') as Map<String, dynamic>?;
    final tableRowLoop = TableRowLoopObject(
        length: iterable.length,
        cols: cols,
        parentloop: parentLoop == null
            ? null
            : TableRowLoopObject.fromJson(parentLoop));

    evaluator.context.pushScope();

    buffer.writeln('  <tr class="row${tableRowLoop.row}">');
    for (var i = 0; i < iterable.length; i++) {
      final item = iterable[i];
      evaluator.context.setVariable('tablerowloop', tableRowLoop.toMap());
      evaluator.context.setVariable(accessor.name, item);
      buffer.writeln('    <td class="col${tableRowLoop.col}">');

      String inner = '      ';
      for (final node in body) {
        inner += evaluator.evaluate(node).toString();
      }
      buffer.write(inner);
      buffer.writeln('    </td>');

      if (tableRowLoop.col == cols) {
        // End of row
        buffer.write('  </tr>');
        if (i < iterable.length - 1) {
          // If not the last item, start a new row
          tableRowLoop.row++;
          buffer.writeln('\n  <tr class="row${tableRowLoop.row}">');
        }

        tableRowLoop.col = 0; // Reset column index
      }
      tableRowLoop.increment();
    }

    if (tableRowLoop.col != 1) {
      // Close the last row if it's not already closed
      buffer.write('  </tr>');
    }

    evaluator.context.popScope();
  }

  @override
  Parser parser() {
    return (ref0(tableRowTag).trim() &
            any().plusLazy(endTableRowTag()) &
            endTableRowTag())
        .map((values) {
      final tag = values[0] as Tag;
      tag.body = parseInput((values[1] as List).join(''));
      return tag;
    });
  }
}

Parser tableRowTag() => someTag("tablerow");

Parser endTableRowTag() =>
    (tagStart() & string('endtablerow').trim() & tagEnd()).map((values) {
      return Tag('endtablerow', []);
    });
