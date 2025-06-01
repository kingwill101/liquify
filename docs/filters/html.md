# HTML Filters

HTML filters provide essential tools for safely handling HTML content, escaping special characters, and manipulating HTML markup in your Liquid templates.

## escape

Escapes HTML special characters to prevent XSS attacks and ensure proper HTML rendering.

### Syntax
```liquid
{{ string | escape }}
```

### Characters Escaped
- `&` → `&amp;`
- `<` → `&lt;`
- `>` → `&gt;`
- `"` → `&#34;`
- `'` → `&#39;`

### Examples
```liquid
{{ "<p>Hello & welcome</p>" | escape }}
<!-- Output: &lt;p&gt;Hello &amp; welcome&lt;/p&gt; -->

{{ 'Say "Hello" to the world' | escape }}
<!-- Output: Say &#34;Hello&#34; to the world -->

{{ "Tom & Jerry" | escape }}
<!-- Output: Tom &amp; Jerry -->

{{ "<script>alert('xss')</script>" | escape }}
<!-- Output: &lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt; -->
```

### Notes
- Essential for displaying user-generated content safely
- Prevents XSS (Cross-Site Scripting) attacks
- Required when outputting dynamic content in HTML

### Aliases
- `xml_escape` - Alias for `escape`

---

## escape_once

Escapes HTML special characters but doesn't re-escape already escaped entities.

### Syntax
```liquid
{{ string | escape_once }}
```

### Examples
```liquid
{{ "&lt;p&gt;Hello &amp; welcome&lt;/p&gt;" | escape_once }}
<!-- Output: &lt;p&gt;Hello &amp; welcome&lt;/p&gt; -->

{{ "<p>Hello & welcome</p>" | escape_once }}
<!-- Output: &lt;p&gt;Hello &amp; welcome&lt;/p&gt; -->

{{ "Tom &amp; Jerry <script>" | escape_once }}
<!-- Output: Tom &amp; Jerry &lt;script&gt; -->
```

### Notes
- Safer than double-escaping content
- Useful when content might already be partially escaped
- Applies `unescape` then `escape` internally

---

## unescape

Converts HTML entities back to their original characters.

### Syntax
```liquid
{{ string | unescape }}
```

### Entities Unescaped
- `&amp;` → `&`
- `&lt;` → `<`
- `&gt;` → `>`
- `&#34;` → `"`
- `&#39;` → `'`

### Examples
```liquid
{{ "&lt;p&gt;Hello &amp; welcome&lt;/p&gt;" | unescape }}
<!-- Output: <p>Hello & welcome</p> -->

{{ "Say &#34;Hello&#34; to the world" | unescape }}
<!-- Output: Say "Hello" to the world -->

{{ "Tom &amp; Jerry" | unescape }}
<!-- Output: Tom & Jerry -->
```

### Notes
- Useful for processing stored HTML entities
- Reverse operation of `escape`
- Be cautious about security when unescaping user content

---

## strip_html

Removes all HTML tags from a string, leaving only the text content.

### Syntax
```liquid
{{ string | strip_html }}
```

### Examples
```liquid
{{ "<p>Hello <b>World</b></p>" | strip_html }}
<!-- Output: Hello World -->

{{ "<div class='content'>Text <span>content</span></div>" | strip_html }}
<!-- Output: Text content -->

{{ "Plain text" | strip_html }}
<!-- Output: Plain text -->

{{ "<script>alert('test')</script><p>Safe content</p>" | strip_html }}
<!-- Output: Safe content -->
```

### Advanced Removal
```liquid
{{ "<style>body{color:red;}</style><p>Content</p>" | strip_html }}
<!-- Output: Content -->

{{ "<!-- comment --><p>Visible text</p>" | strip_html }}
<!-- Output: Visible text -->
```

### Notes
- Removes ALL HTML tags including `<script>`, `<style>`, and comments
- Preserves text content and whitespace
- Useful for creating plain text excerpts
- Safe for removing potentially malicious HTML

---

## newline_to_br

Converts newline characters to HTML line break tags.

### Syntax
```liquid
{{ string | newline_to_br }}
```

### Examples
```liquid
{{ "Hello\nWorld" | newline_to_br }}
<!-- Output: Hello<br />\nWorld -->

{{ "Line 1\nLine 2\nLine 3" | newline_to_br }}
<!-- Output: Line 1<br />\nLine 2<br />\nLine 3 -->

{{ "Single line" | newline_to_br }}
<!-- Output: Single line -->
```

### Practical Usage
```liquid
{% assign user_message = "Thanks for your help!\nThis was very useful.\nBest regards." %}
<p>{{ user_message | newline_to_br }}</p>
<!-- Output:
<p>Thanks for your help!<br />
This was very useful.<br />
Best regards.</p>
-->
```

### Notes
- Converts both `\n` and `\r\n` line endings
- Preserves original newlines alongside `<br />` tags
- Useful for preserving line breaks in user-generated content

---

## strip_newlines

Removes all newline characters from a string.

### Syntax
```liquid
{{ string | strip_newlines }}
```

