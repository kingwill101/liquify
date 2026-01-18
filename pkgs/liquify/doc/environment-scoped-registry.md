# Environment-Scoped Registry

The Environment-Scoped Registry is a powerful feature in Liquify that allows you to create isolated template execution contexts with custom filters and tags. This feature is essential for building secure, multi-tenant applications and implementing plugin systems.

## Overview

Traditional template engines typically use global registries for filters and tags, which can lead to:
- Security vulnerabilities in multi-tenant applications
- Naming conflicts between different parts of an application
- Difficulty in creating isolated execution contexts
- Challenges in implementing plugin systems

Liquify's Environment-Scoped Registry solves these problems by allowing you to:
- Register filters and tags that are only available to specific environments
- Create secure sandboxes that block access to global registries
- Isolate different parts of your application with independent template capabilities
- Implement inheritance patterns through environment cloning

## Core Concepts

### Environment
An `Environment` represents an execution context for template rendering. It manages:
- Variable scopes and data
- Local filter registrations
- Local tag registrations
- Strict mode settings

### Local vs Global Registration
- **Global Registration**: Available to all environments (unless in strict mode)
- **Local Registration**: Only available to the specific environment instance

### Priority System
1. **Local filters/tags** (highest priority)
2. **Global filters/tags** (fallback)
3. **Strict mode** blocks global access entirely

## Basic Usage

### Environment Setup Callback

The simplest way to use environment-scoped registry is through the `environmentSetup` callback:

```dart
final template = Template.parse(
  'Hello {{ name | emphasize }}! {% greeting %}',
  data: {'name': 'World'},
  environmentSetup: (env) {
    // Register filters and tags for this template only
    env.registerLocalFilter('emphasize', (value, args, namedArgs) => 
      '***${value.toString().toUpperCase()}***');
    env.registerLocalTag('greeting', (content, filters) => 
      GreetingTag(content, filters));
  },
);

print(await template.renderAsync());
// Output: Hello ***WORLD***! Welcome!
```

### Custom Environment Instance

For more control, you can create and configure an environment explicitly:

```dart
final customEnv = Environment();
customEnv.registerLocalFilter('format', (value, args, namedArgs) => 
  'FORMATTED:$value');
customEnv.registerLocalTag('custom', (content, filters) => 
  CustomTag(content, filters));

final template = Template.parse(
  '{{ message | format }} {% custom %}',
  data: {'message': 'test'},
  environment: customEnv,
);

print(await template.renderAsync());
// Output: FORMATTED:test [CUSTOM_OUTPUT]
```

## Security Features

### Strict Mode

Strict mode creates a secure sandbox by blocking access to global registries:

```dart
final secureEnv = Environment.withStrictMode();

// Only register safe, vetted filters
secureEnv.registerLocalFilter('sanitize', (value, args, namedArgs) {
  return value.toString()
    .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
    .replaceAll(RegExp(r'[<>"\']'), ''); // Remove dangerous chars
});

secureEnv.registerLocalFilter('truncate', (value, args, namedArgs) {
  final maxLen = args.isNotEmpty ? args[0] as int : 50;
  final str = value.toString();
  return str.length > maxLen ? '${str.substring(0, maxLen)}...' : str;
});

// Global filters are not accessible in strict mode
FilterRegistry.register('dangerous', (value, args, namedArgs) => 
  'DANGEROUS:$value');

print(secureEnv.getFilter('dangerous')); // null
print(secureEnv.getFilter('sanitize')); // Function
```

### Sandboxing User Content

Perfect for scenarios where you need to render user-provided templates safely:

```dart
String renderUserTemplate(String userTemplate, Map<String, dynamic> userData) {
  final secureEnv = Environment.withStrictMode();
  
  // Only provide safe filters
  secureEnv.registerLocalFilter('escape', (value, args, namedArgs) => 
    HtmlEscape().convert(value.toString()));
  secureEnv.registerLocalFilter('length', (value, args, namedArgs) => 
    value.toString().length);
  secureEnv.registerLocalFilter('upper', (value, args, namedArgs) => 
    value.toString().toUpperCase());
  
  final template = Template.parse(
    userTemplate,
    data: userData,
    environment: secureEnv,
  );
  
  return template.render();
}

// Safe to use with untrusted templates
final result = renderUserTemplate(
  'Hello {{ name | escape | upper }}!',
  {'name': '<script>alert("xss")</script>John'}
);
// Output: Hello &LT;SCRIPT&GT;ALERT(&QUOT;XSS&QUOT;)&LT;/SCRIPT&GT;JOHN!
```

## Advanced Patterns

### Environment Inheritance

Create hierarchical environments with shared base functionality:

```dart
// Base environment with common filters
final baseEnv = Environment();
baseEnv.registerLocalFilter('currency', (value, args, namedArgs) {
  final amount = double.parse(value.toString());
  return '\$${amount.toStringAsFixed(2)}';
});
baseEnv.registerLocalFilter('date', (value, args, namedArgs) {
  final date = DateTime.parse(value.toString());
  return '${date.day}/${date.month}/${date.year}';
});

// Specialized environment for e-commerce
final ecommerceEnv = baseEnv.clone();
ecommerceEnv.registerLocalFilter('discount', (value, args, namedArgs) {
  final price = double.parse(value.toString());
  final discountPercent = args.isNotEmpty ? args[0] as double : 10.0;
  return price * (1 - discountPercent / 100);
});

// Specialized environment for reporting
final reportingEnv = baseEnv.clone();
reportingEnv.registerLocalFilter('percentage', (value, args, namedArgs) {
  final decimal = double.parse(value.toString());
  return '${(decimal * 100).toStringAsFixed(1)}%';
});
```
