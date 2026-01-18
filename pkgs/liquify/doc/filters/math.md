# Math Filters

Math filters provide numerical operations and calculations for your Liquid templates.

## plus

Adds a number to the input value.

### Syntax
```liquid
{{ value | plus: number }}
```

### Parameters
- **number** (required) - The number to add

### Examples
```liquid
{{ 5 | plus: 3 }}
<!-- Output: 8 -->

{{ 10.5 | plus: 2.3 }}
<!-- Output: 12.8 -->

{{ 0 | plus: 42 }}
<!-- Output: 42 -->
```

### Notes
- Treats `null` input as `0`
- Treats `null` argument as `0`

---

## minus

Subtracts a number from the input value.

### Syntax
```liquid
{{ value | minus: number }}
```

### Parameters
- **number** (required) - The number to subtract

### Examples
```liquid
{{ 10 | minus: 3 }}
<!-- Output: 7 -->

{{ 15.5 | minus: 2.2 }}
<!-- Output: 13.3 -->

{{ 5 | minus: 10 }}
<!-- Output: -5 -->
```

### Notes
- Treats `null` input as `0`
- Treats `null` argument as `0`

---

## times

Multiplies the input value by a number.

### Syntax
```liquid
{{ value | times: number }}
```

### Parameters
- **number** (required) - The number to multiply by

### Examples
```liquid
{{ 5 | times: 3 }}
<!-- Output: 15 -->

{{ 2.5 | times: 4 }}
<!-- Output: 10.0 -->

{{ 0 | times: 100 }}
<!-- Output: 0 -->
```

### Notes
- Treats `null` input as `0`
- Treats `null` argument as `0`

---

## divided_by

Divides the input value by a number.

### Syntax
```liquid
{{ value | divided_by: number }}
{{ value | divided_by: number, integer_arithmetic }}
```

### Parameters
- **number** (required) - The number to divide by
- **integer_arithmetic** (optional) - If `true`, performs integer division (default: `false`)

### Examples
```liquid
{{ 10 | divided_by: 3 }}
<!-- Output: 3.3333333333333335 -->

{{ 10 | divided_by: 3, true }}
<!-- Output: 3 -->

{{ 15 | divided_by: 5 }}
<!-- Output: 3.0 -->

{{ 10 | divided_by: 0 }}
<!-- Output: 0 (prevents division by zero) -->
```

### Notes
- Prevents division by zero (returns `0`)
- Integer arithmetic floors the result
- Treats `null` input as `0`
- Treats `null` divisor as `1`

---

## modulo

Returns the remainder of dividing the input value by a number.

### Syntax
```liquid
{{ value | modulo: number }}
```

### Parameters
- **number** (required) - The divisor

### Examples
```liquid
{{ 10 | modulo: 3 }}
<!-- Output: 1 -->

{{ 17 | modulo: 5 }}
<!-- Output: 2 -->

{{ 8 | modulo: 4 }}
<!-- Output: 0 -->

{{ -7 | modulo: 3 }}
<!-- Output: 2 (always positive result) -->
```

### Notes
- Always returns a positive result
- Prevents modulo by zero (returns `0`)
- Uses the formula: `((a % b) + b) % b`

---

## abs

Returns the absolute value of the input.

### Syntax
```liquid
{{ value | abs }}
```

### Examples
```liquid
{{ -5 | abs }}
<!-- Output: 5 -->

{{ 3.14 | abs }}
<!-- Output: 3.14 -->

{{ 0 | abs }}
<!-- Output: 0 -->

{{ null | abs }}
<!-- Output: 0 -->
```

### Notes
- Treats `null` input as `0`

---

## ceil

Returns the smallest integer greater than or equal to the input value.

### Syntax
```liquid
{{ value | ceil }}
```

### Examples
```liquid
{{ 5.1 | ceil }}
<!-- Output: 6 -->

{{ 5.0 | ceil }}
<!-- Output: 5 -->

{{ -2.3 | ceil }}
<!-- Output: -2 -->

{{ null | ceil }}
<!-- Output: 0 -->
```

### Notes
- Treats `null` input as `0`

---

## floor

Returns the largest integer less than or equal to the input value.

### Syntax
```liquid
{{ value | floor }}
```

### Examples
```liquid
{{ 5.9 | floor }}
<!-- Output: 5 -->

{{ 5.0 | floor }}
<!-- Output: 5 -->

{{ -2.3 | floor }}
<!-- Output: -3 -->

{{ null | floor }}
<!-- Output: 0 -->
```

### Notes
- Treats `null` input as `0`

