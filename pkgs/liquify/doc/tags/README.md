# Tags Documentation

Tags are the logic elements of Liquid templates. They control the flow of the template, perform iterations, create variables, and handle layout rendering.

## Tag Categories

### Control Flow Tags
Control the execution flow of your templates with conditional logic.

- **[if](control-flow.md#if)** - Conditional execution
- **[unless](control-flow.md#unless)** - Negative conditional execution  
- **[case](control-flow.md#case)** - Multi-way conditional execution

### Iteration Tags
Loop through arrays, objects, and ranges to generate repetitive content.

- **[for](iteration.md#for)** - Standard iteration with advanced features
- **[tablerow](iteration.md#tablerow)** - Generate HTML table rows
- **[cycle](iteration.md#cycle)** - Cycle through values
- **[repeat](iteration.md#repeat)** - Repeat content a specific number of times

### Variable Tags
Create, modify, and capture variables within your templates.

- **[assign](variables.md#assign)** - Create variables
- **[capture](variables.md#capture)** - Capture template output into variables
- **[increment](variables.md#increment)** - Increment numeric variables
- **[decrement](variables.md#decrement)** - Decrement numeric variables

### Layout & Rendering Tags
Handle template composition, inheritance, and partial rendering.

- **[layout](layout.md#layout)** - Define layout templates
- **[block](layout.md#block)** - Define replaceable content blocks
- **[super](layout.md#super)** - Call parent block content
- **[render](layout.md#render)** - Include and render other templates

### Output Tags
Control how content is output and processed.

- **[echo](output.md#echo)** - Output expressions (same as `{{ }}`)
- **[liquid](output.md#liquid)** - Compact tag syntax

### Utility Tags
Utility tags for content handling and flow control.

- **[raw](utility.md#raw)** - Output content without processing
- **[comment](utility.md#comment)** - Add comments (not rendered)
- **[break](utility.md#break)** - Exit loops early
- **[continue](utility.md#continue)** - Skip to next iteration

## Syntax Overview

### Block Tags
Most tags are block tags that wrap content:

```liquid
{% tagname parameters %}
  content
{% endtagname %}
```

### Inline Tags
Some tags are inline and don't require closing:

```liquid
{% tagname parameters %}
```

### Parameters
Tags can accept various types of parameters:

```liquid
{% for item in array limit: 5 offset: 2 %}
{% assign name = "value" %}
{% if condition == true %}
```

## Common Patterns

### Combining Tags
Tags can be nested and combined for complex logic:

```liquid
{% for product in products %}
  {% if product.available %}
    {% assign discounted_price = product.price | times: 0.9 %}
    <div class="product">
      <h3>{{ product.title }}</h3>
      <p>Price: ${{ discounted_price }}</p>
    </div>
  {% endif %}
{% endfor %}
```

### Error Handling
Most tags handle missing data gracefully:

```liquid
{% for item in missing_array %}
  This won't execute if missing_array is null
{% else %}
  This will execute instead
{% endfor %}
```

## Async Support

All tags support both synchronous and asynchronous evaluation:

```dart
// Synchronous
evaluator.evaluateNodes(document.children);

// Asynchronous  
await evaluator.evaluateNodesAsync(document.children);
``` 