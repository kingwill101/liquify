part of 'evaluator.dart';

// extension SyncVisits on Evaluator {
//   @override
//   dynamic visitLiteral(Literal node) {
//     return node.value;
//   }
//
//   @override
//   dynamic visitIdentifier(Identifier node) {
//     final value = context.getVariable(node.name);
//     return value;
//   }
//
//   @override
//   dynamic visitBinaryOperation(BinaryOperation node) {
//     final left = node.left.accept(this);
//     final right = node.right.accept(this);
//     switch (node.operator) {
//       case '+': return left + right;
//       case '-': return left - right;
//       case '*': return left * right;
//       case '/': return left / right;
//       case '==': return left == right;
//       case '!=': return left != right;
//       case '<': return left < right;
//       case '>': return left > right;
//       case '<=': return left <= right;
//       case '>=': return left >= right;
//       case 'and': return isTruthy(left) && isTruthy(right);
//       case 'or': return isTruthy(left) || isTruthy(right);
//       case '..': return List.generate(right - left + 1, (index) => left + index);
//       case 'in':
//         if (right is! Iterable) {
//           throw Exception('Right side of "in" operator must be iterable.');
//         }
//         return right.contains(left);
//       default:
//         throw UnsupportedError('Unsupported operator: ${node.operator}');
//     }
//   }
//
//   @override
//   dynamic visitUnaryOperation(UnaryOperation node) {
//     final expr = node.expression.accept(this);
//     switch (node.operator) {
//       case 'not':
//       case '!':
//         return !expr;
//       default:
//         throw UnsupportedError('Unsupported operator: ${node.operator}');
//     }
//   }
//
//   @override
//   dynamic visitGroupedExpression(GroupedExpression node) {
//     return node.expression.accept(this);
//   }
//
//   @override
//   dynamic visitAssignment(Assignment node) {
//     final value = node.value.accept(this);
//     if (node.variable is Identifier) {
//       context.setVariable((node.variable as Identifier).name, value);
//     } else if (node.variable is MemberAccess) {
//       final memberAccess = node.variable as MemberAccess;
//       final objName = (memberAccess.object as Identifier).name;
//
//       if (context.getVariable(objName) == null) {
//         context.setVariable(objName, {});
//       }
//
//       var objectVal = context(objName);
//       for (var i = 0; i < memberAccess.members.length; i++) {
//         final name = (memberAccess.members[i] as Identifier).name;
//         if (i == memberAccess.members.length - 1) {
//           objectVal[name] = value;
//         } else {
//           if (!(objectVal as Map).containsKey(memberAccess.members[i])) {
//             objectVal[name] = {};
//           }
//           objectVal = objectVal[name];
//         }
//       }
//     }
//   }
//
//   @override
//   dynamic visitDocument(Document node) {
//     return evaluateNodes(node.children);
//   }
//
//   @override
//   dynamic visitFilter(Filter node) {
//     final filterFunction = context.getFilter(node.name.name);
//     if (filterFunction == null) {
//       throw Exception('Undefined filter: ${node.name.name}');
//     }
//
//     final args = <dynamic>[];
//     final namedArgs = <String, dynamic>{};
//
//     for (final arg in node.arguments) {
//       if (arg is NamedArgument) {
//         namedArgs[arg.identifier.name] = arg.value.accept(this);
//       } else {
//         args.add(arg.accept(this));
//       }
//     }
//
//     return (value) => filterFunction(value, args, namedArgs);
//   }
//
//   @override
//   dynamic visitFilterExpression(FilteredExpression node) {
//     dynamic value;
//     if (node.expression is Assignment) {
//       (node.expression as Assignment).value.accept(this);
//       if ((node.expression as Assignment).value is Literal) {
//         value = ((node.expression as Assignment).value as Literal).value;
//       } else {
//         value = context.getVariable(
//             ((node.expression as Assignment).value as Identifier).name);
//       }
//     } else {
//       value = node.expression.accept(this);
//     }
//
//     for (final filter in node.filters) {
//       final filterFunction = filter.accept(this);
//       value = filterFunction(value);
//     }
//     return value;
//   }
//
//   @override
//   dynamic visitMemberAccess(MemberAccess node) {
//     var object = node.object;
//     final objName = (object as Identifier).name;
//     var objectVal = context.getVariable(objName);
//
//     if (objectVal == null) return null;
//
//     for (final member in node.members) {
//       final keyName = member is Identifier
//           ? member.name
//           : ((member as ArrayAccess).array as Identifier).name;
//       final isArray = member is ArrayAccess;
//
//       if (isArray) {
//         final key = (member.array as Identifier).name;
//         final index = (member.key as Literal).value;
//         objectVal = objectVal[key];
//
//         if (objectVal == null) return;
//         if (objectVal is List) {
//           if (index >= 0 && index < objectVal.length) {
//             objectVal = objectVal[index];
//           } else {
//             return null;
//           }
//         } else {
//           objectVal = objectVal[index];
//         }
//       } else if (objectVal is Drop) {
//         if (member is Identifier) {
//           objectVal = objectVal(Symbol(keyName));
//         }
//       } else if (objectVal is Map) {
//         if (!objectVal.containsKey(keyName)) {
//           return null;
//         }
//         objectVal = objectVal[keyName];
//       } else if (objectVal == null) {
//         return null;
//       }
//     }
//     return objectVal;
//   }
//
//   @override
//   dynamic visitNamedArgument(NamedArgument node) {
//     return MapEntry(node.identifier.name, node.value.accept(this));
//   }
//
//   @override
//   dynamic visitTag(Tag node) {
//     final tag = TagRegistry.createTag(node.name, node.content, node.filters);
//     tag?.preprocess(this);
//     tag?.body = node.body;
//     tag?.evaluate(this, buffer);
//   }
//
//   @override
//   dynamic visitTextNode(TextNode node) {
//     return node.text;
//   }
//
//   @override
//   dynamic visitVariable(Variable node) {
//     return node.expression.accept(this);
//   }
//
//   @override
//   visitArrayAccess(ArrayAccess arrayAccess) {
//     final array = arrayAccess.array.accept(this);
//     final key = arrayAccess.key.accept(this);
//     if (array is List) {
//       final index = key is int ? key : int.parse(key);
//       if (index >= 0 && index < array.length) {
//         return array[index];
//       }
//     } else if (array is Map && array.containsKey(key)) {
//       return array[key];
//     }
//     return null;
//   }
// }
