# Variable Tags

Variable tags allow you to create, modify, and capture variables within your Liquid templates. These tags are essential for storing and manipulating data during template rendering.

## assign

Creates or updates variables with values, expressions, or filter results.

### Syntax
```liquid
{% assign variable_name = value %}
{% assign variable_name = expression | filter %}
```

### Parameters
- **variable_name** (required) - The name of the variable to create/update
- **value** (required) - The value, expression, or filtered expression to assign

### Examples

#### Basic Assignment
```liquid
{% assign my_variable = "hello" %}
{{ my_variable }}
<!-- Output: hello -->
```

#### Assignment with Filters
```liquid
{% assign my_variable = "hello" | upcase %}
{{ my_variable }}
<!-- Output: HELLO -->
```

#### Expression Assignment
```liquid
{% assign x = 2 %}
{% assign result = x | plus: 3 %}
{{ result }}
<!-- Output: 5 -->
```

#### Multiple Filters
```liquid
{% assign my_variable = "hello world" | capitalize | split: " " | first %}
{{ my_variable }}
<!-- Output: Hello -->
```

### Notes
- Variables created with `assign` persist throughout the template
- Can assign strings, numbers, arrays, objects, and filtered results
- Supports both sync and async evaluation

---

## capture

Captures the rendered output of a template block into a variable.

### Syntax
```liquid
{% capture variable_name %}
  content to capture
{% endcapture %}
```

### Parameters
- **variable_name** (required) - The name of the variable to store the captured content

### Examples

#### Basic Capture
```liquid
{% capture my_variable %}I am being captured.{% endcapture %}
{{ my_variable }}
<!-- Output: I am being captured. -->
```

#### Capture with Variables and Filters
```liquid
{% capture my_variable %}Hello {{ "World" | upcase }}{% endcapture %}
{{ my_variable }}
<!-- Output: Hello WORLD -->
```

#### Complex Capture
```liquid
{% capture product_card %}
  <div class="product">
    <h3>{{ product.title }}</h3>
    <p>${{ product.price | round: 2 }}</p>
  </div>
{% endcapture %}

{{ product_card }}
```

### Notes
- The captured content is rendered and stored as a string
- Supports Liquid syntax within the capture block
- Useful for building reusable content snippets

---

## increment

Outputs and increments a counter variable. Each counter maintains its own independent state.

### Syntax
```liquid
{% increment counter_name %}
```

### Parameters
- **counter_name** (required) - The name of the counter variable

### Examples

#### Basic Increment
```liquid
{% increment counter %}
{% increment counter %}
{% increment counter %}
<!-- Output: 012 -->
```

#### Multiple Counters
```liquid
{% increment counter1 %}
{% increment counter2 %}
{% increment counter1 %}
{% increment counter2 %}
<!-- Output: 0011 -->
```

#### Independence from assign
```liquid
{% assign counter = 42 %}
{% increment counter %}
{{ counter }}
<!-- Output: 042 (increment counter is separate from assigned counter) -->
```

#### Shared State with decrement
```liquid
{% increment counter %}
{% decrement counter %}
{% increment counter %}
<!-- Output: 0-10 -->
```

### Notes
- Counters start at 0 on first use
- Each named counter maintains independent state
- `increment` counters are separate from variables created with `assign`
- Shares counter state with `decrement` tag

---

## decrement

Outputs and decrements a counter variable. Shares state with increment counters.

### Syntax
```liquid
{% decrement counter_name %}
```

### Parameters
- **counter_name** (required) - The name of the counter variable

### Examples

#### Basic Decrement
```liquid
{% decrement counter %}
{% decrement counter %}
{% decrement counter %}
<!-- Output: -1-2-3 -->
```

#### Starting from Increment
```liquid
{% increment counter %}
{% increment counter %}
{% decrement counter %}
{% decrement counter %}
<!-- Output: 0110 -->
```

#### Multiple Counters
```liquid
{% decrement counter1 %}
{% decrement counter2 %}
{% decrement counter1 %}
{% decrement counter2 %}
<!-- Output: -1-1-2-2 -->
```

### Notes
- Counters start at -1 on first decrement
- Shares state with `increment` counters of the same name
- Independent from variables created with `assign`
- Useful for countdown operations

## Usage Patterns

### Building Dynamic Content
```liquid
{% assign base_url = "https://example.com" %}
{% assign api_endpoint = base_url | append: "/api/v1" %}

{% capture user_greeting %}
  {% if user.name %}
    Hello, {{ user.name }}!
  {% else %}
    Welcome, Guest!
  {% endif %}
{% endcapture %}

{{ user_greeting }}
```

### Loop Counters
```liquid
{% for item in items %}
  <div id="item-{% increment item_counter %}">
    {{ item.title }}
  </div>
{% endfor %}
```

### Conditional Content Building
```liquid
{% capture error_message %}
  {% if errors.size > 0 %}
    <div class="errors">
      {% for error in errors %}
        <p>{{ error }}</p>
      {% endfor %}
    </div>
  {% endif %}
{% endcapture %}

{% if error_message != blank %}
  {{ error_message }}
{% endif %}
```

## Async Support

All variable tags support both synchronous and asynchronous evaluation:

```dart
// Synchronous
evaluator.evaluateNodes(document.children);

// Asynchronous
await evaluator.evaluateNodesAsync(document.children);
```

The behavior is identical in both modes, ensuring consistent results regardless of the evaluation method used. 