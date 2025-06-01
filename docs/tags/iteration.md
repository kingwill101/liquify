# Iteration Tags

Iteration tags allow you to loop through arrays, objects, ranges, and other collections to generate repetitive content in your Liquid templates.

## for

The primary iteration tag for looping through collections with advanced features and controls.

### Syntax
```liquid
{% for item in collection %}
  content
{% endfor %}

{% for item in collection limit: n offset: n reversed %}
  content
{% else %}
  content when collection is empty
{% endfor %}
```

### Parameters
- **item** (required) - Variable name for each iteration item
- **collection** (required) - Array, object, or range to iterate over
- **limit** (optional) - Maximum number of items to iterate
- **offset** (optional) - Number of items to skip from beginning
- **reversed** (optional) - Iterate in reverse order

### Examples

#### Basic Iteration
```liquid
{% for item in (1..3) %}{{ item }}{% endfor %}
<!-- Output: 123 -->
```

#### Empty Collection Handling
```liquid
{% for item in (1..0) %}{{ item }}{% else %}No items{% endfor %}
<!-- Output: No items -->
```

#### With Limit
```liquid
{% for item in (1..5) limit:3 %}{{ item }}{% endfor %}
<!-- Output: 123 -->
```

#### With Offset
```liquid
{% for item in (1..5) offset:2 %}{{ item }}{% endfor %}
<!-- Output: 345 -->
```

#### Reversed Order
```liquid
{% for item in (1..3) reversed %}{{ item }}{% endfor %}
<!-- Output: 321 -->
```

#### Iterating Over Objects (Maps)
```liquid
{% for pair in metadata %}{{ pair[0] }}:{{ pair[1] }}{% endfor %}
<!-- Iterates over key-value pairs -->
```

### forloop Object

Within a `for` loop, the `forloop` object provides iteration metadata:

- **forloop.index** - Current iteration (1-indexed)
- **forloop.index0** - Current iteration (0-indexed) 
- **forloop.first** - true if first iteration
- **forloop.last** - true if last iteration
- **forloop.length** - Total number of iterations
- **forloop.rindex** - Remaining iterations (including current)
- **forloop.rindex0** - Remaining iterations (0-indexed)
- **forloop.parentloop** - Parent loop object for nested loops

```liquid
{% for item in (1..3) %}
  Index:{{ forloop.index }}, First:{{ forloop.first }}, Last:{{ forloop.last }}
{% endfor %}
<!-- Output: Index:1, First:true, Last:false Index:2, First:false, Last:false Index:3, First:false, Last:true -->
```

#### Nested Loops
```liquid
{% for outer in (1..2) %}
  {% for inner in (1..2) %}
    Outer:{{ forloop.parentloop.index }}, Inner:{{ forloop.index }}
  {% endfor %}
{% endfor %}
<!-- Output: Outer:1, Inner:1 Outer:1, Inner:2 Outer:2, Inner:1 Outer:2, Inner:2 -->
```

---

## tablerow

Generates HTML table rows with automatic row and column management.

### Syntax
```liquid
{% tablerow item in collection %}
  content
{% endtablerow %}

{% tablerow item in collection cols:n limit:n offset:n %}
  content
{% endtablerow %}
```

### Parameters
- **item** (required) - Variable name for each item
- **collection** (required) - Collection to iterate over
- **cols** (optional) - Number of columns per row (default: 6)
- **limit** (optional) - Maximum number of items
- **offset** (optional) - Number of items to skip

### Examples

#### Basic Table Row
```liquid
<table>
{% tablerow product in products %}
  {{ product.title }}
{% endtablerow %}
</table>
<!-- Generates <tr> and <td> elements automatically -->
```

#### With Column Control
```liquid
<table>
{% tablerow item in (1..6) cols:2 %}
  {{ item }}
{% endtablerow %}
</table>
<!-- Output: 3 rows with 2 columns each -->
```

