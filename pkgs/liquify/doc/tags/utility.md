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
Compare literal Liquid source with the value produced by evaluating it.

```liquid-live
Literal: {% raw %}{{ city }}{% endraw %}
Rendered: {{ city }}
```

```json-live
{
  "city": "Nairobi"
}
```

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
Keep an internal note out of the output.

```liquid-live
{{ notice }}{% comment %}Internal draft: {{ reviewer }}{% endcomment %}
```

```json-live
{
  "notice": "Schedule updated.",
  "reviewer": "Lea"
}
```

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
Stop when the loop reaches the end marker.

```liquid-live
{%- for item in items -%}
  {%- if item == "STOP" -%}{%- break -%}{%- endif -%}
  [{{ item }}]
{%- endfor -%}
```

```json-live
{
  "items": [
    "Oak",
    "Elm",
    "STOP",
    "Ash"
  ]
}
```

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
Skip unavailable products and keep going.

```liquid-live
{%- for item in items -%}
  {%- unless item.available -%}{%- continue -%}{%- endunless -%}
  [{{ item.name }}]
{%- endfor -%}
```

```json-live
{
  "items": [
    {
      "name": "Tea",
      "available": true
    },
    {
      "name": "Coffee",
      "available": false
    },
    {
      "name": "Cocoa",
      "available": true
    }
  ]
}
```

```liquid
{% for item in (1..5) %}
  {% if item == 3 %}{% continue %}{% endif %}
  {{ item }}
{% endfor %}
<!-- Output: 1245 -->
```

## doc

Document a template for its author. The documentation block does not render.

```liquid-live
{% doc %}
  Displays the current workshop title.
{% enddoc -%}
Workshop: {{ title }}
```

```json-live
{
  "title": "Paper marbling"
}
```

---

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