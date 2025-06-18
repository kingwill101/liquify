# Date Filters

Date filters provide powerful date and time formatting capabilities for your Liquid templates.

## date

Formats a date using a custom format string.

### Syntax
```liquid
{{ date_value | date: format_string }}
```

### Parameters
- **format_string** (required) - The format pattern to use

### Format Patterns

#### Common Patterns
- `%Y` - 4-digit year (2023)
- `%y` - 2-digit year (23)
- `%m` - Month as number (01-12)
- `%B` - Full month name (January)
- `%b` - Abbreviated month name (Jan)
- `%d` - Day of month (01-31)
- `%H` - Hour 24-hour format (00-23)
- `%I` - Hour 12-hour format (01-12)
- `%M` - Minutes (00-59)
- `%S` - Seconds (00-59)
- `%p` - AM/PM

### Examples
```liquid
{{ "2023-05-15" | date: "%B %d, %Y" }}
<!-- Output: May 15, 2023 -->

{{ "2023-05-15T14:30:00" | date: "%Y-%m-%d %H:%M" }}
<!-- Output: 2023-05-15 14:30 -->

{{ "2023-05-15" | date: "%A, %B %d" }}
<!-- Output: Monday, May 15 -->

{{ "now" | date: "%Y-%m-%d" }}
<!-- Output: Current date in YYYY-MM-DD format -->
```

### Input Types
- DateTime objects
- Date strings (ISO 8601, RFC 2822, etc.)
- Unix timestamps (numbers)
- Special string "now" for current time

---

## date_to_xmlschema

Converts a date to XML Schema (ISO 8601) format.

### Syntax
```liquid
{{ date_value | date_to_xmlschema }}
```

### Examples
```liquid
{{ "2023-05-15T14:30:00" | date_to_xmlschema }}
<!-- Output: 2023-05-15T14:30:00Z -->

{{ "May 15, 2023" | date_to_xmlschema }}
<!-- Output: 2023-05-15T00:00:00Z -->

{{ "now" | date_to_xmlschema }}
<!-- Output: Current time in ISO 8601 format -->
```

### Notes
- Outputs in UTC timezone
- Follows ISO 8601 standard
- Ideal for XML documents and APIs

---

## date_to_rfc822

Converts a date to RFC 822 format.

### Syntax
```liquid
{{ date_value | date_to_rfc822 }}
```

### Examples
```liquid
{{ "2023-05-15T14:30:00" | date_to_rfc822 }}
<!-- Output: Mon, 15 May 2023 14:30:00 +0000 -->

{{ "May 15, 2023" | date_to_rfc822 }}
<!-- Output: Mon, 15 May 2023 00:00:00 +0000 -->

{{ "now" | date_to_rfc822 }}
<!-- Output: Current time in RFC 822 format -->
```

### Notes
- Follows RFC 822 standard
- Includes timezone offset
- Commonly used in RSS feeds and email headers

---

## date_to_string

Formats a date to a short string format.

### Syntax
```liquid
{{ date_value | date_to_string }}
{{ date_value | date_to_string: "ordinal" }}
{{ date_value | date_to_string: "ordinal", "US" }}
```

### Parameters
- **style** (optional) - "ordinal" for ordinal dates
- **locale** (optional) - "US" for US-style formatting

### Examples
```liquid
{{ "2023-05-15" | date_to_string }}
<!-- Output: 15 May 2023 -->

{{ "2023-05-15" | date_to_string: "ordinal" }}
<!-- Output: 15th May 2023 -->

{{ "2023-05-15" | date_to_string: "ordinal", "US" }}
<!-- Output: May 15th, 2023 -->
```

### Notes
- Default format: DD MMM YYYY
- Ordinal style adds ordinal suffixes (st, nd, rd, th)
- US style changes month/day order

---

## date_to_long_string

Formats a date to a long string format with full month names.

### Syntax
```liquid
{{ date_value | date_to_long_string }}
{{ date_value | date_to_long_string: "ordinal" }}
{{ date_value | date_to_long_string: "ordinal", "US" }}
```

### Parameters
- **style** (optional) - "ordinal" for ordinal dates
- **locale** (optional) - "US" for US-style formatting

### Examples
```liquid
{{ "2023-05-15" | date_to_long_string }}
<!-- Output: 15 May 2023 -->

{{ "2023-05-15" | date_to_long_string: "ordinal" }}
<!-- Output: 15th May 2023 -->

{{ "2023-05-15" | date_to_long_string: "ordinal", "US" }}
<!-- Output: May 15th, 2023 -->
```

### Notes
- Uses full month names (January vs Jan)
- Same ordinal and US formatting options as `date_to_string`

## Usage Patterns

