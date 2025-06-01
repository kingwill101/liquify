# Output Tags

Output tags control how content is rendered and processed in your Liquid templates.

## echo

Outputs the result of an expression, equivalent to using `{{ }}` syntax.

### Syntax
```liquid
{% echo expression %}
{% echo expression | filter %}
```

### Examples
```liquid
{% echo "Hello World" %}
<!-- Output: Hello World -->

{% echo user.name | upcase %}
<!-- Same as: {{ user.name | upcase }} -->
```

---

## liquid

Allows for compact, inline Liquid syntax without the need for separate tag blocks.

### Syntax
```liquid
{% liquid
  statement1
  statement2
  echo result
%}
```

### Examples
```liquid
{% liquid
  assign name = "John"
  assign greeting = "Hello " | append: name
  echo greeting
%}
<!-- Output: Hello John -->
```

### Notes
- More compact than multiple separate tag blocks
- Useful for complex variable manipulation
- Each line is treated as a separate Liquid statement 