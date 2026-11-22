import 'package:liquify/src/exceptions.dart';
import 'package:liquify/src/tag.dart';
import 'package:liquify/src/tags/for.dart' show sliceLoopItems;
import 'package:liquify/src/util.dart' show isTruthy;

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
    bool? colLast,
  }) : colLast = colLast ?? col == cols,
       rindex = length,
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

    if (col == cols) {
      row++;
      col = 1;
    } else {
      col++;
    }
    col0 = col - 1;
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
      cols = json['cols'] as int? ?? 0,
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

class TableRowTag extends AbstractTag with CustomTagParser, AsyncTag {
  late Identifier accessor;
  late List<dynamic> iterable;
  bool hasCollection = false;
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
        'TableRowTag requires an identifier on the left side of "in".',
      );
    }

    accessor = left;

    final collection = evaluator.evaluate(right);
    hasCollection = isTruthy(collection);

    for (final arg in namedArgs) {
      if (arg.identifier.name == 'limit') {
        limit = evaluator.evaluate(arg.value);
      } else if (arg.identifier.name == 'offset') {
        offset = evaluator.evaluate(arg.value);
      } else if (arg.identifier.name == 'cols') {
        cols = evaluator.evaluate(arg.value) as int;
      }
    }

    iterable = sliceLoopItems(collection, offset ?? 0, limit);

    if (cols == 0) {
      cols = iterable.length;
    }
  }

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    if (!hasCollection) return;

    final parentLoop = evaluator.context.getVariable('tablerowloop');
    final tableRowLoop = TableRowLoopObject(
      length: iterable.length,
      cols: cols,
      parentloop: parentLoop is Map<String, dynamic>
          ? TableRowLoopObject.fromJson(parentLoop)
          : null,
    );

    evaluator.context.pushScope();

    try {
      buffer.writeln('<tr class="row1">');

      for (var i = 0; i < iterable.length; i++) {
        evaluator.context.setVariable('tablerowloop', tableRowLoop.toMap());
        evaluator.context.setVariable(accessor.name, iterable[i]);

        buffer.write('<td class="col${tableRowLoop.col}">');
        try {
          evaluator.evaluateBody(body);
        } on BreakException {
          break;
        } on ContinueException {
          // Continue with the next cell after closing this one.
        } finally {
          buffer.write('</td>');
        }

        final endsRow = tableRowLoop.colLast;
        tableRowLoop.increment();
        if (endsRow && i < iterable.length - 1) {
          buffer.write('</tr>\n<tr class="row${tableRowLoop.row}">');
        }
      }
      buffer.writeln('</tr>');
    } finally {
      evaluator.context.popScope();
    }
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    if (!hasCollection) return;

    final parentLoop = evaluator.context.getVariable('tablerowloop');
    final tableRowLoop = TableRowLoopObject(
      length: iterable.length,
      cols: cols,
      parentloop: parentLoop is Map<String, dynamic>
          ? TableRowLoopObject.fromJson(parentLoop)
          : null,
    );

    evaluator.context.pushScope();

    try {
      buffer.writeln('<tr class="row1">');

      for (var i = 0; i < iterable.length; i++) {
        evaluator.context.setVariable('tablerowloop', tableRowLoop.toMap());
        evaluator.context.setVariable(accessor.name, iterable[i]);

        buffer.write('<td class="col${tableRowLoop.col}">');
        try {
          await evaluator.evaluateBodyAsync(body);
        } on BreakException {
          break;
        } on ContinueException {
          // Continue with the next cell after closing this one.
        } finally {
          buffer.write('</td>');
        }

        final endsRow = tableRowLoop.colLast;
        tableRowLoop.increment();
        if (endsRow && i < iterable.length - 1) {
          buffer.write('</tr>\n<tr class="row${tableRowLoop.row}">');
        }
      }
      buffer.writeln('</tr>');
    } finally {
      evaluator.context.popScope();
    }
  }

  @override
  Parser parser([LiquidConfig? config]) {
    return (tableRowTag(config) &
            any().plusLazy(endTableRowTag(config)) &
            endTableRowTag(config))
        .map((values) {
          final tag = values[0] as Tag;
          tag.body = parseInput((values[1] as List).join(''));
          return tag;
        });
  }
}

Parser tableRowTag([LiquidConfig? config]) =>
    someTag("tablerow", config: config);

Parser endTableRowTag([LiquidConfig? config]) =>
    (createTagStart(config) &
            string('endtablerow').trim() &
            createTagEnd(config))
        .map((values) {
          return Tag('endtablerow', []);
        });
