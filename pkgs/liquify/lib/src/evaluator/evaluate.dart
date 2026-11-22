part of 'evaluator.dart';

extension Evaluation on Evaluator {
  bool liquidEquals(Object? left, Object? right) {
    if (left is ConditionPredicate) return _matchesPredicate(left, right);
    if (right is ConditionPredicate) return _matchesPredicate(right, left);
    return left == right;
  }

  bool _matchesPredicate(ConditionPredicate predicate, Object? value) {
    if (predicate == ConditionPredicate.blank) {
      if (value == null || value == false) return true;
      if (value is String) return _blankString.hasMatch(value);
    }

    return switch (value) {
      String() => value.isEmpty,
      List() => value.isEmpty,
      Map() => value.isEmpty,
      _ => false,
    };
  }

  int? _compare(Object? left, Object? right) {
    if (left is num && right is num) {
      if (left == right) return 0;
      if (left < right) return -1;
      return left > right ? 1 : null;
    }
    if (left is String && right is String) return left.compareTo(right);
    if ((left is num || left is String) && (right is num || right is String)) {
      throw ArgumentError(
        'Cannot compare ${left.runtimeType} with ${right.runtimeType}',
      );
    }
    return null;
  }

  dynamic _lookupMember(Object? value, String name) {
    if (value is Drop) return value(Symbol(name));
    if (value is Map && value.containsKey(name)) return value[name];
    if (value is! List && value is! String && value is! Map && value is! int) {
      return null;
    }
    if (!FilterRegistry.isDotNotationFilter(name)) return null;
    return FilterRegistry.getFilter(name)?.call(value, [], {});
  }

  dynamic _lookupIndex(Object? value, Object? key) {
    if (value is Drop && key is String) return value(Symbol(key));
    if (value is Map) return value[key];
    if (value is! List || key is! int) return null;
    final index = key < 0 ? value.length + key : key;
    return index >= 0 && index < value.length ? value[index] : null;
  }

  dynamic evaluate(ASTNode node) {
    return node.accept(this);
  }

  Future<dynamic> evaluateAsync(ASTNode node) {
    return node.acceptAsync(this);
  }

  List<ASTNode> resolveAndParseTemplate(String templateName) {
    final root = context.getRoot();
    if (root == null) {
      throw Exception('No root directory set for template resolution');
    }

    final source = root.resolve(templateName);
    return parseInput(source.content);
  }

  Future<List<ASTNode>> resolveAndParseTemplateAsync(
    String templateName,
  ) async {
    final root = context.getRoot();
    if (root == null) {
      throw Exception('No root directory set for template resolution');
    }
    final source = await root.resolveAsync(templateName);
    return parseInput(source.content);
  }

  String evaluateNodes(List<ASTNode> nodes) {
    // Like Shopify Liquid, store continuation in the render's for register.
    // Tag environment clones share the register value within that render.
    final ownsForRegister = !context.registers.containsKey('for');
    if (ownsForRegister) context.setRegister('for', <String, int>{});
    try {
      for (final node in nodes) {
        if (node is Assignment) continue;
        if (node is Tag) {
          node.accept(this);
        } else {
          currentBuffer.write(node.accept(this));
        }
      }
      return buffer.toString();
    } finally {
      if (ownsForRegister) context.removeRegister('for');
    }
  }

  Future<dynamic> evaluateNodesAsync(List<ASTNode> nodes) async {
    // Like Shopify Liquid, store continuation in the render's for register.
    // Tag environment clones share the register value within that render.
    final ownsForRegister = !context.registers.containsKey('for');
    if (ownsForRegister) context.setRegister('for', <String, int>{});
    try {
      for (final node in nodes) {
        if (node is Assignment) continue;
        if (node is Tag) {
          await node.acceptAsync(this);
        } else {
          currentBuffer.write(await node.acceptAsync(this));
        }
      }
      return buffer.toString();
    } finally {
      if (ownsForRegister) context.removeRegister('for');
    }
  }
}

// Match the whitespace characters in Ruby's condition predicate.
final _blankString = RegExp(r'^[ \t\n\r\f\x0B]*$');
