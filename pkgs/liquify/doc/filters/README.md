# Filters Documentation

Filters transform and manipulate data in your Liquid templates. They are applied using the pipe (`|`) operator and can be chained together for complex transformations.

## Filter Categories

### [Array Filters](array.md)
Manipulate arrays, lists, and collections with powerful array operations.

- **[join](array.md#join)** - Join array elements into a string
- **[first](array.md#first)** - Get the first element
- **[last](array.md#last)** - Get the last element
- **[size](array.md#size)** - Get array length
- **[length](array.md#size)** - Alias for size
- **[upper](array.md#upper)** - Convert to uppercase
- **[lower](array.md#lower)** - Convert to lowercase
- **[reverse](array.md#reverse)** - Reverse array order
- **[sort](array.md#sort)** - Sort array elements
- **[sort_natural](array.md#sort_natural)** - Natural/human-friendly sorting
- **[map](array.md#map)** - Extract property values
- **[where](array.md#where)** - Filter by property values
- **[where_exp](array.md#where_exp)** - Filter by Liquid expressions
- **[reject](array.md#reject)** - Exclude by property values
- **[reject_exp](array.md#reject_exp)** - Exclude by Liquid expressions
- **[uniq](array.md#uniq)** - Remove duplicates
- **[slice](array.md#slice)** - Extract array portion
- **[compact](array.md#compact)** - Remove null values
- **[concat](array.md#concat)** - Combine arrays
- **[push](array.md#push)** - Add element to end
- **[pop](array.md#pop)** - Remove last element
- **[shift](array.md#shift)** - Remove first element
- **[unshift](array.md#unshift)** - Add element to beginning
- **[find](array.md#find)** - Find first matching element
- **[find_exp](array.md#find_exp)** - Find first matching element by expression
- **[find_index](array.md#find_index)** - Find index of matching element
- **[find_index_exp](array.md#find_index_exp)** - Find index by expression
- **[sum](array.md#sum)** - Sum numeric values
- **[group_by](array.md#group_by)** - Group by property value
- **[group_by_exp](array.md#group_by_exp)** - Group by expression result
- **[has](array.md#has)** - Check for property values
- **[has_exp](array.md#has_exp)** - Check for expression matches

### [String Filters](string.md)
Transform and format strings with comprehensive text manipulation.

- **[append](string.md#append)** - Add text to end
- **[prepend](string.md#prepend)** - Add text to beginning
- **[upcase](string.md#upcase)** - Convert to uppercase
- **[downcase](string.md#downcase)** - Convert to lowercase
- **[capitalize](string.md#capitalize)** - Capitalize first letter
- **[strip](string.md#strip)** - Remove whitespace
- **[lstrip](string.md#lstrip)** - Remove leading whitespace
- **[rstrip](string.md#rstrip)** - Remove trailing whitespace
- **[replace](string.md#replace)** - Replace all occurrences
- **[replace_first](string.md#replace_first)** - Replace first occurrence
- **[replace_last](string.md#replace_last)** - Replace last occurrence
- **[remove](string.md#remove)** - Remove all occurrences
- **[remove_first](string.md#remove_first)** - Remove first occurrence
- **[remove_last](string.md#remove_last)** - Remove last occurrence
- **[split](string.md#split)** - Split into array
- **[truncate](string.md#truncate)** - Limit length
- **[truncatewords](string.md#truncatewords)** - Limit word count
- **[strip_newlines](string.md#strip_newlines)** - Remove newlines
- **[normalize_whitespace](string.md#normalize_whitespace)** - Normalize spacing
- **[number_of_words](string.md#number_of_words)** - Count words
- **[array_to_sentence_string](string.md#array_to_sentence_string)** - Array to sentence

### [Math Filters](math.md)
Perform mathematical operations and calculations.

- **[plus](math.md#plus)** - Addition
- **[minus](math.md#minus)** - Subtraction
- **[times](math.md#times)** - Multiplication
- **[divided_by](math.md#divided_by)** - Division
- **[modulo](math.md#modulo)** - Remainder
- **[abs](math.md#abs)** - Absolute value
- **[ceil](math.md#ceil)** - Round up
- **[floor](math.md#floor)** - Round down
- **[round](math.md#round)** - Round to nearest
- **[at_least](math.md#at_least)** - Minimum value
- **[at_most](math.md#at_most)** - Maximum value

### [Date Filters](date.md)
Format and manipulate dates and times.

- **[date](date.md#date)** - Format dates with custom patterns
- **[date_to_xmlschema](date.md#date_to_xmlschema)** - ISO 8601 format
- **[date_to_rfc822](date.md#date_to_rfc822)** - RFC 822 format
- **[date_to_string](date.md#date_to_string)** - Short string format
- **[date_to_long_string](date.md#date_to_long_string)** - Long string format

### [HTML Filters](html.md)
Handle HTML encoding and manipulation safely.

- **[escape](html.md#escape)** - HTML escape special characters
- **[xml_escape](html.md#escape)** - Alias for escape
- **[escape_once](html.md#escape_once)** - Escape only unescaped content
- **[unescape](html.md#unescape)** - Convert HTML entities back
- **[strip_html](html.md#strip_html)** - Remove HTML tags
- **[newline_to_br](html.md#newline_to_br)** - Convert newlines to `<br>`
- **[strip_newlines](html.md#strip_newlines)** - Remove newline characters

### [URL Filters](url.md)
Encode and manipulate URLs and query strings.

- **[url_encode](url.md#url_encode)** - URL encode for query parameters
- **[url_decode](url.md#url_decode)** - URL decode
- **[cgi_escape](url.md#cgi_escape)** - CGI form encoding
- **[uri_escape](url.md#uri_escape)** - URI path encoding
- **[slugify](url.md#slugify)** - Create URL-friendly slugs

### [Miscellaneous Filters](misc.md)
Utility filters for various data operations.

- **[default](misc.md#default)** - Provide fallback values
- **[json](misc.md#json)** - Convert to JSON
- **[jsonify](misc.md#json)** - Alias for json
- **[parse_json](misc.md#parse_json)** - Parse JSON strings
- **[inspect](misc.md#inspect)** - Debug output with circular reference handling
- **[to_integer](misc.md#to_integer)** - Convert to integer
- **[raw](misc.md#raw)** - Output without processing

## Basic Syntax

### Single Filter
```liquid
{{ value | filter_name }}
{{ "hello" | upcase }}  <!-- Output: HELLO -->
```

### Filter with Arguments
```liquid
{{ value | filter_name: argument }}
{{ "hello world" | truncate: 5 }}  <!-- Output: hello... -->
```

### Multiple Arguments
```liquid
{{ value | filter_name: arg1, arg2 }}
{{ "hello" | replace: "l", "x" }}  <!-- Output: hexxo -->
```

### Chained Filters
```liquid
{{ value | filter1 | filter2 | filter3 }}
{{ "hello world" | upcase | replace: " ", "-" | append: "!" }}
<!-- Output: HELLO-WORLD! -->
```

## Common Patterns

### Data Transformation Pipeline
```liquid
{% assign processed_data = raw_data 
  | map: "title" 
  | compact 
  | sort 
  | uniq 
  | join: ", " %}
```

### Safe Output with Defaults
```liquid
{{ product.title | default: "Untitled Product" }}
{{ user.email | default: "No email provided" }}
```

### Text Processing
```liquid
{{ description 
  | strip 
  | truncate: 100 
  | append: "..." 
  | escape }}
```

### Number Formatting
```liquid
{{ price | times: 1.08 | round: 2 | prepend: "$" }}
{{ quantity | at_least: 0 | at_most: 100 }}
```

## Error Handling

Most filters handle invalid input gracefully:

```liquid
{{ null | size }}           <!-- Output: 0 -->
{{ "" | default: "empty" }} <!-- Output: empty -->
{{ "abc" | plus: 1 }}       <!-- Error: invalid operation -->
```

## Async Support

All filters support both synchronous and asynchronous evaluation with identical behavior.

## Custom Filters

You can extend the filter system by registering custom filters:

```dart
FilterRegistry.register('myFilter', (value, args, namedArgs) {
  // Custom filter logic
  return transformedValue;
});
```

## Performance Tips

1. **Chain efficiently** - Order filters to minimize intermediate processing
2. **Use appropriate types** - Some filters work better with specific data types
3. **Cache complex results** - Store transformed data in variables when reused
4. **Validate inputs** - Use `default` filter to handle null/undefined values

```liquid
{% assign cached_result = expensive_data | complex_transform %}
{% for item in items %}{{ cached_result }}{% endfor %}
``` 