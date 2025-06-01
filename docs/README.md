# Liquid Grammar Documentation

A comprehensive Dart implementation of the Liquid template language with support for filters, tags, and advanced templating features.

## Table of Contents

### 📖 [Tags Documentation](tags/)
- **[Control Flow](tags/control-flow.md)** - `if`, `unless`, `case`, conditional logic
- **[Iteration](tags/iteration.md)** - `for`, `tablerow`, `cycle`, `repeat` 
- **[Variables](tags/variables.md)** - `assign`, `capture`, `increment`, `decrement`
- **[Layout & Rendering](tags/layout.md)** - `layout`, `block`, `super`, `render`
- **[Output](tags/output.md)** - `echo`, `liquid`
- **[Utility](tags/utility.md)** - `raw`, `comment`, `break`, `continue`

### 🔧 [Filters Documentation](filters/)
- **[Array Filters](filters/array.md)** - Array manipulation and processing
- **[String Filters](filters/string.md)** - String transformation and formatting
- **[Math Filters](filters/math.md)** - Mathematical operations
- **[Date Filters](filters/date.md)** - Date formatting and manipulation
- **[HTML Filters](filters/html.md)** - HTML encoding and processing
- **[URL Filters](filters/url.md)** - URL encoding and manipulation
- **[Misc Filters](filters/misc.md)** - Utility filters (json, parse_json, etc.)

### 📚 [Examples & Guides](examples/)
- **[Basic Usage](examples/basic-usage.md)** - Template fundamentals and getting started
- **[Template Layouts](examples/template-layouts.md)** - Layout inheritance and composition
- **[Custom Tags](examples/custom-tags.md)** - Creating advanced custom tags
- **[Drop Objects](examples/drop-objects.md)** - Custom object model integration
- **[File System Integration](examples/file-system.md)** - Template loading and organization

## Quick Start

### Basic Variable Output
```liquid
{{ name }}
{{ user.email }}
{{ products[0].title }}
```

### Basic Control Flow
```liquid
{% if user.logged_in %}
  Welcome back, {{ user.name }}!
{% else %}
  Please log in.
{% endif %}
```

### Basic Iteration
```liquid
{% for product in products %}
  <h3>{{ product.title }}</h3>
  <p>{{ product.description }}</p>
{% endfor %}
```

### Filters
```liquid
{{ "hello world" | capitalize }}
{{ products | size }}
{{ product.created_at | date: "%B %d, %Y" }}
```

## Features

- ✅ **Complete Liquid compatibility** - Full support for standard Liquid syntax
- ✅ **Async support** - Both synchronous and asynchronous evaluation
- ✅ **Comprehensive filters** - 70+ built-in filters across 7 categories
- ✅ **Rich tag library** - 20+ tags for control flow, iteration, and layout
- ✅ **Error handling** - Detailed error messages and exception handling
- ✅ **Extensible** - Easy to add custom filters and tags
- ✅ **Well-tested** - Extensive test coverage with real-world examples

## Contributing

This documentation is automatically generated from source code and tests. To update:

1. Modify the source code or tests
2. Run the documentation generation script
3. Review and commit the changes

For more information, see the [Contributing Guide](../CONTRIBUTING.md). 