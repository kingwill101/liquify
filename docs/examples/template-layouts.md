# Template Layout Examples

This document demonstrates sophisticated template inheritance patterns using the Liquid layout system, including multi-level hierarchies, block overrides, and dynamic layout selection.

## Overview

The layout example showcases:
- Multi-level template inheritance
- Block definition and customization
- Layout variable passing
- Dynamic template composition
- Async template rendering

## Complete File Structure

The example creates a virtual file system with multiple templates:

```
layouts/
  base.liquid     - Root layout with common HTML structure
  post.liquid     - Blog post layout extending base
posts/
  hello-world.liquid - Specific blog post content
```

## Base Layout Template

### Code: `layouts/base.liquid`
```liquid
<!DOCTYPE html>
<html>
<head>
  <title>{% block title %}Default Title{% endblock %}</title>
  {% block meta %}{% endblock %}
  <link rel="stylesheet" href="/styles.css">
  {% block styles %}{% endblock %}
</head>
<body>
  <header>
    {% block header %}
      <nav>
        <a href="/">Home</a>
        <a href="/about">About</a>
        <a href="/contact">Contact</a>
      </nav>
    {% endblock %}
  </header>

  <main>
    {% block content %}
      Default content
    {% endblock %}
  </main>

  <footer>
    {% block footer %}
      <p>&copy; {{ year }} My Website</p>
    {% endblock %}
  </footer>

  <script src="/main.js"></script>
  {% block scripts %}{% endblock %}
</body>
</html>
```

### Features Demonstrated

#### Block Definitions
```liquid
{% block title %}Default Title{% endblock %}
{% block meta %}{% endblock %}
{% block styles %}{% endblock %}
```
- Defines customizable sections in the layout
- Provides default content where appropriate
- Creates extension points for child templates

#### Variable Integration
```liquid
<p>&copy; {{ year }} My Website</p>
```
- Accepts variables passed from child templates
- Enables dynamic content in layouts

## Post Layout Template

### Code: `layouts/post.liquid`
```liquid
{% layout "layouts/base.liquid", title: post_title, year: year %}

{% block meta %}
  <meta name="author" content="{{ post.author }}">
  <meta name="description" content="{{ post.excerpt }}">
{% endblock %}

{% block styles %}
  <link rel="stylesheet" href="/blog.css">
{% endblock %}

{% block content %}
  <article>
    <h1>{{ post_title }}</h1>
    <div class="metadata">
      By {{ post.author }} on {{ post.date | date: "%B %d, %Y" }}
    </div>
    <div class="content">
      {{ post.content }}
    </div>
    {% if post.tags.size > 0 %}
      <div class="tags">
        Tags:
        {% for tag in post.tags %}
          <span class="tag">{{ tag }}</span>
        {% endfor %}
      </div>
    {% endif %}
  </article>
{% endblock %}

{% block scripts %}
  <script src="/blog.js"></script>
{% endblock %}
```

### Features Demonstrated

#### Layout Inheritance
```liquid
{% layout "layouts/base.liquid", title: post_title, year: year %}
```
- Extends the base layout
- Passes variables to parent template
- Inherits all base layout structure

#### Block Overrides
```liquid
{% block content %}
  <article>
    <!-- Custom post content -->
  </article>
{% endblock %}
```
- Replaces default block content
- Provides specialized functionality
- Maintains layout structure

#### Conditional Logic
```liquid
{% if post.tags.size > 0 %}
  <div class="tags">
    {% for tag in post.tags %}
      <span class="tag">{{ tag }}</span>
    {% endfor %}
  </div>
{% endif %}
```
- Conditional content rendering
- Loop-based content generation
- Data-driven template logic

## Blog Post Content

### Code: `posts/hello-world.liquid`
```liquid
{% assign post_title = "Hello, World!" %}
{% layout "layouts/post.liquid", post_title: post_title, year: year %}

{%- block header -%}
<h1>HEADER CONTENT</h1>
{%- endblock -%}

{% block footer %}
  {{ block.parent }}
  <div class="post-footer">
    <a href="/posts">Back to Posts</a>
  </div>
{% endblock %}
```

### Features Demonstrated

#### Variable Assignment
```liquid
{% assign post_title = "Hello, World!" %}
```
- Creates template-scoped variables
- Enables dynamic variable passing

#### Layout Chain
```liquid
{% layout "layouts/post.liquid", post_title: post_title, year: year %}
```
- Three-level inheritance: content → post → base
- Variable propagation through chain

#### Block Content Extension
```liquid
{% block footer %}
  {{ block.parent }}
  <div class="post-footer">
    <a href="/posts">Back to Posts</a>
  </div>
{% endblock %}
```
- Uses `block.parent` to include parent block content
- Adds additional content to existing blocks
- Preserves base layout functionality

#### Whitespace Control
```liquid
{%- block header -%}
<h1>HEADER CONTENT</h1>
{%- endblock -%}
```
- Uses `{%-` and `-%}` for whitespace trimming
- Controls output formatting

