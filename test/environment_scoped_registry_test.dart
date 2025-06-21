import 'dart:async';

import 'package:test/test.dart';
import 'package:liquify/src/tags/tag.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/buffer.dart';
import 'package:liquify/src/registry.dart';
import 'package:liquify/liquify.dart';

void main() {
  group('Environment-Scoped Registry Tests', () {
    setUp(() {
      // Register built-in tags and filters for testing
      registerBuiltIns();
    });

    group('Environment-Scoped Filters', () {
      test('should register and retrieve environment-scoped filters', () {
        final env = Environment();
        
        // Register a filter only in this environment
        env.registerLocalFilter('uppercase', (value, args, namedArgs) {
          return value.toString().toUpperCase();
        });
        
        // Should be able to retrieve the local filter
        final filter = env.getFilter('uppercase');
        expect(filter, isNotNull);
        expect(filter!('hello', [], {}), equals('HELLO'));
      });

      test('should isolate filters between different environments', () {
        final env1 = Environment();
        final env2 = Environment();
        
        // Register different filters in each environment
        env1.registerLocalFilter('env1_filter', (value, args, namedArgs) => 'env1-$value');
        env2.registerLocalFilter('env2_filter', (value, args, namedArgs) => 'env2-$value');
        
        // env1 should have env1_filter but not env2_filter
        expect(env1.getFilter('env1_filter'), isNotNull);
        expect(env1.getFilter('env2_filter'), isNull);
        
        // env2 should have env2_filter but not env1_filter
        expect(env2.getFilter('env2_filter'), isNotNull);
        expect(env2.getFilter('env1_filter'), isNull);
      });

      test('should fallback to global registry when local filter not found', () {
        final env = Environment();
        
        // Register a global filter
        FilterRegistry.register('global_filter', (value, args, namedArgs) => 'global-$value');
        
        // Should find the global filter even though not registered locally
        final filter = env.getFilter('global_filter');
        expect(filter, isNotNull);
        expect(filter!('test', [], {}), equals('global-test'));
      });

      test('should prioritize local filters over global ones', () {
        final env = Environment();
        
        // Register global filter
        FilterRegistry.register('shared_name', (value, args, namedArgs) => 'global-$value');
        
        // Register local filter with same name
        env.registerLocalFilter('shared_name', (value, args, namedArgs) => 'local-$value');
        
        // Should get the local version
        final filter = env.getFilter('shared_name');
        expect(filter, isNotNull);
        expect(filter!('test', [], {}), equals('local-test'));
      });

      test('should list all available filters (local + global)', () {
        final env = Environment();
        
        // Register global filters
        FilterRegistry.register('global1', (value, args, namedArgs) => value);
        FilterRegistry.register('global2', (value, args, namedArgs) => value);
        
        // Register local filters
        env.registerLocalFilter('local1', (value, args, namedArgs) => value);
        env.registerLocalFilter('local2', (value, args, namedArgs) => value);
        
        final availableFilters = env.getAvailableFilters();
        expect(availableFilters, containsAll(['global1', 'global2', 'local1', 'local2']));
      });
    });

    group('Environment-Scoped Tags', () {
      test('should register and retrieve environment-scoped tags', () {
        final env = Environment();
        
        // Register a tag only in this environment
        env.registerLocalTag('custom_tag', (content, filters) => CustomTestTag(content, filters));
        
        // Should be able to retrieve the local tag
        final tag = env.getTag('custom_tag');
        expect(tag, isNotNull);
        expect(tag is Function, isTrue);
      });

      test('should isolate tags between different environments', () {
        final env1 = Environment();
        final env2 = Environment();
        
        // Register different tags in each environment
        env1.registerLocalTag('env1_tag', (content, filters) => CustomTestTag(content, filters));
        env2.registerLocalTag('env2_tag', (content, filters) => CustomTestTag(content, filters));
        
        // env1 should have env1_tag but not env2_tag
        expect(env1.getTag('env1_tag'), isNotNull);
        expect(env1.getTag('env2_tag'), isNull);
        
        // env2 should have env2_tag but not env1_tag
        expect(env2.getTag('env2_tag'), isNotNull);
        expect(env2.getTag('env1_tag'), isNull);
      });

      test('should fallback to global registry when local tag not found', () {
        final env = Environment();
        
        // Register a global tag
        TagRegistry.register('global_tag', (content, filters) => CustomTestTag(content, filters));
        
        // Should find the global tag even though not registered locally
        final tag = env.getTag('global_tag');
        expect(tag, isNotNull);
      });

      test('should prioritize local tags over global ones', () {
        final env = Environment();
        
        // Register global tag
        TagRegistry.register('shared_tag', (content, filters) => GlobalTestTag(content, filters));
        
        // Register local tag with same name
        env.registerLocalTag('shared_tag', (content, filters) => LocalTestTag(content, filters));
        
        // Should get the local version
        final tagCreator = env.getTag('shared_tag');
        expect(tagCreator, isNotNull);
        
        final tag = tagCreator!([], []);
        expect(tag, isA<LocalTestTag>());
      });

      test('should list all available tags (local + global)', () {
        final env = Environment();
        
        // Register global tags
        TagRegistry.register('global_tag1', (content, filters) => CustomTestTag(content, filters));
        TagRegistry.register('global_tag2', (content, filters) => CustomTestTag(content, filters));
        
        // Register local tags
        env.registerLocalTag('local_tag1', (content, filters) => CustomTestTag(content, filters));
        env.registerLocalTag('local_tag2', (content, filters) => CustomTestTag(content, filters));
        
        final availableTags = env.getAvailableTags();
        expect(availableTags, containsAll(['global_tag1', 'global_tag2', 'local_tag1', 'local_tag2']));
      });
    });

    group('Integration Tests - Actual Rendering', () {
      test('should demonstrate environment-scoped filters work with global fallback', () async {
        // Test that local filters take precedence over global ones
        final env = Environment();
        
        // Register a global filter
        FilterRegistry.register('test_filter', (value, args, namedArgs) => 'GLOBAL: $value');
        
        // Register a local filter with the same name
        env.registerLocalFilter('test_filter', (value, args, namedArgs) => 'LOCAL: $value');
        
        // Test that local takes precedence
        final filter = env.getFilter('test_filter');
        expect(filter!('hello', [], {}), equals('LOCAL: hello'));
        
        // Test that fallback to global works when local doesn't exist
        final globalFilter = env.getFilter('test_filter');
        expect(globalFilter, isNotNull);
        
        // Create new environment without local filter
        final env2 = Environment();
        final globalOnlyFilter = env2.getFilter('test_filter');
        expect(globalOnlyFilter!('hello', [], {}), equals('GLOBAL: hello'));
      });

      test('should verify local filter functionality without full rendering', () {
        final env = Environment();
        
        // Register a local filter
        env.registerLocalFilter('shout', (value, args, namedArgs) {
          return '${value.toString().toUpperCase()}!!!';
        });
        
        // Test the filter directly
        final filter = env.getFilter('shout');
        expect(filter, isNotNull);
        
        final result = filter!('hello world', [], {});
        expect(result, equals('HELLO WORLD!!!'));
      });

      test('should verify tag creator functions work', () {
        final env = Environment();
        
        // Register a local tag
        env.registerLocalTag('greet', (content, filters) => GreetTag(content, filters));
        
        // Test the tag creator
        final tagCreator = env.getTag('greet');
        expect(tagCreator, isNotNull);
        
        final tag = tagCreator!([], []);
        expect(tag, isA<GreetTag>());
      });

      test('should verify template rendering works with built-in tags', () async {
        // First test that template rendering works at all with built-in tags
        final template = Template.parse('{% assign x = "hello" %}{{ x }}');
        final result = await template.renderAsync();
        
        expect(result.trim(), equals('hello'));
      });

      test('should demonstrate actual template rendering with environment setup callback', () async {
        // Test the new Template API with environment setup callback
        final template = Template.parse(
          'Hello {{ name }}! {% custom_tag %} Result: {{ result | emphasize }}',
          data: {'name': 'World', 'result': 'success'},
          environmentSetup: (env) {
            // Register custom filters and tags for this template
            env.registerLocalFilter('emphasize', (value, args, namedArgs) => '***${value.toString().toUpperCase()}***');
            env.registerLocalTag('custom_tag', (content, filters) => DemoTag(content, filters));
          },
        );
        
        final result = await template.renderAsync();
        expect(result.trim(), equals('Hello World! [DEMO: ] Result: ***SUCCESS***'));
      });

      test('should demonstrate template with custom environment instance', () async {
        // Create a custom environment with pre-configured filters/tags
        final customEnv = Environment.withStrictMode(); // Strict mode for security
        customEnv.registerLocalFilter('safe', (value, args, namedArgs) => 'SAFE:$value');
        customEnv.registerLocalTag('secure_tag', (content, filters) => GreetTag(content, filters));
        
        // Use the custom environment in a template
        final template = Template.parse(
          '{{ message | safe }} {% secure_tag %}',
          data: {'message': 'test'},
          environment: customEnv,
        );
        
        final result = await template.renderAsync();
        expect(result.trim(), equals('SAFE:test Hello'));
      });

      test('should demonstrate environment isolation between templates', () async {
        // Template 1 with specific filters
        final template1 = Template.parse(
          '{{ value | format }}',
          data: {'value': 'test'},
          environmentSetup: (env) {
            env.registerLocalFilter('format', (value, args, namedArgs) => 'TEMPLATE1:$value');
          },
        );
        
        // Template 2 with different filters
        final template2 = Template.parse(
          '{{ value | format }}',
          data: {'value': 'test'},
          environmentSetup: (env) {
            env.registerLocalFilter('format', (value, args, namedArgs) => 'TEMPLATE2:$value');
          },
        );
        
        final result1 = await template1.renderAsync();
        final result2 = await template2.renderAsync();
        
        expect(result1.trim(), equals('TEMPLATE1:test'));
        expect(result2.trim(), equals('TEMPLATE2:test'));
      });

      test('should allow access to environment after template creation', () async {
        final template = Template.parse('{{ value | dynamic_filter }}', data: {'value': 'test'});
        
        // Register filter after template creation
        template.environment.registerLocalFilter('dynamic_filter', (value, args, namedArgs) => 'DYNAMIC:$value');
        
        final result = await template.renderAsync();
        expect(result.trim(), equals('DYNAMIC:test'));
      });

      test('should verify filter isolation between environments', () {
        final env1 = Environment();
        final env2 = Environment();
        
        // Register different filters in each environment
        env1.registerLocalFilter('format', (value, args, namedArgs) => 'ENV1: $value');
        env2.registerLocalFilter('format', (value, args, namedArgs) => 'ENV2: $value');
        
        // Test that filters work differently in each environment
        final filter1 = env1.getFilter('format');
        final filter2 = env2.getFilter('format');
        
        expect(filter1!('test', [], {}), equals('ENV1: test'));
        expect(filter2!('test', [], {}), equals('ENV2: test'));
      });

      test('should verify strict mode blocks global filters', () {
        final strictEnv = Environment.withStrictMode();
        
        // Register only local filter
        strictEnv.registerLocalFilter('safe', (value, args, namedArgs) => 'SAFE: $value');
        
        // Register a global filter
        FilterRegistry.register('dangerous', (value, args, namedArgs) => 'DANGER: $value');
        
        // Should have access to local filter
        expect(strictEnv.getFilter('safe'), isNotNull);
        
        // Should NOT have access to global filter in strict mode
        expect(strictEnv.getFilter('dangerous'), isNull);
      });
    });

    group('Environment Cloning', () {
      test('should clone local filters and tags with environment', () {
        final original = Environment();
        
        // Register local filters and tags
        original.registerLocalFilter('test_filter', (value, args, namedArgs) => 'filtered-$value');
        original.registerLocalTag('test_tag', (content, filters) => CustomTestTag(content, filters));
        
        // Clone the environment
        final cloned = original.clone();
        
        // Cloned environment should have the same local registrations
        expect(cloned.getFilter('test_filter'), isNotNull);
        expect(cloned.getTag('test_tag'), isNotNull);
        
        // But they should be independent - changes to one shouldn't affect the other
        cloned.registerLocalFilter('clone_only', (value, args, namedArgs) => value);
        
        expect(cloned.getFilter('clone_only'), isNotNull);
        expect(original.getFilter('clone_only'), isNull);
      });
    });

    group('Security and Sandboxing', () {
      test('should create secure environment with limited filters', () {
        final secureEnv = Environment();
        
        // Only register safe filters
        secureEnv.registerLocalFilter('escape', (value, args, namedArgs) => 'escaped-$value');
        secureEnv.registerLocalFilter('truncate', (value, args, namedArgs) => value.toString().substring(0, 5));
        
        // Register dangerous global filter
        FilterRegistry.register('dangerous_filter', (value, args, namedArgs) => 'DANGER');
        
        // Secure environment should have access to its safe filters
        expect(secureEnv.getFilter('escape'), isNotNull);
        expect(secureEnv.getFilter('truncate'), isNotNull);
        
        // But also to global filters (this might change based on implementation)
        expect(secureEnv.getFilter('dangerous_filter'), isNotNull);
      });

      test('should support strict mode that blocks global registry access', () {
        final strictEnv = Environment.withStrictMode(); // Create with strict mode enabled
        
        // Register local filter
        strictEnv.registerLocalFilter('safe_filter', (value, args, namedArgs) => 'safe-$value');
        
        // Register global filter
        FilterRegistry.register('global_filter', (value, args, namedArgs) => 'global');
        
        // Should have access to local
        expect(strictEnv.getFilter('safe_filter'), isNotNull);
        
        // Should NOT have access to global in strict mode
        expect(strictEnv.getFilter('global_filter'), isNull);
      });

      test('should create Environment with strict mode using named constructor', () {
        final strictEnv = Environment.withStrictMode();
        
        // Should be in strict mode
        expect(strictEnv.strictMode, isTrue);
        
        // Should be able to toggle strict mode off
        strictEnv.setStrictMode(false);
        expect(strictEnv.strictMode, isFalse);
        
        // Should be able to toggle it back on
        strictEnv.setStrictMode(true);
        expect(strictEnv.strictMode, isTrue);
      });
    });
  });
}

