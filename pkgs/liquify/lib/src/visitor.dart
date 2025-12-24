import 'ast.dart';

abstract class ASTVisitor<T> {
  T visitDocument(Document node);

  T visitTag(Tag node);

  T visitLiteral(Literal node);

  T visitIdentifier(Identifier node);

  T visitBinaryOperation(BinaryOperation node);

  T visitUnaryOperation(UnaryOperation node);

  T visitGroupedExpression(GroupedExpression node);

  T visitAssignment(Assignment node);

  T visitTextNode(TextNode node);

  T visitFilterExpression(FilteredExpression node);

  T visitVariable(Variable node);

  T visitFilter(Filter node);

  T visitMemberAccess(MemberAccess node);

  T visitNamedArgument(NamedArgument node);

  T visitArrayAccess(ArrayAccess arrayAccess);

  // Asynchronous methods
  Future<T> visitDocumentAsync(Document node);

  Future<T> visitTagAsync(Tag node);

  Future<T> visitLiteralAsync(Literal node);

  Future<T> visitIdentifierAsync(Identifier node);

  Future<T> visitBinaryOperationAsync(BinaryOperation node);

  Future<T> visitUnaryOperationAsync(UnaryOperation node);

  Future<T> visitGroupedExpressionAsync(GroupedExpression node);

  Future<T> visitAssignmentAsync(Assignment node);

  Future<T> visitTextNodeAsync(TextNode node);

  Future<T> visitFilterExpressionAsync(FilteredExpression node);

  Future<T> visitVariableAsync(Variable node);

  Future<T> visitFilterAsync(Filter node);

  Future<T> visitMemberAccessAsync(MemberAccess node);

  Future<T> visitNamedArgumentAsync(NamedArgument node);

  Future<T> visitArrayAccessAsync(ArrayAccess arrayAccess);
}
