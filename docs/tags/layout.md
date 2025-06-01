# Layout & Rendering Tags

Layout tags handle template composition, inheritance, and partial rendering for building complex template structures.

## layout

Defines the base layout template that child templates extend.

### Syntax
```liquid
{% layout "layout_name" %}
```

### Examples
```liquid
{% layout "base" %}

<!-- Content of this template will be inserted into the layout -->
<h1>Page Title</h1>
<p>Page content</p>
```

---

## block

Defines a replaceable content block within a layout template.

### Syntax
```liquid
{% block block_name %}
  default content
{% endblock %}
```

### Examples
```liquid
<!-- In layout template -->
<!DOCTYPE html>
<html>
<head>
  {% block head %}
    <title>Default Title</title>
  {% endblock %}
</head>
<body>
  {% block content %}
    <p>Default content</p>
  {% endblock %}
</body>
</html>
```

---

## super

Calls the parent block's content when overriding a block.

### Syntax
```liquid
{% block block_name %}
  {% super %}
  additional content
{% endblock %}
```

### Examples
```liquid
{% block head %}
  {% super %}
  <meta name="description" content="Page description">
{% endblock %}
```

---

## render

Includes and renders another template file.

### Syntax
```liquid
{% render "template_name" %}
{% render "template_name", variable: value %}
```

### Examples
```liquid
{% render "product_card", product: product %}
{% render "header" %}
```

## Layout Inheritance Patterns

### Base Layout
```liquid
<!-- layouts/base.liquid -->
<!DOCTYPE html>
<html>
<head>
  <title>{% block title %}Default Title{% endblock %}</title>
  {% block head %}{% endblock %}
</head>
<body>
  <header>{% render "header" %}</header>
  <main>{% block content %}{% endblock %}</main>
  <footer>{% render "footer" %}</footer>
</body>
</html>
```

### Child Template
```liquid
{% layout "base" %}

{% block title %}Product Page{% endblock %}

{% block head %}
  {% super %}
  <meta name="description" content="Product description">
{% endblock %}

{% block content %}
  <h1>{{ product.title }}</h1>
  {% render "product_details", product: product %}
{% endblock %}
``` 