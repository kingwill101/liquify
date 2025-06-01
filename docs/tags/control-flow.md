# Control Flow Tags

Control flow tags allow you to create conditional logic in your Liquid templates. These tags determine which parts of your template are rendered based on specific conditions.

## if

Executes a block of code if a condition is true. Supports `else` and `elseif`/`elif` for multiple conditions.

### Syntax
```liquid
{% if condition %}
  content when true
{% endif %}

{% if condition %}
  content when true
{% else %}
  content when false
{% endif %}

{% if condition1 %}
  content for condition1
{% elseif condition2 %}
  content for condition2
{% else %}
  fallback content
{% endif %}
```

### Parameters
- **condition** (required) - Any expression that evaluates to true or false

### Examples

#### Basic If Statement
```liquid
{% if true %}
  True
{% endif %}
<!-- Output: True -->
```

#### If-Else Statement
```liquid
{% if false %}
  True
{% else %}
  False
{% endif %}
<!-- Output: False -->
```

#### Multiple Conditions
```liquid
{% if false %}
  first
{% elseif true %}
  second
{% elseif true %}
  third
{% else %}
  fourth
{% endif %}
<!-- Output: second -->
```

#### Nested If Statements
```liquid
{% if true %}
  {% if false %}
    Inner False
  {% else %}
    Inner True
  {% endif %}
{% endif %}
<!-- Output: Inner True -->
```

#### Variable Comparisons
```liquid
{% if user.logged_in %}
  Welcome back, {{ user.name }}!
{% else %}
  Please log in.
{% endif %}
```

#### Complex Conditions
```liquid
{% if product.price > 100 and product.available %}
  Premium product available!
{% elsif product.price > 50 %}
  Mid-range product
{% else %}
  Budget-friendly option
{% endif %}
```

### Notes
- Supports `elseif` and `elif` (both forms are valid)
- Can be used with `break` and `continue` inside loops
- Conditions follow Liquid truthiness rules
- Supports nested if statements

---

## unless

Executes a block of code if a condition is false. This is the inverse of `if`.

### Syntax
```liquid
{% unless condition %}
  content when condition is false
{% endunless %}
```

### Parameters
- **condition** (required) - Any expression that evaluates to true or false

### Examples

#### Basic Unless
```liquid
{% unless product.title == "Awesome Shoes" %}
  These shoes are not awesome.
{% endunless %}
<!-- Output: These shoes are not awesome. (if title is not "Awesome Shoes") -->
```

#### Unless with Variable
```liquid
{% unless user.logged_in %}
  Please log in to continue.
{% endunless %}
```

#### Nested Unless
```liquid
{% unless product.title == "Awesome Shoes" %}
  {% unless product.price > 100 %}
    Affordable non-awesome shoes!
  {% endunless %}
{% endunless %}
```

#### Unless vs If
```liquid
<!-- These are equivalent -->
{% unless condition %}
  content
{% endunless %}

{% if condition == false %}
  content
{% endif %}
```

### Notes
- `unless` does not support `else` or `elseif` blocks
- Use `if` with negated conditions for more complex logic
- Can be nested for multiple negative conditions
- Useful for guard clauses and negative conditions

---

## case

Provides multi-way conditional logic, similar to switch statements in other languages.

### Syntax
```liquid
{% case variable %}
  {% when value1 %}
    content for value1
  {% when value2, value3 %}
    content for value2 or value3
  {% else %}
    fallback content
{% endcase %}
```

### Parameters
- **variable** (required) - The variable or expression to compare against
- **when values** (required) - One or more values to match against

### Examples

#### Basic Case Statement
```liquid
{% assign handle = "cake" %}
{% case handle %}
  {% when "cake" %}
    This is a cake
  {% when "cookie" %}
    This is a cookie
  {% else %}
    This is not a cake nor a cookie
{% endcase %}
<!-- Output: This is a cake -->
```

#### Multiple Values in When
```liquid
{% assign handle = "biscuit" %}
{% case handle %}
  {% when "cake" %}
    This is a cake
  {% when "cookie", "biscuit" %}
    This is a cookie or biscuit
  {% else %}
    This is something else
{% endcase %}
<!-- Output: This is a cookie or biscuit -->
```

#### Case Without Else
```liquid
{% assign handle = "pie" %}
{% case handle %}
  {% when "cake" %}
    This is a cake
  {% when "cookie" %}
    This is a cookie
{% endcase %}
<!-- Output: (nothing - no match and no else) -->
```

#### Case with Product Types
```liquid
{% case product.type %}
  {% when "book" %}
    <i class="icon-book"></i> {{ product.title }}
  {% when "cd", "dvd" %}
    <i class="icon-disc"></i> {{ product.title }}
  {% when "clothing" %}
    <i class="icon-shirt"></i> {{ product.title }}
  {% else %}
    <i class="icon-product"></i> {{ product.title }}
{% endcase %}
```

### Notes
- Uses exact equality comparison (==)
- Supports multiple values in a single `when` clause
- `else` clause is optional but recommended
- More efficient than multiple `if`/`elseif` for many conditions
- First matching `when` clause is executed (no fall-through)

## Control Flow in Loops

Control flow tags work seamlessly with loop tags for complex logic:

### Break on Condition
```liquid
{% for item in (1..5) %}
  {% if item == 3 %}
    {% break %}
  {% endif %}
  {{ item }}
{% endfor %}
<!-- Output: 12 -->
```

### Continue on Condition
```liquid
{% for item in (1..5) %}
  {% if item == 3 %}
    {% continue %}
  {% endif %}
  {{ item }}
{% endfor %}
<!-- Output: 1245 -->
```

### Complex Loop Logic
```liquid
{% for product in products %}
  {% case product.availability %}
    {% when "in_stock" %}
      {% if product.featured %}
        <div class="featured-product">{{ product.title }}</div>
      {% else %}
        <div class="regular-product">{{ product.title }}</div>
      {% endif %}
    {% when "low_stock" %}
      <div class="low-stock">{{ product.title }} - Only {{ product.quantity }} left!</div>
    {% else %}
      {% unless product.coming_soon %}
        {% continue %}
      {% endunless %}
      <div class="coming-soon">{{ product.title }} - Coming Soon</div>
  {% endcase %}
{% endfor %}
```

## Truthiness Rules

Liquid follows these truthiness rules for conditions:

### Truthy Values
- `true`
- Non-zero numbers
- Non-empty strings
- Non-empty arrays
- Non-null objects

### Falsy Values  
- `false`
- `null`/`nil`
- `0`
- Empty strings `""`
- Empty arrays `[]`

### Examples
```liquid
{% if "" %}Never executed{% endif %}
{% if "hello" %}Always executed{% endif %}
{% if 0 %}Never executed{% endif %}
{% if 42 %}Always executed{% endif %}
{% if array %}Executed if array has items{% endif %}
```

## Async Support

All control flow tags support both synchronous and asynchronous evaluation:

```dart
// Synchronous
evaluator.evaluateNodes(document.children);

// Asynchronous
await evaluator.evaluateNodesAsync(document.children);
```

The conditional logic and execution flow remain identical in both modes. 