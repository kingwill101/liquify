# Utility Tags

Utility tags provide essential functionality for content handling, flow control, and template management.

## raw

Outputs content without processing any Liquid syntax within it.

### Syntax
```liquid
{% raw %}
  content with {{ liquid }} syntax that won't be processed
{% endraw %}
```

### Examples
```liquid
{% raw %}
  This {{ variable }} and {% tag %} won't be processed
{% endraw %}
<!-- Output: This {{ variable }} and {% tag %} won't be processed -->
```

---

## comment

Adds comments to templates that are not rendered in the output.

### Syntax
```liquid
{% comment %}
  This is a comment and won't appear in output
{% endcomment %}
```

### Examples
```liquid
{% comment %}
  TODO: Add error handling here
{% endcomment %}
<!-- Output: (nothing) -->
```

---

## break

Exits the current loop early.

### Syntax
```liquid
{% break %}
```

### Examples
```liquid
{% for item in (1..5) %}
  {% if item == 3 %}{% break %}{% endif %}
  {{ item }}
{% endfor %}
<!-- Output: 12 -->
```

---

## continue

Skips the rest of the current iteration and moves to the next.

### Syntax
```liquid
{% continue %}
```

### Examples
```liquid
{% for item in (1..5) %}
  {% if item == 3 %}{% continue %}{% endif %}
  {{ item }}
{% endfor %}
<!-- Output: 1245 -->
```

## Usage Patterns

### Conditional Content Processing
```liquid
{% for product in products %}
  {% unless product.available %}{% continue %}{% endunless %}
  
  {% if product.price > 1000 %}{% break %}{% endif %}
  
  <div class="product">{{ product.title }}</div>
{% endfor %}
```

### Template Documentation
```liquid
{% comment %}
  Product listing template
  Variables required: products (array)
  Optional: featured_products (array)
{% endcomment %}

{% raw %}
  Example usage: {{ product.title | truncate: 20 }}
{% endraw %}
``` 