---

## round

Rounds the input value to the specified number of decimal places.

### Syntax
```liquid
{{ value | round }}
{{ value | round: decimal_places }}
```

### Parameters
- **decimal_places** (optional) - Number of decimal places to round to (default: `0`)

### Examples
```liquid
{{ 5.6789 | round }}
<!-- Output: 6 -->

{{ 5.6789 | round: 2 }}
<!-- Output: 5.68 -->

{{ 5.6789 | round: 0 }}
<!-- Output: 6 -->

{{ 123.456 | round: 1 }}
<!-- Output: 123.5 -->
```

### Notes
- Treats `null` input as `0`
- Uses standard rounding rules (0.5 rounds up)

---

## at_least

Returns the maximum of the input value and the argument.

### Syntax
```liquid
{{ value | at_least: minimum }}
```

### Parameters
- **minimum** (required) - The minimum value to return

### Examples
```liquid
{{ 5 | at_least: 10 }}
<!-- Output: 10 -->

{{ 15 | at_least: 10 }}
<!-- Output: 15 -->

{{ -5 | at_least: 0 }}
<!-- Output: 0 -->
```

### Notes
- Useful for setting minimum boundaries
- Treats `null` values as `0`

---

## at_most

Returns the minimum of the input value and the argument.

### Syntax
```liquid
{{ value | at_most: maximum }}
```

### Parameters
- **maximum** (required) - The maximum value to return

### Examples
```liquid
{{ 15 | at_most: 10 }}
<!-- Output: 10 -->

{{ 5 | at_most: 10 }}
<!-- Output: 5 -->

{{ 100 | at_most: 50 }}
<!-- Output: 50 -->
```

### Notes
- Useful for setting maximum boundaries
- Treats `null` values as `0`

## Usage Patterns

### Price Calculations
```liquid
{% assign subtotal = items | sum: "price" %}
{% assign tax = subtotal | times: 0.08 | round: 2 %}
{% assign total = subtotal | plus: tax %}
```

### Percentage Operations
```liquid
{% assign discount_amount = price | times: discount_percent | divided_by: 100 %}
{% assign final_price = price | minus: discount_amount | round: 2 %}
```

### Range Constraints
```liquid
{% assign normalized_score = user_score | at_least: 0 | at_most: 100 %}
{% assign progress_percent = completed | divided_by: total | times: 100 | round: 1 %}
```

### Statistical Calculations
```liquid
{% assign average = values | sum | divided_by: values.size | round: 2 %}
{% assign variance = values | map: "deviation" | sum | divided_by: values.size %}
```

### Pagination Math
```liquid
{% assign total_pages = total_items | divided_by: items_per_page | ceil %}
{% assign current_page = page_number | at_least: 1 | at_most: total_pages %}
```

### Financial Calculations
```liquid
{% assign monthly_payment = principal 
  | times: rate 
  | divided_by: 12 
  | round: 2 %}
```

## Error Handling

Math filters handle edge cases gracefully:

```liquid
{{ null | plus: 5 }}          <!-- Output: 5 -->
{{ 10 | divided_by: 0 }}      <!-- Output: 0 -->
{{ -7 | modulo: 3 }}          <!-- Output: 2 -->
{{ "text" | times: 2 }}       <!-- Error: Invalid operation -->
```

## Chaining Math Operations

```liquid
{% assign result = base_value
  | plus: adjustment
  | times: multiplier
  | round: 2
  | at_least: minimum_value %}
```

## Advanced Examples

### Complex Financial Calculation
```liquid
{% assign compound_interest = principal
  | times: rate
  | plus: 1
  | times: years
  | minus: principal
  | round: 2 %}
```

### Normalized Scoring
```liquid
{% assign normalized_score = raw_score
  | minus: min_score
  | divided_by: max_score | minus: min_score
  | times: 100
  | round: 1
  | at_least: 0
  | at_most: 100 %}
```

### Grid Layout Calculations
```liquid
{% assign columns_per_row = container_width | divided_by: item_width | floor %}
{% assign rows_needed = total_items | divided_by: columns_per_row | ceil %}
```

## Performance Tips

1. **Use integer arithmetic** when appropriate to avoid floating-point precision issues
2. **Round early** in calculation chains to prevent accumulation of precision errors
3. **Cache complex calculations** in variables for reuse

```liquid
{% assign tax_rate = 0.08 %}
{% assign rounded_subtotal = subtotal | round: 2 %}
{% assign tax = rounded_subtotal | times: tax_rate | round: 2 %}
``` 