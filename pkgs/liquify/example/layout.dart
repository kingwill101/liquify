import 'package:liquify/liquify.dart';

void main() async {
  // Create our file system with templates
  final fs = MapRoot({
    // Base layout with common structure
    'layouts/base.liquid': '''
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
</html>''',

    // Blog post layout that extends base
    'layouts/post.liquid': '''
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
{% endblock %}''',

    // Actual blog post using post layout
    'posts/hello-world.liquid': '''
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
{% endblock %}'''
  });

  // Sample post data
  final context = {
    'year': 2024,
    'post': {
      'title': 'Hello, World!',
      'author': 'John Doe',
      'date': '2024-02-09',
      'excerpt': 'An introduction to our blog',
      'content': '''
Welcome to our new blog! This is our first post exploring the features
of the Liquid template engine. We'll be covering:

- Template inheritance
- Layout blocks
- Custom filters
- And much more!

Stay tuned for more content coming soon!''',
      'tags': ['welcome', 'introduction', 'liquid'],
    }
  };

  print('\nRendering blog post with layout inheritance:');
  print('----------------------------------------\n');

  // Render the blog post
  final template =
      Template.fromFile('posts/hello-world.liquid', fs, data: context);
  print(await template.renderAsync());

  // Demonstrate dynamic layout names
  print('\nDemo of dynamic layout names:');
  print('----------------------------------------\n');

  final dynamicTemplate = Template.parse(
      '{% layout "layouts/{{ layout_type }}.liquid", title: "Dynamic Title" %}',
      data: {
        'layout_type': 'post',
      },
      root: fs);
  print(await dynamicTemplate.renderAsync());
}
