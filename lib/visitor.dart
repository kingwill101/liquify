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
}
