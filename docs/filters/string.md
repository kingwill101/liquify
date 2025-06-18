# String Filters

String filters provide comprehensive text manipulation and formatting capabilities for your Liquid templates.

## append

Appends a string to the end of another string.

### Syntax
```liquid
{{ string | append: suffix }}
```

### Parameters
- **suffix** (required) - The string to append

### Examples
```liquid
{{ "Hello" | append: " World" }}
<!-- Output: Hello World -->

{{ "" | append: "Test" }}
<!-- Output: Test -->

{{ "file" | append: ".txt" }}
<!-- Output: file.txt -->
```

---

## prepend

Prepends a string to the beginning of another string.

### Syntax
```liquid
{{ string | prepend: prefix }}
```

### Parameters
- **prefix** (required) - The string to prepend

### Examples
```liquid
{{ "World" | prepend: "Hello " }}
<!-- Output: Hello World -->

{{ "README" | prepend: "docs/" }}
<!-- Output: docs/README -->
```

---

## upcase

Converts a string to uppercase.

### Syntax
```liquid
{{ string | upcase }}
```

### Examples
```liquid
{{ "hello" | upcase }}
<!-- Output: HELLO -->

{{ "HeLLo" | upcase }}
<!-- Output: HELLO -->
```

### Aliases
- `upper` - Alias for `upcase`

---

## downcase

Converts a string to lowercase.

### Syntax
```liquid
{{ string | downcase }}
```

### Examples
```liquid
{{ "HELLO" | downcase }}
<!-- Output: hello -->

{{ "HeLLo" | downcase }}
<!-- Output: hello -->
```

### Aliases
- `lower` - Alias for `downcase`

---

## capitalize

Capitalizes the first letter of a string and converts the rest to lowercase.

### Syntax
```liquid
{{ string | capitalize }}
```

### Examples
```liquid
{{ "hello" | capitalize }}
<!-- Output: Hello -->

{{ "HELLO WORLD" | capitalize }}
<!-- Output: Hello world -->

{{ "hELLO" | capitalize }}
<!-- Output: Hello -->
```

---

## strip

Removes leading and trailing whitespace from a string.

### Syntax
```liquid
{{ string | strip }}
{{ string | strip: characters }}
```

### Parameters
- **characters** (optional) - Specific characters to remove

### Examples

#### Remove Whitespace
```liquid
{{ "  Hello  " | strip }}
<!-- Output: Hello -->
```

#### Remove Specific Characters
```liquid
{{ "xxHelloxx" | strip: "x" }}
<!-- Output: Hello -->

{{ "...Hello..." | strip: "." }}
<!-- Output: Hello -->
```

---

## lstrip

Removes leading characters from a string.

### Syntax
```liquid
{{ string | lstrip }}
{{ string | lstrip: characters }}
```

### Parameters
- **characters** (optional) - Specific characters to remove

### Examples
```liquid
{{ "  Hello  " | lstrip }}
<!-- Output: Hello   -->

{{ "xxHello" | lstrip: "x" }}
<!-- Output: Hello -->
```

---

## rstrip

Removes trailing characters from a string.

### Syntax
```liquid
{{ string | rstrip }}
{{ string | rstrip: characters }}
```

### Parameters
- **characters** (optional) - Specific characters to remove

### Examples
```liquid
{{ "  Hello  " | rstrip }}
<!-- Output:   Hello -->

{{ "Helloxx" | rstrip: "x" }}
<!-- Output: Hello -->
```

---

## replace

Replaces all occurrences of a substring with another string.

### Syntax
```liquid
{{ string | replace: search, replacement }}
```

### Parameters
- **search** (required) - The substring to find
- **replacement** (required) - The replacement string

### Examples
```liquid
{{ "Hello World" | replace: "o", "a" }}
<!-- Output: Hella Warld -->

{{ "Hello Hello" | replace: "Hello", "Hi" }}
<!-- Output: Hi Hi -->

{{ "one-two-three" | replace: "-", " " }}
<!-- Output: one two three -->
```

---

## replace_first

Replaces the first occurrence of a substring.

### Syntax
```liquid
{{ string | replace_first: search, replacement }}
```

### Parameters
- **search** (required) - The substring to find
- **replacement** (required) - The replacement string

### Examples
```liquid
{{ "Hello Hello" | replace_first: "Hello", "Hi" }}
<!-- Output: Hi Hello -->

{{ "Hello World" | replace_first: "o", "a" }}
<!-- Output: Hella World -->
```

---

## replace_last

Replaces the last occurrence of a substring.

### Syntax
```liquid
{{ string | replace_last: search, replacement }}
```

### Parameters
- **search** (required) - The substring to find
- **replacement** (required) - The replacement string

### Examples
```liquid
{{ "Hello Hello" | replace_last: "Hello", "Hi" }}
<!-- Output: Hello Hi -->

{{ "Hello World" | replace_last: "o", "a" }}
<!-- Output: Hello Warld -->
```

---

## remove

Removes all occurrences of a substring.

### Syntax
```liquid
{{ string | remove: substring }}
```

### Parameters
- **substring** (required) - The substring to remove

### Examples
```liquid
{{ "Hello World" | remove: "o" }}
<!-- Output: Hell Wrld -->

{{ "Hello World" | remove: "l" }}
<!-- Output: Heo Word -->

{{ "a-b-c-d" | remove: "-" }}
<!-- Output: abcd -->
```

---

## remove_first

Removes the first occurrence of a substring.

### Syntax
```liquid
{{ string | remove_first: substring }}
```

### Parameters
- **substring** (required) - The substring to remove

