# URL Filters

URL filters provide essential encoding, decoding, and URL manipulation capabilities for your Liquid templates.

## url_encode

Encodes a string for safe use in URLs by replacing special characters with percent-encoded values.

### Syntax
```liquid
{{ string | url_encode }}
```

### Examples
```liquid
{{ "hello world" | url_encode }}
<!-- Output: hello+world -->

{{ "user@example.com" | url_encode }}
<!-- Output: user%40example.com -->

{{ "hello world & friends" | url_encode }}
<!-- Output: hello+world+%26+friends -->

{{ "path/to/file.txt" | url_encode }}
<!-- Output: path%2Fto%2Ffile.txt -->
```

### Notes
- Spaces are encoded as `+` for query parameter compatibility
- Uses standard URL encoding (RFC 3986)
- Safe for query parameters and form data

---

## url_decode

Decodes a URL-encoded string back to its original form.

### Syntax
```liquid
{{ string | url_decode }}
```

### Examples
```liquid
{{ "hello+world" | url_decode }}
<!-- Output: hello world -->

{{ "user%40example.com" | url_decode }}
<!-- Output: user@example.com -->

{{ "hello+world+%26+friends" | url_decode }}
<!-- Output: hello world & friends -->

{{ "path%2Fto%2Ffile.txt" | url_decode }}
<!-- Output: path/to/file.txt -->
```

### Notes
- Converts `+` characters back to spaces
- Handles all standard percent-encoded characters
- Useful for processing query parameters

---

## cgi_escape

Escapes a string using CGI escape rules for form data and query parameters.

### Syntax
```liquid
{{ string | cgi_escape }}
```

### Examples
```liquid
{{ "hello world!" | cgi_escape }}
<!-- Output: hello+world%21 -->

{{ "user@example.com" | cgi_escape }}
<!-- Output: user%40example.com -->

{{ "data & more data" | cgi_escape }}
<!-- Output: data+%26+more+data -->

{{ "special chars: !'()*" | cgi_escape }}
<!-- Output: special+chars%3A+%21%27%28%29%2A -->
```

### Special Characters Escaped
- Space → `+`
- `!` → `%21`
- `'` → `%27`
- `(` → `%28`
- `)` → `%29`
- `*` → `%2A`

### Notes
- More aggressive escaping than `url_encode`
- Specifically designed for CGI form submissions
- Escapes additional characters for maximum compatibility

---

## uri_escape

Escapes a string for use in URI paths while preserving certain safe characters.

### Syntax
```liquid
{{ string | uri_escape }}
```

### Examples
```liquid
{{ "hello world[]" | uri_escape }}
<!-- Output: hello%20world[] -->

{{ "path/to/resource.json" | uri_escape }}
<!-- Output: path/to/resource.json -->

{{ "query with spaces" | uri_escape }}
<!-- Output: query%20with%20spaces -->

{{ "data[key]=value" | uri_escape }}
<!-- Output: data[key]=value -->
```

### Preserved Characters
- Square brackets: `[` and `]`
- Forward slashes: `/`
- Other URI-safe characters

### Notes
- Uses `Uri.encodeFull()` for path-appropriate encoding
- Preserves URI structure characters
- Ideal for building complete URIs

---

## slugify

Converts a string into a URL-friendly slug.

### Syntax
```liquid
{{ string | slugify }}
{{ string | slugify: mode }}
{{ string | slugify: mode, preserve_case }}
```

### Parameters
- **mode** (optional) - Slugify mode: `"default"`, `"raw"`, `"pretty"`, `"ascii"`, `"latin"`, `"none"`
- **preserve_case** (optional) - If `true`, preserves original case (default: `false`)

### Modes

#### default (default mode)
```liquid
{{ "Hello World!" | slugify }}
<!-- Output: hello-world -->

{{ "Special @#$ Characters" | slugify }}
<!-- Output: special-characters -->
```

#### raw
```liquid
{{ "Hello World!" | slugify: "raw" }}
<!-- Output: hello-world! -->

{{ "Keep @#$ Some!" | slugify: "raw" }}
<!-- Output: keep-@#$-some! -->
```

#### pretty
```liquid
{{ "Hello World & Friends!" | slugify: "pretty" }}
<!-- Output: hello-world-friends -->

{{ "Path/To/File.txt" | slugify: "pretty" }}
<!-- Output: path/to/file.txt -->
```

#### ascii
```liquid
{{ "Héllö Wörld!" | slugify: "ascii" }}
<!-- Output: hello-world -->

{{ "Résumé & Portfolio" | slugify: "ascii" }}
<!-- Output: resume-portfolio -->
```

#### latin
```liquid
{{ "Héllö Wörld!" | slugify: "latin" }}
<!-- Output: hello-world -->

{{ "Café & Naïve" | slugify: "latin" }}
<!-- Output: cafe-naive -->
```

#### none
```liquid
{{ "Hello World!" | slugify: "none" }}
<!-- Output: Hello World! -->
```

### Case Preservation
```liquid
{{ "Hello World!" | slugify: "default", true }}
<!-- Output: Hello-World -->

{{ "CamelCase Text" | slugify: "default", true }}
<!-- Output: CamelCase-Text -->
```

### Advanced Examples
```liquid
{% assign post_slug = post.title | slugify %}
<a href="/posts/{{ post_slug }}">{{ post.title }}</a>

{% assign category_slug = category.name | slugify: "pretty" %}
<a href="/category/{{ category_slug }}">{{ category.name }}</a>
```

