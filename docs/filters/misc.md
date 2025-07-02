# Miscellaneous Filters

Miscellaneous filters provide utility functions for data conversion, debugging, and handling various data types that don't fit into other categories.

## default

Returns the input value if it's not falsy, otherwise returns the default value.

### Syntax
```liquid
{{ value | default: default_value }}
{{ value | default: default_value, allow_false }}
```

### Parameters
- **default_value** (required) - The value to return if input is falsy
- **allow_false** (optional) - If `true`, treats `false` as non-falsy (default: `false`)

### Examples

#### Basic Default Values
```liquid
{{ null | default: 'Guest' }}
<!-- Output: Guest -->

{{ '' | default: 'Empty' }}
<!-- Output: Empty -->

{{ 'Hello' | default: 'Guest' }}
<!-- Output: Hello -->
```

#### Handling False Values
```liquid
{{ false | default: 'Nope' }}
<!-- Output: Nope -->

{{ false | default: 'Nope', true }}
<!-- Output: false -->
```

#### With Variables
```liquid
{{ user.name | default: "Anonymous User" }}
{{ product.description | default: "No description available" }}
```

### Notes
- Treats empty strings, arrays, `null`, `false`, and `0` as falsy
- Use the second parameter to preserve `false` values
- Essential for providing fallback content

---

## json

Converts values to JSON format.

### Syntax
```liquid
{{ value | json }}
{{ value | json: indentation_spaces }}
```

### Parameters
- **indentation_spaces** (optional) - Number of spaces for pretty-printing

### Examples
```liquid
{{ {"name": "John", "age": 30} | json }}
<!-- Output: {"name":"John","age":30} -->

{{ {"name": "John", "age": 30} | json: 2 }}
<!-- Output: 
{
  "name": "John",
  "age": 30
}
-->

{{ [1, 2, 3] | json }}
<!-- Output: [1,2,3] -->

{{ "hello" | json }}
<!-- Output: "hello" -->
```

### Aliases
- `jsonify` - Alias for `json`

### Notes
- Handles nested objects and arrays
- Useful for debugging or API output
- Throws error for circular references (use `inspect` for those)

---

## parse_json

Parses a JSON string into a Dart object (Map, List, or primitive).

### Syntax
```liquid
{{ json_string | parse_json }}
```

### Parameters
None

### Examples

#### Parse Objects
```liquid
{{ '{"name": "John", "age": 30}' | parse_json }}
<!-- Creates: {name: John, age: 30} -->

{% assign user = '{"name": "John", "age": 30}' | parse_json %}
{{ user.name }} is {{ user.age }} years old
<!-- Output: John is 30 years old -->
```

#### Parse Arrays
```liquid
{{ '[1, 2, 3]' | parse_json }}
<!-- Creates: [1, 2, 3] -->

{% assign numbers = '[1, 2, 3]' | parse_json %}
{% for num in numbers %}{{ num }}{% endfor %}
<!-- Output: 123 -->
```

#### Parse Primitives
```liquid
{{ 'true' | parse_json }}     <!-- Output: true -->
{{ '42' | parse_json }}       <!-- Output: 42 -->
{{ '"hello"' | parse_json }}  <!-- Output: hello -->
{{ 'null' | parse_json }}     <!-- Output: null -->
```

#### Complex Nested Data
```liquid
{% assign data = '{"users":[{"name":"John","age":30},{"name":"Jane","age":25}]}' | parse_json %}
{% for user in data.users %}
  {{ user.name }}: {{ user.age }}
{% endfor %}
```

### Error Handling
```liquid
<!-- These will throw FormatException -->
{{ 'invalid json' | parse_json }}
{{ '{incomplete:' | parse_json }}
{{ null | parse_json }}  <!-- Throws ArgumentError -->
```

### Notes
- Throws `FormatException` for invalid JSON
- Throws `ArgumentError` for null input
- Supports all standard JSON data types
- Handles whitespace gracefully

---

## inspect

Inspects values for debugging, handling circular references safely.

### Syntax
```liquid
{{ value | inspect }}
{{ value | inspect: indent_spaces }}
```

