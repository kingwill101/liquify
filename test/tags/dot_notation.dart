import 'package:test/test.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/context.dart';
import 'package:liquify/src/ast.dart';
import 'package:liquify/src/filter_registry.dart';

void main() {
  group('Dot notation filters', () {
    setUp(() {
      // Register built-in dot notation filters
      FilterRegistry.register('size', (value, args, namedArgs) => value.length,
          dotNotation: true);
      FilterRegistry.register('first', (value, args, namedArgs) => value.first,
          dotNotation: true);
      FilterRegistry.register('last', (value, args, namedArgs) => value.last,
          dotNotation: true);
    });

    test('should apply size filter using dot notation', () {
      final context = Environment({
        'site': {
          'pages': [1, 2, 3, 4, 5]
        }
      });
      final evaluator = Evaluator(context);
      final node = MemberAccess(
        Identifier('site'),
        [Identifier('pages'), Identifier('size')],
      );

      final result = evaluator.visitMemberAccess(node);
      expect(result, 5);
    });

    test('should apply first filter using dot notation', () {
      final context = Environment({
        'collection': {
          'products': [
            {'title': 'Product 1'},
            {'title': 'Product 2'}
          ]
        }
      });
      final evaluator = Evaluator(context);
      final node = MemberAccess(
        Identifier('collection'),
        [Identifier('products'), Identifier('first')],
      );

      final result = evaluator.visitMemberAccess(node);
      expect(result, {'title': 'Product 1'});
    });

    test('should apply last filter using dot notation', () {
      final context = Environment({
        'collection': {
          'products': [
            {'title': 'Product 1'},
            {'title': 'Product 2'}
          ]
        }
      });
      final evaluator = Evaluator(context);
      final node = MemberAccess(
        Identifier('collection'),
        [Identifier('products'), Identifier('last')],
      );

      final result = evaluator.visitMemberAccess(node);
      expect(result, {'title': 'Product 2'});
    });

    test(
        'should allow library users to register their own dot notation filters',
        () {
      // Register a custom dot notation filter
      FilterRegistry.register(
          'custom', (value, args, namedArgs) => 'custom filter applied',
          dotNotation: true);

      final context = Environment({'data': 'test'});
      final evaluator = Evaluator(context);
      final node = MemberAccess(
        Identifier('data'),
        [Identifier('custom')],
      );

      final result = evaluator.visitMemberAccess(node);
      expect(result, 'custom filter applied');
    });
  });
}