### Examples
```liquid
{{ "Hello Hello" | remove_first: "Hello" }}
<!-- Output:  Hello -->

{{ "Hello World" | remove_first: "o" }}
<!-- Output: Hell World -->
```

---

## remove_last

Removes the last occurrence of a substring.

### Syntax
```liquid
{{ string | remove_last: substring }}
```

### Parameters
- **substring** (required) - The substring to remove

### Examples
```liquid
{{ "Hello Hello" | remove_last: "Hello" }}
<!-- Output: Hello  -->

{{ "Hello World" | remove_last: "o" }}
<!-- Output: Hello Wrld -->
```

---

## split

Splits a string into an array of substrings.

### Syntax
```liquid
{{ string | split: delimiter }}
```

### Parameters
- **delimiter** (required) - The delimiter to split on

### Examples
```liquid
{{ "Hello World" | split: " " }}
<!-- Output: ["Hello", "World"] -->

{{ "a,b,c" | split: "," }}
<!-- Output: ["a", "b", "c"] -->

{{ "one-two-three" | split: "-" }}
<!-- Output: ["one", "two", "three"] -->

{% assign words = "apple,banana,orange" | split: "," %}
{% for word in words %}{{ word }}{% endfor %}
<!-- Output: applebanana orange -->
```

### Notes
- Empty trailing elements are automatically removed
- Returns an array that can be used with array filters

---

## truncate

Limits a string to a specified length and adds an ellipsis.

### Syntax
```liquid
{{ string | truncate: length }}
{{ string | truncate: length, ellipsis }}
```

### Parameters
- **length** (required) - Maximum length including ellipsis
- **ellipsis** (optional) - Custom ellipsis string (default: "...")

### Examples
```liquid
{{ "Hello World" | truncate: 5 }}
<!-- Output: He... -->

{{ "Hello" | truncate: 10 }}
<!-- Output: Hello -->

{{ "Hello World" | truncate: 8, "---" }}
<!-- Output: Hello--- -->

{{ "A very long description" | truncate: 15 }}
<!-- Output: A very long... -->
```

### Notes
- If string is shorter than length, returns original string
- Ellipsis is included in the character count

---

## truncatewords

Limits a string to a specified number of words.

### Syntax
```liquid
{{ string | truncatewords: word_count }}
{{ string | truncatewords: word_count, ellipsis }}
```

### Parameters
- **word_count** (required) - Maximum number of words
- **ellipsis** (optional) - Custom ellipsis string (default: "...")

### Examples
```liquid
{{ "Hello World Foo Bar" | truncatewords: 2 }}
<!-- Output: Hello World... -->

{{ "Hello" | truncatewords: 2 }}
<!-- Output: Hello -->

{{ "Hello World Foo Bar" | truncatewords: 2, "---" }}
<!-- Output: Hello World--- -->
```

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

{{ "Hello\r\nWorld" | strip_newlines }}
<!-- Output: HelloWorld -->

{{ "Line 1\nLine 2\nLine 3" | strip_newlines }}
<!-- Output: Line 1Line 2Line 3 -->
```

---

## normalize_whitespace

Normalizes whitespace by replacing multiple consecutive whitespace characters with single spaces.

### Syntax
```liquid
{{ string | normalize_whitespace }}
```

### Examples
```liquid
{{ "Hello   World" | normalize_whitespace }}
<!-- Output: Hello World -->

{{ "   Hello   World   " | normalize_whitespace }}
<!-- Output:  Hello World  -->

{{ "Hello\nWorld" | normalize_whitespace }}
<!-- Output: Hello World -->
```

---

## number_of_words

Counts the number of words in a string.

### Syntax
```liquid
{{ string | number_of_words }}
{{ string | number_of_words: mode }}
```

### Parameters
- **mode** (optional) - Counting mode: `'cjk'`, `'auto'`, or default

### Examples
```liquid
{{ "Hello World" | number_of_words }}
<!-- Output: 2 -->

{{ "你好世界" | number_of_words: "cjk" }}
<!-- Output: 4 -->

{{ "Hello 世界" | number_of_words: "auto" }}
<!-- Output: 3 -->

{{ "" | number_of_words }}
<!-- Output: 0 -->
```

## Usage Patterns

### Text Processing Pipeline
```liquid
{{ user_input 
  | strip 
  | replace: "  ", " " 
  | truncatewords: 10 
  | capitalize }}
```

### URL Slug Generation
```liquid
{% assign slug = product.title 
  | downcase 
  | replace: " ", "-" 
  | remove: "'" 
  | remove: "!" %}
```

### Clean Input Data
```liquid
{% assign clean_name = form.name 
  | strip 
  | normalize_whitespace 
  | capitalize %}
```

### Content Formatting
```liquid
<p>{{ article.excerpt 
  | strip_newlines 
  | truncate: 150 
  | append: "..." }}</p>
```

### Dynamic Classes
```liquid
<div class="{{ category.name | downcase | replace: ' ', '-' }}">
  {{ category.name }}
</div>
```

### Search and Replace
```liquid
{% assign formatted_text = content 
  | replace: "\n", "<br>" 
  | replace: "[link]", "<a href='#'>" 
  | replace: "[/link]", "</a>" %}
```

## Performance Tips

1. **Chain efficiently** - Order operations to minimize intermediate processing
2. **Cache results** - Store processed strings in variables for reuse
3. **Validate input** - Use `default` filter for null safety

```liquid
{% assign processed_title = product.title 
  | default: "Untitled" 
  | strip 
  | truncate: 50 %}

<!-- Reuse the processed title -->
<h1>{{ processed_title }}</h1>
<meta property="og:title" content="{{ processed_title }}">
``` 