## Usage Patterns

### URL Building
```liquid
{% assign search_query = user_input | url_encode %}
<a href="/search?q={{ search_query }}">Search for "{{ user_input }}"</a>
```

### Clean URLs for Content
```liquid
{% assign article_slug = article.title | slugify %}
<link rel="canonical" href="{{ site.url }}/articles/{{ article_slug }}">
```

### Form Data Processing
```liquid
<form action="/submit" method="post">
  <input type="hidden" name="return_url" value="{{ current_url | url_encode }}">
  <input type="hidden" name="data" value="{{ form_data | cgi_escape }}">
</form>
```

### API URL Construction
```liquid
{% assign api_params = params | map: "name" | join: "&" | url_encode %}
{% assign api_url = base_url | append: "?" | append: api_params %}
<script>fetch('{{ api_url }}');</script>
```

### Social Media Sharing
```liquid
{% assign share_url = page.url | url_encode %}
{% assign share_text = page.title | append: " - " | append: page.excerpt | url_encode %}

<a href="https://twitter.com/intent/tweet?url={{ share_url }}&text={{ share_text }}">
  Share on Twitter
</a>
```

### File Download Links
```liquid
{% for file in downloads %}
  {% assign file_path = file.path | uri_escape %}
  <a href="/download/{{ file_path }}" download="{{ file.name | slugify }}.{{ file.extension }}">
    {{ file.name }}
  </a>
{% endfor %}
```

## Advanced URL Manipulation

### Query Parameter Building
```liquid
{% assign params = "" %}
{% for filter in active_filters %}
  {% assign encoded_value = filter.value | url_encode %}
  {% assign param = filter.key | append: "=" | append: encoded_value %}
  {% if params == "" %}
    {% assign params = param %}
  {% else %}
    {% assign params = params | append: "&" | append: param %}
  {% endif %}
{% endfor %}

<a href="/search?{{ params }}">Apply Filters</a>
```

### Breadcrumb URLs
```liquid
{% assign breadcrumb_url = "" %}
{% for segment in page.path_segments %}
  {% assign segment_slug = segment | slugify %}
  {% assign breadcrumb_url = breadcrumb_url | append: "/" | append: segment_slug %}
  <a href="{{ breadcrumb_url }}">{{ segment }}</a>
  {% unless forloop.last %} > {% endunless %}
{% endfor %}
```

### Internationalization URLs
```liquid
{% for locale in site.available_locales %}
  {% assign locale_slug = locale.code | slugify %}
  {% assign current_path = page.path | uri_escape %}
  <a href="/{{ locale_slug }}/{{ current_path }}" hreflang="{{ locale.code }}">
    {{ locale.name }}
  </a>
{% endfor %}
```

### Search Engine Friendly URLs
```liquid
{% assign seo_title = product.title | slugify: "ascii" %}
{% assign seo_category = product.category | slugify: "ascii" %}
{% assign seo_brand = product.brand | slugify: "ascii" %}

<link rel="canonical" href="/{{ seo_category }}/{{ seo_brand }}/{{ seo_title }}-{{ product.id }}">
```

## Security Considerations

### Safe URL Construction
```liquid
<!-- SECURE: Always encode user input -->
{% assign safe_query = user_search | url_encode %}
<a href="/search?q={{ safe_query }}">Search</a>

<!-- DANGEROUS: Raw user input -->
<a href="/search?q={{ user_search }}">Search</a>
```

### Path Traversal Prevention
```liquid
{% assign safe_filename = user_filename | slugify: "ascii" %}
<a href="/files/{{ safe_filename }}">Download</a>
```

### XSS Prevention in URLs
```liquid
{% assign safe_redirect = redirect_url | url_encode %}
<form action="/login">
  <input type="hidden" name="redirect" value="{{ safe_redirect }}">
</form>
```

## Performance Tips

1. **Cache slugified content** - Store slugs for frequently accessed content
2. **Use appropriate encoding** - Choose the right filter for your use case
3. **Combine operations efficiently** - Chain filters for complex transformations

```liquid
{% assign cached_slug = article.title | slugify: "ascii" %}
{% assign article_url = "/articles/" | append: cached_slug %}

<!-- Reuse the cached values -->
<link rel="canonical" href="{{ article_url }}">
<meta property="og:url" content="{{ site.url }}{{ article_url }}">
```

## Error Handling

URL filters handle edge cases gracefully:

```liquid
{{ null | url_encode }}        <!-- Output: (empty) -->
{{ "" | slugify }}             <!-- Output: (empty) -->
{{ "text" | url_decode }}      <!-- Output: text -->
```

## Filter Combinations

### Complete URL Processing Pipeline
```liquid
{% assign clean_url = user_input 
  | strip 
  | slugify: "ascii" 
  | url_encode %}

<a href="/content/{{ clean_url }}">View Content</a>
```

### Multi-Language Slug Generation
```liquid
{% assign en_slug = title | slugify: "ascii" %}
{% assign de_slug = title_de | slugify: "latin" %}
{% assign jp_slug = title_jp | slugify: "unicode" %}
```

### SEO-Optimized URL Building
```liquid
{% assign seo_url = page.title 
  | append: " " 
  | append: page.category 
  | slugify: "ascii" 
  | truncate: 60, "" %}

<link rel="canonical" href="/{{ seo_url }}">
``` 