### Blog Post Formatting
```liquid
<time datetime="{{ post.date | date_to_xmlschema }}">
  {{ post.date | date: "%B %d, %Y" }}
</time>
```

### RSS Feed Generation
```liquid
<pubDate>{{ article.published_at | date_to_rfc822 }}</pubDate>
<lastBuildDate>{{ site.time | date_to_rfc822 }}</lastBuildDate>
```

### Human-Readable Dates
```liquid
<p>Published {{ post.date | date_to_long_string: "ordinal" }}</p>
<p>Last updated {{ post.updated_at | date: "%B %d, %Y at %I:%M %p" }}</p>
```

### Archive Organization
```liquid
{% assign posts_by_year = posts | group_by_exp: "post", "post.date | date: '%Y'" %}
{% for year_group in posts_by_year %}
  <h2>{{ year_group.name }}</h2>
  {% for post in year_group.items %}
    <article>
      <h3>{{ post.title }}</h3>
      <time>{{ post.date | date: "%B %d" }}</time>
    </article>
  {% endfor %}
{% endfor %}
```

### Event Scheduling
```liquid
{% assign upcoming_events = events | where_exp: "event", "event.date >= 'now'" %}
{% for event in upcoming_events %}
  <div class="event">
    <h3>{{ event.title }}</h3>
    <time datetime="{{ event.date | date_to_xmlschema }}">
      {{ event.date | date: "%A, %B %d at %I:%M %p" }}
    </time>
  </div>
{% endfor %}
```

### Relative Date Calculations
```liquid
{% assign days_until = event.date | date: "%j" | minus: "now" | date: "%j" %}
{% if days_until > 0 %}
  <p>{{ days_until }} days until event</p>
{% endif %}
```

## Advanced Formatting

### Custom Date Formats
```liquid
<!-- European format -->
{{ date | date: "%d/%m/%Y" }}

<!-- US format -->
{{ date | date: "%m/%d/%Y" }}

<!-- ISO format -->
{{ date | date: "%Y-%m-%d" }}

<!-- Full timestamp -->
{{ date | date: "%Y-%m-%d %H:%M:%S %Z" }}
```

### Conditional Date Display
```liquid
{% if post.updated_at != post.created_at %}
  <p>
    Published {{ post.created_at | date_to_string }}
    (Updated {{ post.updated_at | date_to_string }})
  </p>
{% else %}
  <p>Published {{ post.created_at | date_to_string }}</p>
{% endif %}
```

### Multi-Language Date Support
```liquid
{% case site.locale %}
  {% when 'en-US' %}
    {{ date | date: "%B %d, %Y" }}
  {% when 'en-GB' %}
    {{ date | date: "%d %B %Y" }}
  {% when 'de' %}
    {{ date | date: "%d. %B %Y" }}
  {% else %}
    {{ date | date_to_string }}
{% endcase %}
```

## Input Format Support

### Supported Input Formats
```liquid
<!-- ISO 8601 -->
{{ "2023-05-15T14:30:00Z" | date: "%Y-%m-%d" }}

<!-- RFC 2822 -->
{{ "Mon, 15 May 2023 14:30:00 +0000" | date: "%Y-%m-%d" }}

<!-- Unix timestamp -->
{{ 1684159800 | date: "%Y-%m-%d" }}

<!-- Natural language -->
{{ "May 15, 2023" | date: "%Y-%m-%d" }}

<!-- Current time -->
{{ "now" | date: "%Y-%m-%d %H:%M:%S" }}
```

## Error Handling

Date filters handle invalid input gracefully:

```liquid
{{ null | date: "%Y-%m-%d" }}        <!-- Output: (empty) -->
{{ "invalid" | date: "%Y-%m-%d" }}   <!-- Output: original input -->
{{ "" | date_to_xmlschema }}         <!-- Output: (empty) -->
```

## Performance Tips

1. **Cache date calculations** - Store formatted dates in variables for reuse
2. **Use appropriate formats** - Choose the simplest format that meets your needs
3. **Batch date operations** - Group date formatting operations together

```liquid
{% assign formatted_date = post.date | date: "%B %d, %Y" %}
{% assign iso_date = post.date | date_to_xmlschema %}

<time datetime="{{ iso_date }}">{{ formatted_date }}</time>
<meta property="article:published_time" content="{{ iso_date }}">
```

## Timezone Considerations

- Date filters typically output in UTC
- Input dates are parsed according to their timezone information
- Use appropriate timezone handling for user-specific displays
- Consider server timezone settings for "now" references

```liquid
<!-- Server time -->
{{ "now" | date: "%Y-%m-%d %H:%M:%S %Z" }}

<!-- UTC time -->
{{ "now" | date_to_xmlschema }}

<!-- User-friendly format -->
{{ "now" | date: "%B %d, %Y at %I:%M %p" }}
``` 