### Examples
```liquid
{{ "Hello\nWorld" | strip_newlines }}
<!-- Output: HelloWorld -->

{{ "Line 1\r\nLine 2\nLine 3" | strip_newlines }}
<!-- Output: Line 1Line 2Line 3 -->

{{ "   Multi\n  line\n  text   " | strip_newlines }}
<!-- Output:    Multi  line  text    -->
```

### Notes
- Removes both `\n` and `\r\n` line endings
- Does not affect other whitespace characters
- Useful for creating single-line text from multi-line input

## Usage Patterns

### Safe User Content Display
```liquid
<div class="user-comment">
  <h4>{{ comment.author | escape }}</h4>
  <p>{{ comment.content | escape | newline_to_br }}</p>
</div>
```

### Meta Tag Content
```liquid
<meta name="description" content="{{ page.description | strip_html | strip_newlines | escape }}">
<meta property="og:description" content="{{ page.excerpt | strip_html | truncate: 160 | escape }}">
```

### Email Content Processing
```liquid
{% assign email_content = user_input | strip_html | escape %}
<div class="email-preview">
  {{ email_content | newline_to_br }}
</div>
```

### Search Result Snippets
```liquid
{% for result in search_results %}
  <div class="search-result">
    <h3>{{ result.title | escape }}</h3>
    <p>{{ result.content | strip_html | truncate: 200 | escape }}</p>
  </div>
{% endfor %}
```

### Form Input Sanitization
```liquid
{% assign clean_input = form.message 
  | strip_html 
  | escape_once 
  | newline_to_br %}
<div class="message-preview">{{ clean_input }}</div>
```

### RSS Feed Generation
```liquid
<item>
  <title>{{ post.title | escape }}</title>
  <description>{{ post.content | strip_html | escape }}</description>
</item>
```

## Security Best Practices

### Always Escape User Input
```liquid
<!-- SECURE -->
<p>Hello {{ user.name | escape }}</p>

<!-- DANGEROUS -->
<p>Hello {{ user.name }}</p>
```

### Multi-Layer Protection
```liquid
{% assign safe_content = user_content 
  | strip_html 
  | escape 
  | truncate: 500 %}
<div class="user-content">{{ safe_content }}</div>
```

### HTML Attribute Safety
```liquid
<!-- SECURE -->
<img src="{{ image.url | escape }}" alt="{{ image.alt | escape }}">

<!-- SECURE with additional validation -->
<a href="{{ link.url | escape }}" title="{{ link.title | strip_html | escape }}">
```

### Comment System Security
```liquid
<div class="comment">
  <div class="author">{{ comment.author | escape }}</div>
  <div class="content">
    {{ comment.body | strip_html | escape | newline_to_br }}
  </div>
  <time>{{ comment.created_at | date_to_string }}</time>
</div>
```

## Advanced Examples

### Rich Text Processing
```liquid
{% assign processed_content = article.content %}

{% comment %}Strip dangerous tags but preserve formatting{% endcomment %}
{% assign processed_content = processed_content 
  | replace: '<script', '&lt;script'
  | replace: '<iframe', '&lt;iframe'
  | replace: 'javascript:', ''
  | escape_once %}

<article>{{ processed_content }}</article>
```

### Social Media Integration
```liquid
<meta property="og:title" content="{{ post.title | strip_html | escape }}">
<meta property="og:description" content="{{ post.excerpt | strip_html | strip_newlines | truncate: 160 | escape }}">
<meta name="twitter:card" content="summary">
<meta name="twitter:title" content="{{ post.title | strip_html | escape }}">
```

### Template Email Generation
```liquid
<html>
<head>
  <title>{{ email.subject | escape }}</title>
</head>
<body>
  <h1>{{ email.title | escape }}</h1>
  <div class="content">
    {{ email.body | strip_html | escape | newline_to_br }}
  </div>
</body>
</html>
```

## Performance Considerations

1. **Apply filters in optimal order** - Strip HTML before escaping for better performance
2. **Cache processed content** - Store sanitized content in variables for reuse
3. **Combine operations** - Use `escape_once` instead of `unescape` + `escape`

```liquid
{% assign clean_content = raw_content | strip_html | escape %}
{% assign excerpt = clean_content | truncate: 200 %}

<!-- Reuse processed content -->
<meta name="description" content="{{ excerpt }}">
<div class="preview">{{ excerpt }}</div>
```

## Error Handling

HTML filters handle edge cases gracefully:

```liquid
{{ null | escape }}           <!-- Output: (empty) -->
{{ "" | strip_html }}         <!-- Output: (empty) -->
{{ "text" | newline_to_br }}  <!-- Output: text -->
```

## Filter Combinations

### Common Combinations
```liquid
<!-- Safe user content with preserved formatting -->
{{ user_input | strip_html | escape | newline_to_br }}

<!-- Clean meta content -->
{{ content | strip_html | strip_newlines | escape | truncate: 160 }}

<!-- Preserve some HTML but escape dangerous content -->
{{ content | escape_once | strip_newlines }}
``` 