## Main Example Code

```dart
import 'package:liquify/liquify.dart';

void main() async {
  // Create our file system with templates
  final fs = MapRoot({
    'layouts/base.liquid': '''[base template content]''',
    'layouts/post.liquid': '''[post template content]''',
    'posts/hello-world.liquid': '''[post content]'''
  });

  // Sample post data
  final context = {
    'year': 2024,
    'post': {
      'title': 'Hello, World!',
      'author': 'John Doe',
      'date': '2024-02-09',
      'excerpt': 'An introduction to our blog',
      'content': '''Welcome to our new blog! This is our first post...''',
      'tags': ['welcome', 'introduction', 'liquid'],
    }
  };

  print('\nRendering blog post with layout inheritance:');
  
  // Render the blog post
  final template = Template.fromFile('posts/hello-world.liquid', fs, data: context);
  print(await template.renderAsync());
}
```

## Expected Output

```html
<!DOCTYPE html>
<html>
<head>
  <title>Hello, World!</title>
  <meta name="author" content="John Doe">
  <meta name="description" content="An introduction to our blog">
  <link rel="stylesheet" href="/styles.css">
  <link rel="stylesheet" href="/blog.css">
</head>
<body>
  <header>
<h1>HEADER CONTENT</h1>
  </header>

  <main>
    <article>
      <h1>Hello, World!</h1>
      <div class="metadata">
        By John Doe on February 09, 2024
      </div>
      <div class="content">
        Welcome to our new blog! This is our first post exploring the features
        of the Liquid template engine. We'll be covering:

        - Template inheritance
        - Layout blocks
        - Custom filters
        - And much more!

        Stay tuned for more content coming soon!
      </div>
      <div class="tags">
        Tags:
        <span class="tag">welcome</span>
        <span class="tag">introduction</span>
        <span class="tag">liquid</span>
      </div>
    </article>
  </main>

  <footer>
    <p>&copy; 2024 My Website</p>
    <div class="post-footer">
      <a href="/posts">Back to Posts</a>
    </div>
  </footer>

  <script src="/main.js"></script>
  <script src="/blog.js"></script>
</body>
</html>
```

## Dynamic Layout Selection

The example also demonstrates dynamic layout selection:

```dart
final dynamicTemplate = Template.parse(
    '{% layout "layouts/{{ layout_type }}.liquid", title: "Dynamic Title" %}',
    data: {
      'layout_type': 'post',
    },
    root: fs);
print(await dynamicTemplate.renderAsync());
```

### Features Demonstrated

#### Dynamic Layout Names
```liquid
{% layout "layouts/{{ layout_type }}.liquid", title: "Dynamic Title" %}
```
- Uses variable interpolation in layout paths
- Enables runtime layout selection
- Supports conditional layout logic

## Advanced Patterns

### Context Data Structure
```dart
final context = {
  'year': 2024,
  'post': {
    'title': 'Hello, World!',
    'author': 'John Doe',
    'date': '2024-02-09',
    'excerpt': 'An introduction to our blog',
    'content': '''[full content]''',
    'tags': ['welcome', 'introduction', 'liquid'],
  }
};
```
- Nested data structures
- Rich metadata support
- Array and object composition

### Async Rendering
```dart
final template = Template.fromFile('posts/hello-world.liquid', fs, data: context);
print(await template.renderAsync());
```
- Asynchronous template processing
- File system integration
- Non-blocking rendering

### Variable Propagation
```
hello-world.liquid → post.liquid → base.liquid
     ↓                 ↓            ↓
post_title, year → title, year → year (footer)
```
- Variables flow through inheritance chain
- Each level can add or transform data
- Parent templates receive child variables

## Use Cases

### Blog Systems
- Post templates with consistent styling
- Category-specific layouts
- Tag-based content organization

### Documentation Sites
- Consistent navigation and structure
- Content-type specific formatting
- Cross-referencing and linking

### E-commerce Platforms
- Product page templates
- Category and listing layouts
- Checkout and user account pages

### Content Management
- Page templates with editable regions
- Multi-site theme support
- Responsive design patterns

## Performance Considerations

1. **Template Caching** - Parse layouts once, reuse for multiple content
2. **Inheritance Depth** - Limit inheritance levels for performance
3. **Variable Scope** - Minimize variable passing between levels
4. **Async Operations** - Use async rendering for complex layouts

```dart
// Efficient pattern
final baseTemplate = Template.fromFile('layouts/base.liquid', fs);
final postTemplate = Template.fromFile('layouts/post.liquid', fs);

// Reuse parsed templates
for (final post in posts) {
  final content = postTemplate.render(data: post);
  final final_output = baseTemplate.render(data: {...post, 'content': content});
}
```

## Related Examples

- [Basic Usage](basic-usage.md) - Template fundamentals
- [File System Integration](file-system.md) - Template loading patterns
- [Custom Tags](custom-tags.md) - Block tag development 