#### With Limit and Offset
```liquid
<table>
{% tablerow item in (1..10) cols:3 limit:6 offset:2 %}
  {{ item }}
{% endtablerow %}
</table>
<!-- Shows items 3-8 in 2 rows of 3 columns -->
```

### tablerowloop Object

Similar to `forloop` but for table-specific properties:

- **tablerowloop.index** - Current item index
- **tablerowloop.col** - Current column number
- **tablerowloop.col0** - Current column (0-indexed)
- **tablerowloop.row** - Current row number
- **tablerowloop.first** - true if first item
- **tablerowloop.last** - true if last item
- **tablerowloop.col_first** - true if first column
- **tablerowloop.col_last** - true if last column

---

## cycle

Cycles through a list of values, commonly used in loops for alternating content.

### Syntax
```liquid
{% cycle value1, value2, value3 %}
{% cycle "group_name": value1, value2, value3 %}
```

### Parameters
- **values** (required) - Comma-separated list of values to cycle through
- **group_name** (optional) - Name for independent cycle groups

### Examples

#### Basic Cycling
```liquid
{% cycle "one", "two", "three" %}
{% cycle "one", "two", "three" %}
{% cycle "one", "two", "three" %}
{% cycle "one", "two", "three" %}
<!-- Output: onetwothreeone -->
```

#### Named Groups
```liquid
{% cycle "group1": "one", "two", "three" %}
{% cycle "group2": "a", "b", "c" %}
{% cycle "group1": "one", "two", "three" %}
{% cycle "group2": "a", "b", "c" %}
<!-- Output: oneatwob -->
```

#### In Loops
```liquid
{% for item in items %}
  <div class="{% cycle 'odd', 'even' %}">{{ item }}</div>
{% endfor %}
```

#### With Variables
```liquid
{% assign var1 = "first" %}
{% assign var2 = "second" %}
{% cycle var1, var2 %}
{% cycle var1, var2 %}
<!-- Output: firstsecond -->
```

---

## repeat

Repeats content a specified number of times.

### Syntax
```liquid
{% repeat count %}
  content
{% endrepeat %}
```

### Parameters
- **count** (required) - Number of times to repeat content

### Examples

#### Basic Repeat
```liquid
{% repeat 3 %}Hello{% endrepeat %}
<!-- Output: HelloHelloHello -->
```

#### With Variables
```liquid
{% assign count = 4 %}
{% repeat count %}*{% endrepeat %}
<!-- Output: **** -->
```

## Loop Control

### break
Exit a loop early:
```liquid
{% for item in (1..5) %}
  {% if item == 3 %}{% break %}{% endif %}
  {{ item }}
{% endfor %}
<!-- Output: 12 -->
```

### continue
Skip to the next iteration:
```liquid
{% for item in (1..5) %}
  {% if item == 3 %}{% continue %}{% endif %}
  {{ item }}
{% endfor %}
<!-- Output: 1245 -->
```

## Common Patterns

### Alternating Content
```liquid
{% for product in products %}
  <div class="product {% cycle 'left', 'right' %}">
    <h3>{{ product.title }}</h3>
    <p>{{ product.description }}</p>
  </div>
{% endfor %}
```

### Grid Layout with tablerow
```liquid
<table class="product-grid">
{% tablerow product in products cols:3 %}
  <div class="product-card">
    <img src="{{ product.image }}" alt="{{ product.title }}">
    <h3>{{ product.title }}</h3>
    <p>${{ product.price }}</p>
  </div>
{% endtablerow %}
</table>
```

### Conditional Iteration
```liquid
{% for product in products %}
  {% if product.featured %}
    <div class="featured">{{ product.title }}</div>
  {% elsif forloop.index <= 3 %}
    <div class="top-three">{{ product.title }}</div>
  {% else %}
    {% unless forloop.last %}
      <div class="regular">{{ product.title }}</div>
    {% endunless %}
  {% endif %}
{% endfor %}
```

## Async Support

All iteration tags support both synchronous and asynchronous evaluation with identical behavior in both modes. 