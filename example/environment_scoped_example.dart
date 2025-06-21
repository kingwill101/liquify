import 'dart:async';
import 'package:liquify/liquify.dart';
import 'package:liquify/parser.dart';


void main() async {
  print('=== Environment-Scoped Registry Examples ===\n');

  // Example 1: Template with environment setup callback
  print('1. Template with environment setup callback:');
  final template1 = Template.parse(
    'Hello {{ name }}! {% custom_greeting %} Result: {{ status | emphasize }}',
    data: {'name': 'World', 'status': 'success'},
    environmentSetup: (env) {
      // Register custom filters and tags for this template only
      env.registerLocalFilter('emphasize', (value, args, namedArgs) {
        return '***${value.toString().toUpperCase()}***';
      });
      env.registerLocalTag('custom_greeting', (content, filters) {
        return CustomGreetingTag(content, filters);
      });
    },
  );

  final result1 = await template1.renderAsync();
  print('Output: $result1\n');

  // Example 2: Secure template with strict mode
  print('2. Secure template with strict mode:');
  final secureEnv = Environment.withStrictMode();
  secureEnv.registerLocalFilter('sanitize', (value, args, namedArgs) {
    return 'CLEAN:${value.toString().replaceAll(RegExp(r'[<>]'), '')}';
  });
  secureEnv.registerLocalFilter('truncate', (value, args, namedArgs) {
    final str = value.toString();
    final maxLen = args.isNotEmpty ? args[0] as int : 10;
    return str.length > maxLen ? '${str.substring(0, maxLen)}...' : str;
  });

  final secureTemplate = Template.parse(
    'Safe content: {{ userInput | sanitize | truncate: 15 }}',
    data: {'userInput': '<script>alert("hack")</script>This is a long message'},
    environment: secureEnv,
  );

  final result2 = await secureTemplate.renderAsync();
  print('Output: $result2\n');

  // Example 3: Environment isolation between templates
  print('3. Environment isolation between templates:');
  final template3a = Template.parse(
    'Template A: {{ value | format }}',
    data: {'value': 'test'},
    environmentSetup: (env) {
      env.registerLocalFilter('format', (value, args, namedArgs) => 'FORMAT_A:$value');
    },
  );

  final template3b = Template.parse(
    'Template B: {{ value | format }}',
    data: {'value': 'test'},
    environmentSetup: (env) {
      env.registerLocalFilter('format', (value, args, namedArgs) => 'FORMAT_B:$value');
    },
  );

  final result3a = await template3a.renderAsync();
  final result3b = await template3b.renderAsync();
  print('Output A: $result3a');
  print('Output B: $result3b\n');

  // Example 4: Dynamic environment modification
  print('4. Dynamic environment modification:');
  final dynamicTemplate = Template.parse(
    'Before: {{ message | transform }}\nAfter: {{ message | transform }}',
    data: {'message': 'hello'},
  );

  // Register initial filter
  dynamicTemplate.environment.registerLocalFilter('transform', (value, args, namedArgs) {
    return 'INITIAL:$value';
  });

  final resultBefore = await dynamicTemplate.renderAsync(clearBuffer: false);
  
  // Change the filter behavior
  dynamicTemplate.environment.registerLocalFilter('transform', (value, args, namedArgs) {
    return 'UPDATED:$value';
  });

  final resultAfter = dynamicTemplate.renderAsync(clearBuffer: true);
  print('Combined output:\n${await resultAfter}\n');

  // Example 5: Complex nested environment with cloning
  print('5. Complex nested environment with cloning:');
  final baseEnv = Environment();
  baseEnv.registerLocalFilter('base_filter', (value, args, namedArgs) => 'BASE:$value');
  baseEnv.registerLocalTag('base_tag', (content, filters) => BaseTag(content, filters));

  final childEnv = baseEnv.clone();
  childEnv.registerLocalFilter('child_filter', (value, args, namedArgs) => 'CHILD:$value');
  childEnv.registerLocalTag('child_tag', (content, filters) => ChildTag(content, filters));

  final complexTemplate = Template.parse(
    '''
Base: {{ text | base_filter }}
Child: {{ text | child_filter }}
{% base_tag %}{% child_tag %}
    '''.trim(),
    data: {'text': 'test'},
    environment: childEnv,
  );

  final result5 = await complexTemplate.renderAsync();
  print('Output:\n$result5\n');

  print('=== All examples completed successfully! ===');
}

// Custom tag implementations for the examples
class CustomGreetingTag extends AbstractTag {
  CustomGreetingTag(super.content, super.filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    buffer.write('🎉 Welcome! 🎉');
  }

  @override
  FutureOr evaluateAsync(Evaluator evaluator, Buffer buffer) {
    return evaluate(evaluator, buffer);
  }
}

class BaseTag extends AbstractTag {
  BaseTag(super.content, super.filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    buffer.write('[BASE_TAG]');
  }

  @override
  FutureOr evaluateAsync(Evaluator evaluator, Buffer buffer) {
    return evaluate(evaluator, buffer);
  }
}

class ChildTag extends AbstractTag {
  ChildTag(super.content, super.filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    buffer.write('[CHILD_TAG]');
  }

  @override
  FutureOr evaluateAsync(Evaluator evaluator, Buffer buffer) {
    return evaluate(evaluator, buffer);
  }
} 