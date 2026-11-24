import 'builtin_examples.dart';

const examples = <String, PlaygroundExample>{
  'basic': PlaygroundExample(
    entryFile: 'index.liquid',
    files: {
      'index.liquid': r'''{% assign title = "Hello, World!" %}
<h1>{{ title }}</h1>
<p>Today is {{ "now" | date: "%B %d, %Y" }}</p>

{% capture greeting %}Hello {{ "World" | upcase }}{% endcapture %}
<p>{{ greeting }}</p>

{% for item in items %}
  <div class="item">
    <span>{{ item.name }}</span>
    <span>{{ item.price | prepend: "$" }}</span>
  </div>
{% endfor %}''',
    },
    contextJson: r'''{
  "items": [
    { "name": "Widget", "price": 9.99 },
    { "name": "Gadget", "price": 24.99 },
    { "name": "Doohickey", "price": 4.99 }
  ]
}''',
  ),
  'layout': PlaygroundExample(
    entryFile: 'posts/hello-world.liquid',
    files: {
      'layouts/base.liquid': r'''<!DOCTYPE html>
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
</html>''',
      'layouts/post.liquid':
          r'''{% layout "layouts/base.liquid", title: post_title, year: year %}

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
{% endblock %}''',
      'posts/hello-world.liquid': r'''{% assign post_title = "Hello, World!" %}
{% layout "layouts/post.liquid", post_title: post_title, year: year %}

{%- block header -%}
  <h1>HEADER CONTENT</h1>
{%- endblock -%}

{% block footer %}
  {{ block.parent }}
  <div class="post-footer">
    <a href="/posts">Back to Posts</a>
  </div>
{% endblock %}''',
    },
    contextJson: r'''{
  "year": 2024,
  "post": {
    "title": "Hello, World!",
    "author": "John Doe",
    "date": "2024-02-09",
    "excerpt": "An introduction to our blog",
    "content": "Welcome to our new blog! This is our first post exploring layout inheritance, blocks, and parent content.",
    "tags": ["welcome", "introduction", "liquid"]
  }
}''',
  ),
  'dynamic-layout': PlaygroundExample(
    entryFile: 'pages/profile.liquid',
    files: {
      'layouts/full.liquid': r'''<!DOCTYPE html>
<html>
<head>
  <title>{{ title }}</title>
</head>
<body>
  <aside>Full navigation</aside>
  <main>{% block content %}{% endblock %}</main>
</body>
</html>''',
      'layouts/minimal.liquid': r'''<!DOCTYPE html>
<html>
<head>
  <title>{{ title }}</title>
</head>
<body>
  <main class="minimal">
    {% block content %}{% endblock %}
  </main>
</body>
</html>''',
      'pages/profile.liquid':
          r'''{% layout "layouts/{{ layout_type }}.liquid", title: user.name %}

{% block content %}
  <article>
    <h1>{{ user.name }}</h1>
    <p>{{ user.bio }}</p>
    <p>Selected layout: <strong>{{ layout_type }}</strong></p>
  </article>
{% endblock %}''',
    },
    contextJson: r'''{
  "layout_type": "full",
  "user": {
    "name": "Ada Lovelace",
    "bio": "Mathematician and early computing pioneer."
  }
}''',
  ),
  ...builtinExamples,
};
