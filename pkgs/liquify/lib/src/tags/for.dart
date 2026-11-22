import 'dart:convert';

import 'package:liquify/src/ast.dart';
import 'package:liquify/src/buffer.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/exceptions.dart';
import 'package:liquify/src/tags/tag.dart';

class ForLoopObject {
  final int length;
  final String? name;
  final ForLoopObject? parentloop;
  int index;
  int index0;
  int rindex;
  int rindex0;
  bool first;
  bool last;

  ForLoopObject({
    required this.length,
    this.name,
    this.parentloop,
    this.index = 1,
    this.index0 = 0,
  }) : rindex = length,
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
  }

  Map<String, dynamic> toMap() {
    return {
      'length': length,
      if (name != null) 'name': name,
      'parentloop': parentloop?.toMap(),
      'index': index,
      'index0': index0,
      'rindex': rindex,
      'rindex0': rindex0,
      'first': first,
      'last': last,
    };
  }

  ForLoopObject.fromJson(Map<String, dynamic> json)
    : length = json['length'],
      name = json['name'],
      parentloop = json['parentloop'] != null
          ? ForLoopObject.fromJson(json['parentloop'])
          : null,
      index = json['index'],
      index0 = json['index0'],
      rindex = json['rindex'],
      rindex0 = json['rindex0'],
      first = json['first'],
      last = json['last'];
}

class ForTag extends AbstractTag with AsyncTag {
  late String variableName;
  late String loopName;
  late List<dynamic> iterable;
  int? limit;
  int? offset;
  bool reversed = false;

  ForTag(super.content, super.filters);

  String _collectionName(ASTNode node) => switch (node) {
    Identifier(:final name) => name,
    MemberAccess(:final object, :final members) => [
      _collectionName(object),
      ...members.map(_collectionName),
    ].join('.'),
    ArrayAccess(:final array, :final key) =>
      '${_collectionName(array)}[${_collectionName(key)}]',
    BinaryOperation(left: final start, operator: '..', right: final end) =>
      '(${_collectionName(start)}..${_collectionName(end)})',
    Literal(:final value) => value.toString(),
    _ => '',
  };

  @override
  void preprocess(Evaluator evaluator) {
    if (content.isEmpty || content.first is! BinaryOperation) {
      throw Exception('ForTag requires a binary operation.');
    }

    final binaryOperation = content.first as BinaryOperation;
    if (binaryOperation.operator != 'in') {
      throw Exception('ForTag requires an "in" binary operation.');
    }

    final left = binaryOperation.left;
    final right = binaryOperation.right;

    if (left is! Identifier) {
      throw Exception(
        'ForTag requires an identifier on the left side of "in".',
      );
    }

    variableName = left.name;
    loopName = '$variableName-${_collectionName(right)}';
    final continuationKey = '$variableName-${jsonEncode(right.toJson())}';

    final collection = evaluator.evaluate(right);

    final offsets =
        evaluator.context.registers.putIfAbsent('for', () => <String, int>{})
            as Map<String, int>;

    for (final arg in namedArgs) {
      if (arg.identifier.name == 'limit') {
        limit = evaluator.evaluate(arg.value);
      } else if (arg.identifier.name == 'offset') {
        final value = arg.value;
        offset = value is Identifier && value.name == 'continue'
            ? offsets[continuationKey]
            : evaluator.evaluate(value);
      }
    }

    final modifier = content.length > 1 ? content[1] : null;
    reversed = modifier is Identifier && modifier.name == 'reversed';

    final startOffset = offset ?? 0;
    iterable = sliceLoopItems(collection, startOffset, limit);
    offsets[continuationKey] =
        (startOffset < 0 ? 0 : startOffset) + iterable.length;

    if (reversed) {
      iterable = iterable.reversed.toList();
    }
  }

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    if (iterable.isEmpty) {
      final elseBlock = body
          .where((node) => node is Tag && node.name == 'else')
          .firstOrNull;
      if (elseBlock != null) {
        for (final node in (elseBlock as Tag).body) {
          if (node is Tag) {
            evaluator.evaluate(node);
          } else {
            buffer.write(evaluator.evaluate(node));
          }
        }
      }
      return;
    }

    final parentLoop = evaluator.context.getVariable('forloop');
    final forLoop = ForLoopObject(
      length: iterable.length,
      name: loopName,
      parentloop: parentLoop is Map<String, dynamic>
          ? ForLoopObject.fromJson(parentLoop)
          : null,
    );

    evaluator.context.pushScope();

    Map<String, dynamic> merged = {};
    try {
      outerLoop:
      for (final item in iterable) {
        evaluator.context.setVariable('forloop', forLoop.toMap());
        evaluator.context.setVariable(variableName, item);

        for (final node in body) {
          if (node is Tag && node.name == 'else') continue;

          try {
            if (node is Tag) {
              evaluator.evaluate(node);
            } else {
              buffer.write(evaluator.evaluate(node));
            }
          } on BreakException {
            return;
          } on ContinueException {
            forLoop.increment();
            continue outerLoop;
          }
        }

        forLoop.increment();
      }
    } finally {
      merged = evaluator.context.all();
      evaluator.context.popScope();
      merged.remove('forloop');
      merged.remove(variableName);
      evaluator.context.merge(merged);
    }
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    if (iterable.isEmpty) {
      final elseBlock = body
          .where((node) => node is Tag && node.name == 'else')
          .firstOrNull;
      if (elseBlock != null) {
        for (final node in (elseBlock as Tag).body) {
          if (node is Tag) {
            await evaluator.evaluateAsync(node);
          } else {
            buffer.write(await evaluator.evaluateAsync(node));
          }
        }
      }
      return;
    }

    final parentLoop = evaluator.context.getVariable('forloop');
    final forLoop = ForLoopObject(
      length: iterable.length,
      name: loopName,
      parentloop: parentLoop is Map<String, dynamic>
          ? ForLoopObject.fromJson(parentLoop)
          : null,
    );

    evaluator.context.pushScope();

    Map<String, dynamic> merged = {};
    try {
      outerLoop:
      for (final item in iterable) {
        evaluator.context.setVariable('forloop', forLoop.toMap());
        evaluator.context.setVariable(variableName, item);

        for (final node in body) {
          if (node is Tag && node.name == 'else') continue;

          try {
            if (node is Tag) {
              await evaluator.evaluateAsync(node);
            } else {
              buffer.write(await evaluator.evaluateAsync(node));
            }
          } on BreakException {
            return;
          } on ContinueException {
            forLoop.increment();
            continue outerLoop;
          }
        }

        forLoop.increment();
      }
    } finally {
      merged = evaluator.context.all();
      evaluator.context.popScope();
      merged.remove('forloop');
      merged.remove(variableName);
      evaluator.context.merge(merged);
    }
  }
}

/// Selects the items for the built-in Liquid iteration tags.
List<dynamic> sliceLoopItems(Object? collection, int offset, int? limit) {
  // Liquid iterates a nonempty string as a single item, regardless of slice options.
  if (collection is String) return collection.isEmpty ? [] : [collection];

  final Iterable<dynamic> items = switch (collection) {
    Map() => collection.entries.map((entry) => [entry.key, entry.value]),
    Iterable() => collection,
    _ => const [],
  };
  final remaining = offset > 0 ? items.skip(offset) : items;
  return (limit == null ? remaining : remaining.take(limit < 0 ? 0 : limit))
      .toList();
}
