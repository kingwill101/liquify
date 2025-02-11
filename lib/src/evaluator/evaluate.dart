part of 'evaluator.dart';

extension Evaluation on Evaluator {
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
      String templateName) async {
    final root = context.getRoot();
    if (root == null) {
      throw Exception('No root directory set for template resolution');
    }
    final source = await root.resolveAsync(templateName);
    return parseInput(source.content);
  }

  String evaluateNodes(List<ASTNode> nodes) {
    for (final node in nodes) {
      if (node is Assignment) continue;
      if (node is Tag) {
        node.accept(this);
      } else {
        currentBuffer.write(node.accept(this));
      }
    }
    return buffer.toString();
  }

  Future<dynamic> evaluateNodesAsync(List<ASTNode> nodes) async {
    for (final node in nodes) {
      if (node is Assignment) continue;
      if (node is Tag) {
        await node.acceptAsync(this);
      } else {
        currentBuffer.write(await node.acceptAsync(this));
      }
    }
    return buffer.toString();
  }
}
