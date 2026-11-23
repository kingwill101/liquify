final class PlaygroundExample {
  const PlaygroundExample({
    required this.files,
    required this.entryFile,
    required this.contextJson,
    this.expectedOutput = const [],
  });

  final Map<String, String> files;
  final String entryFile;
  final String contextJson;
  final List<String> expectedOutput;
}

const builtinExamples = <String, PlaygroundExample>{
  'control-flow': PlaygroundExample(
    entryFile: 'control-flow.liquid',
    files: {
      'control-flow.liquid': r'''<h1>Control flow</h1>

{% if user.member and user.points > 100 %}
  <p>Welcome back, {{ user.name }}. You have gold status.</p>
{% elsif user.member %}
  <p>Welcome back, {{ user.name }}.</p>
{% else %}
  <p>Create an account to collect points.</p>
{% endif %}

{% unless cart_empty %}
  <p>Your cart is ready for checkout.</p>
{% endunless %}

{% case plan %}
  {% when "starter" %}
    <strong>Starter plan: one project</strong>
  {% when "team", "business" %}
    <strong>Team plan: shared workspaces</strong>
  {% else %}
    <strong>Choose a plan</strong>
{% endcase %}

<h2>Available within budget</h2>
<ul>
{% for product in products %}
  {% unless product.available %}{% continue %}{% endunless %}
  {% if product.price > budget %}{% break %}{% endif %}
  <li>{{ product.name }} — ${{ product.price }}</li>
{% else %}
  <li>No products found.</li>
{% endfor %}
</ul>''',
    },
    contextJson: r'''{
  "user": { "name": "Maya", "member": true, "points": 180 },
  "cart_empty": false,
  "plan": "team",
  "budget": 50,
  "products": [
    { "name": "Sticker pack", "price": 4, "available": true },
    { "name": "T-shirt", "price": 24, "available": false },
    { "name": "Field guide", "price": 18, "available": true },
    { "name": "Collector box", "price": 80, "available": true },
    { "name": "Poster", "price": 12, "available": true }
  ]
}''',
    expectedOutput: [
      'gold status',
      'Team plan: shared workspaces',
      'Sticker pack',
      'Field guide',
    ],
  ),
  'iteration': PlaygroundExample(
    entryFile: 'iteration.liquid',
    files: {
      'iteration.liquid': r'''<h1>Iteration tools</h1>

<ol class="product-list">
{% for product in products limit: 4 %}
  <li class="{% cycle "odd", "even" %}">
    {{ forloop.index }}. {{ product.name }}
    {% if forloop.first %}<em>first</em>{% endif %}
    {% if forloop.last %}<em>last</em>{% endif %}
  </li>
{% else %}
  <li>The collection is empty.</li>
{% endfor %}
</ol>

<p>
  Reversed range:
  {% for number in (1..5) reversed %}
    {{ number }}{% unless forloop.last %}, {% endunless %}
  {% endfor %}
</p>

<table>
{% tablerow product in products cols: 3 %}
  <strong>{{ product.name }}</strong><br>
  <small>row {{ tablerowloop.row }}, column {{ tablerowloop.col }}</small>
{% endtablerow %}
</table>

<p class="rating">{% repeat 3 %}<span>★</span>{% endrepeat %}</p>''',
    },
    contextJson: r'''{
  "products": [
    { "name": "Notebook" },
    { "name": "Pencil" },
    { "name": "Ruler" },
    { "name": "Eraser" },
    { "name": "Marker" },
    { "name": "Folder" }
  ]
}''',
    expectedOutput: ['class="odd"', 'Reversed range:', 'row1', 'column 3', '★'],
  ),
  'variables-output': PlaygroundExample(
    entryFile: 'variables-output.liquid',
    files: {
      'variables-output.liquid': r'''{% doc %}
  Demonstrates assign, capture, counters, echo, liquid, raw, and comment.
{% enddoc %}

{% liquid
  assign customer_name = customer.name | upcase
  assign subtotal = item.price | times: item.quantity
  assign tax = subtotal | times: tax_rate
  assign total = subtotal | plus: tax | round: 2
%}

<h1>{% echo customer_name | prepend: "Order for " %}</h1>

{% capture order_summary %}
  {{ item.quantity }} × {{ item.name }} = ${{ subtotal }}
{% endcapture %}

<p>{{ order_summary | strip }}</p>
<p>Tax: ${{ tax | round: 2 }}</p>
<p>Total: ${{ total }}</p>

<ol>
  <li>Line {% increment line_number %}: validate order</li>
  <li>Line {% increment line_number %}: reserve stock</li>
  <li>Adjustment {% decrement stock_adjustment %}</li>
</ol>

{% comment %}This internal note never reaches the output.{% endcomment %}

<pre>{% raw %}{{ product.title }} is still Liquid source.
{% if product.available %}In stock{% endif %}{% endraw %}</pre>''',
    },
    contextJson: r'''{
  "customer": { "name": "Ari" },
  "item": { "name": "Template Handbook", "price": 24.5, "quantity": 2 },
  "tax_rate": 0.15
}''',
    expectedOutput: [
      'Order for ARI',
      '2 × Template Handbook = \$49',
      'Total: \$56.35',
      'Line 0',
      'Line 1',
      'Adjustment -1',
      '{{ product.title }} is still Liquid source.',
    ],
  ),
  'render-partials': PlaygroundExample(
    entryFile: 'catalog.liquid',
    files: {
      'catalog.liquid': r'''{% assign page_title = "Featured supplies" %}
{% render "partials/header.liquid", title: page_title, navigation: navigation %}

<main>
  <p>{{ products.size }} products rendered through an isolated partial.</p>
  <section class="product-grid">
    {% render "partials/product-card.liquid" for products as product %}
  </section>
</main>

{% render "partials/footer.liquid", year: year %}''',
      'partials/header.liquid': r'''<header>
  <h1>{{ title }}</h1>
  <nav>
  {% for item in navigation %}
    <a href="{{ item.url }}">{{ item.label }}</a>
  {% endfor %}
  </nav>
</header>''',
      'partials/product-card.liquid': r'''<article class="product-card">
  <h2>{{ product.name }}</h2>
  <p>${{ product.price }}</p>
  {% render "partials/stock-badge.liquid", available: product.available %}
</article>''',
      'partials/stock-badge.liquid': r'''{% if available %}
  <span class="in-stock">In stock</span>
{% else %}
  <span class="sold-out">Sold out</span>
{% endif %}''',
      'partials/footer.liquid': r'''<footer>
  <small>&copy; {{ year }} Liquify Supply Co.</small>
</footer>''',
    },
    contextJson: r'''{
  "year": 2026,
  "navigation": [
    { "label": "Catalog", "url": "/catalog" },
    { "label": "About", "url": "/about" }
  ],
  "products": [
    { "name": "Dot-grid notebook", "price": 12, "available": true },
    { "name": "Brass ruler", "price": 18, "available": false },
    { "name": "Archive pen", "price": 6, "available": true }
  ]
}''',
    expectedOutput: [
      '<h1>Featured supplies</h1>',
      'Dot-grid notebook',
      'Brass ruler',
      'Sold out',
      '2026 Liquify Supply Co.',
    ],
  ),
  'filters': PlaygroundExample(
    entryFile: 'filter-lab.liquid',
    files: {
      'filter-lab.liquid': r'''<h1>{{ page_title | capitalize }}</h1>

{% assign published = articles | where: "published", true %}
{% assign authors = published | map: "author" | uniq | sort %}

<p>{{ published.size }} published articles</p>
<p>Authors: {{ authors | join: ", " }}</p>

{% for article in published %}
  {% assign slug = article.title | slugify %}
  <article id="{{ slug }}">
    <h2>{{ article.title }}</h2>
    <p>{{ article.excerpt | strip_html | truncate: 58 }}</p>
    <a href="/search?q={{ article.title | url_encode }}">Find related</a>
  </article>
{% endfor %}

{% assign sale_price = product.price | times: product.discount | round: 2 %}
<p>Sale price: ${{ sale_price }}</p>
<p>Published: {{ published_at | date: "%B %-d, %Y" }}</p>
<p>Escaped input: {{ unsafe_html | escape }}</p>''',
    },
    contextJson: r'''{
  "page_title": "THE FILTER LAB",
  "published_at": "2026-07-14T10:30:00Z",
  "product": { "price": 79.95, "discount": 0.8 },
  "unsafe_html": "<strong>Hello & welcome</strong>",
  "articles": [
    {
      "title": "Building with Liquid & Dart",
      "author": "Maya",
      "published": true,
      "excerpt": "<p>Compose <strong>safe</strong>, reusable templates with a compact syntax.</p>"
    },
    {
      "title": "Layouts in practice",
      "author": "Ari",
      "published": true,
      "excerpt": "<p>Share structure while child templates replace named blocks.</p>"
    },
    {
      "title": "A private draft",
      "author": "Maya",
      "published": false,
      "excerpt": "<p>This article should not render.</p>"
    }
  ]
}''',
    expectedOutput: [
      'The filter lab',
      '2 published articles',
      'Authors: Ari, Maya',
      'building-with-liquid-dart',
      'Sale price: \$63.96',
      'July 14, 2026',
      '&lt;strong&gt;Hello &amp; welcome&lt;/strong&gt;',
    ],
  ),
};
