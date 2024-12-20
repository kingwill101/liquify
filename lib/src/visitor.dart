import 'dart:async';
import 'ast.dart';

abstract class ASTVisitor<T> {
  Future<T> visitDocument(Document node);
  Future<T> visitTag(Tag node);
  Future<T> visitLiteral(Literal node);
  Future<T> visitIdentifier(Identifier node);
  Future<T> visitBinaryOperation(BinaryOperation node);
  Future<T> visitUnaryOperation(UnaryOperation node);
  Future<T> visitGroupedExpression(GroupedExpression node);
  Future<T> visitAssignment(Assignment node);
  Future<T> visitTextNode(TextNode node);
  Future<T> visitFilterExpression(FilteredExpression node);
  Future<T> visitVariable(Variable node);
  Future<T> visitFilter(Filter node);
  Future<T> visitMemberAccess(MemberAccess node);
  Future<T> visitNamedArgument(NamedArgument node);
  Future<T> visitArrayAccess(ArrayAccess arrayAccess);
}
