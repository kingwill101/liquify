# Layout & Rendering Tags

Layout tags handle template composition, inheritance, and partial rendering for building complex template structures.

## layout

Defines the base layout template that child templates extend.

### Syntax
```liquid
{% layout "layout_name" %}
```

### Examples
Load a base layout and pass it a page title. Edit the base in its own tab.

```liquid-live
{% layout "base", title: page_title %}
{% block content %}Welcome to {{ page_title }}.{% endblock %}
```

```json-live
{
  "page_title": "the workshop"
}
```

```files-live
{
  "base.liquid": "<!doctype html>\n<title>{{ title }}</title>\n<main>{% block content %}Default content{% endblock %}</main>"
}
```

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
Override the base layout’s content block from the main template.

```liquid-live
{% layout "base" %}
{% block content %}<p>{{ announcement }}</p>{% endblock %}
```

```json-live
{
  "announcement": "Doors open at nine."
}
```

```files-live
{
  "base.liquid": "<main>{% block content %}<p>Nothing scheduled.</p>{% endblock %}</main>"
}
```

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
  {{ super() }}
  additional content
{% endblock %}
```

### Examples
The workshop layout extends the base. Open the `workshop.liquid` tab to edit its call to `super()`.

```liquid-live
{% layout "workshop" %}
```

```json-live
{
  "note": "Lunch is provided."
}
```

```files-live
{
  "base.liquid": "<main>{% block content %}<p>Bring a notebook.</p>{% endblock %}</main>",
  "workshop.liquid": "{% layout \"base\" %}\n{% block content %}{{ super() }}<p>{{ note }}</p>{% endblock %}"
}
```

```liquid
{% block head %}
  {{ super() }}
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
Pass a product explicitly to an isolated partial.

```liquid-live
{% render "card", item: product %}
```

```json-live
{
  "product": {
    "name": "Field journal",
    "price": 12
  }
}
```

```files-live
{
  "card.liquid": "<strong>{{ item.name }}</strong> · {{ item.price }}"
}
```

```liquid
{% render "product_card", product: product %}
{% render "header" %}
```

## include

Render a partial that reads a variable from the surrounding template.

```liquid-live
{% assign label = "Today" -%}
{% include "notice" %}
```

```json-live
{
  "message": "Stocktake at noon"
}
```

```files-live
{
  "notice.liquid": "{{ label }}: {{ message }}"
}
```

---

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
  {{ super() }}
  <meta name="description" content="Product description">
{% endblock %}

{% block content %}
  <h1>{{ product.title }}</h1>
  {% render "product_details", product: product %}
{% endblock %}
``` 