### Parameters
- **indent_spaces** (optional) - Number of spaces for indentation

### Examples

#### Basic Inspection
```liquid
{{ {'a': 1, 'b': 2} | inspect }}
<!-- Output: {"a":1,"b":2} -->

{{ [1, 2, 3] | inspect }}
<!-- Output: [1,2,3] -->
```

#### Circular Reference Handling
```liquid
{% assign circular = {'a': {}} %}
{% assign circular.a.b = circular %}
{{ circular | inspect }}
<!-- Output: {"a":{"b":"[Circular]"}} -->
```

#### Pretty-Printed Inspection
```liquid
{{ complex_object | inspect: 2 }}
<!-- Output:
{
  "a": {
    "b": "[Circular]"
  }
}
-->
```

### Notes
- Safer than `json` for debugging circular structures
- Replaces circular references with `"[Circular]"`
- Identical to `json` for non-circular data
- Essential for debugging complex object relationships

---

## to_integer

Converts the input value to an integer.

### Syntax
```liquid
{{ value | to_integer }}
```

### Parameters
None

### Examples

#### Basic Conversion
```liquid
{{ 3.14 | to_integer }}
<!-- Output: 3 -->

{{ '42' | to_integer }}
<!-- Output: 42 -->

{{ 5.9 | to_integer }}
<!-- Output: 6 (rounds to nearest) -->
```

#### Error Handling
```liquid
{{ 'not a number' | to_integer }}
<!-- Throws FormatException -->
```

### Notes
- Rounds floating-point numbers to nearest integer
- Parses numeric strings
- Throws `FormatException` for invalid input

---

## raw

Returns the input value without any processing.

### Syntax
```liquid
{{ value | raw }}
```

### Parameters
None

### Examples

#### Pass-Through Filter
```liquid
{% assign my_var = "<p>Hello, World!</p>" %}
{{ my_var | raw }}
<!-- Output: <p>Hello, World!</p> -->

{{ 42 | raw }}
<!-- Output: 42 -->

{{ [1, 2, 3] | raw }}
<!-- Output: [1, 2, 3] -->
```

### Notes
- Identity filter - returns input unchanged
- Useful as placeholder in filter chains
- No transformation or processing applied

## Usage Patterns

### Safe Data Access
```liquid
{{ user.profile.name | default: "Unknown User" }}
{{ settings.theme | default: "default" }}
```

### JSON Data Pipeline
```liquid
{% assign raw_data = '{"items": [{"id": 1, "name": "Product"}]}' %}
{% assign parsed = raw_data | parse_json %}
{% assign output = parsed.items | json: 2 %}
```

### Debug Output
```liquid
{% comment %}Debug complex objects{% endcomment %}
{{ complex_object | inspect: 2 }}

{% comment %}Check for circular references{% endcomment %}
{{ potentially_circular | inspect }}
```

### Data Type Conversion
```liquid
{% assign count = "42" | to_integer %}
{% assign formatted = {'count': count} | json %}
```

### Fallback Content
```liquid
<h1>{{ page.title | default: "Untitled Page" }}</h1>
<p>{{ page.description | default: "No description provided." }}</p>
```

## Error Handling

### Graceful Degradation
```liquid
{{ data | parse_json | default: {} }}
{{ number_string | to_integer | default: 0 }}
```

### Validation Patterns
```liquid
{% assign parsed_data = json_string | parse_json %}
{% if parsed_data %}
  <!-- Process valid data -->
  {{ parsed_data | inspect }}
{% else %}
  <!-- Handle parsing failure -->
  Invalid data format
{% endif %}
```

## Performance Considerations

1. **Use `default` early** - Prevent null propagation in filter chains
2. **Cache parsed JSON** - Store `parse_json` results in variables for reuse
3. **Limit `inspect` usage** - Use only for debugging, not production output
4. **Validate before conversion** - Check data types before `to_integer`

```liquid
{% assign cached_data = api_response | parse_json | default: {} %}
{% if cached_data.items %}
  {% for item in cached_data.items %}
    {{ item.name | default: "Unnamed Item" }}
  {% endfor %}
{% endif %}
``` 