// Test helper classes
class CustomTestTag extends AbstractTag {
  CustomTestTag(super.content, super.filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    buffer.write('custom_test_tag_output');
  }

  @override
  FutureOr evaluateAsync(Evaluator evaluator, Buffer buffer) {
    return evaluate(evaluator, buffer);
  }
}

class GlobalTestTag extends AbstractTag {
  GlobalTestTag(super.content, super.filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    buffer.write('global_test_tag_output');
  }

  @override
  FutureOr evaluateAsync(Evaluator evaluator, Buffer buffer) {
    return evaluate(evaluator, buffer);
  }
}

class LocalTestTag extends AbstractTag {
  LocalTestTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    buffer.write('local_test_tag_output');
    return null;
  }
}

class GreetTag extends AbstractTag {
  GreetTag(super.content, super.filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    buffer.write('Hello');
  }

  @override
  FutureOr evaluateAsync(Evaluator evaluator, Buffer buffer) {
    return evaluate(evaluator, buffer);
  }
}

class DemoTag extends AbstractTag {
  DemoTag(super.content, super.filters);

  @override
  FutureOr evaluateAsync(Evaluator evaluator, Buffer buffer) {
    return evaluate(evaluator, buffer);
  }

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    final content = evaluateContent(evaluator);
    buffer.write('[DEMO: $content]');
  }
} 