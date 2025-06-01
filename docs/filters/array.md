# Array Filters

Array filters provide powerful operations for manipulating lists, collections, and sequences in your Liquid templates.

## join

Joins array elements into a string using a separator.

### Syntax
```liquid
{{ array | join }}
{{ array | join: separator }}
```

### Parameters
- **separator** (optional) - The string to use as separator (default: space)

### Examples
```liquid
{{ [1, 2, 3] | join }}
<!-- Output: 1 2 3 -->

{{ ["apple", "banana", "orange"] | join: ", " }}
<!-- Output: apple, banana, orange -->

{{ ["Hello", "World"] | join: "-" }}
<!-- Output: Hello-World -->
```

---

## first

Returns the first element of an array.

### Syntax
```liquid
{{ array | first }}
```

### Examples
```liquid
{{ [1, 2, 3] | first }}
<!-- Output: 1 -->

{{ ["apple", "banana"] | first }}
<!-- Output: apple -->

{{ [] | first }}
<!-- Output: (empty) -->
```

---

## last

Returns the last element of an array.

### Syntax
```liquid
{{ array | last }}
```

### Examples
```liquid
{{ [1, 2, 3] | last }}
<!-- Output: 3 -->

{{ ["apple", "banana"] | last }}
<!-- Output: banana -->

{{ [] | last }}
<!-- Output: (empty) -->
```

---

## size

Returns the number of elements in an array or characters in a string.

### Syntax
```liquid
{{ array | size }}
{{ string | size }}
```

### Examples
```liquid
{{ [1, 2, 3] | size }}
<!-- Output: 3 -->

{{ "hello" | size }}
<!-- Output: 5 -->

{{ [] | size }}
<!-- Output: 0 -->
```

### Aliases
- `length` - Alias for `size`

---

## upper

Converts the input value to uppercase.

### Syntax
```liquid
{{ value | upper }}
```

### Examples
```liquid
{{ "hello" | upper }}
<!-- Output: HELLO -->

{{ "HeLLo" | upper }}
<!-- Output: HELLO -->
```

### Aliases
- `upcase` - Alias for `upper` (from string module)

---

## lower

Converts the input value to lowercase.

### Syntax
```liquid
{{ value | lower }}
```

### Examples
```liquid
{{ "HELLO" | lower }}
<!-- Output: hello -->

{{ "HeLLo" | lower }}
<!-- Output: hello -->
```

### Aliases
- `downcase` - Alias for `lower` (from string module)

---

## reverse

Reverses the order of elements in an array.

### Syntax
```liquid
{{ array | reverse }}
```

### Examples
```liquid
{{ [1, 2, 3] | reverse }}
<!-- Output: [3, 2, 1] -->

{{ ["a", "b", "c"] | reverse }}
<!-- Output: ["c", "b", "a"] -->
```

---

## sort

Sorts the elements of an array in ascending order.

### Syntax
```liquid
{{ array | sort }}
```

### Examples
```liquid
{{ [3, 1, 2] | sort }}
<!-- Output: [1, 2, 3] -->

{{ ["banana", "apple", "cherry"] | sort }}
<!-- Output: ["apple", "banana", "cherry"] -->
```

---

## sort_natural

Sorts an array using natural/human-friendly ordering.

### Syntax
```liquid
{{ array | sort_natural }}
```

### Examples
```liquid
{{ ["item10", "item2", "item1"] | sort_natural }}
<!-- Output: ["item1", "item2", "item10"] -->

{{ ["file1.txt", "file10.txt", "file2.txt"] | sort_natural }}
<!-- Output: ["file1.txt", "file2.txt", "file10.txt"] -->
```

---

## map

Extracts a property value from each object in an array.

### Syntax
```liquid
{{ array | map: property_name }}
```

### Parameters
- **property_name** (required) - The property to extract from each object

### Examples
```liquid
{{ [{"name": "Alice"}, {"name": "Bob"}] | map: "name" }}
<!-- Output: ["Alice", "Bob"] -->

{% assign users = [{"profile": {"age": 25}}, {"profile": {"age": 30}}] %}
{{ users | map: "profile" | map: "age" }}
<!-- Output: [25, 30] -->
```

---

## where

Filters an array of objects based on a property value.

### Syntax
```liquid
{{ array | where: property_name }}
{{ array | where: property_name, expected_value }}
```

### Parameters
- **property_name** (required) - The property to filter by
- **expected_value** (optional) - The value to match (if omitted, filters for truthy values)

### Examples
```liquid
{{ [{"type": "fruit"}, {"type": "vegetable"}] | where: "type", "fruit" }}
<!-- Output: [{"type": "fruit"}] -->

{{ [{"active": true}, {"active": false}, {"active": true}] | where: "active" }}
<!-- Output: [{"active": true}, {"active": true}] -->
```

---

## where_exp

Filters an array of objects based on a Liquid expression.

### Syntax
```liquid
{{ array | where_exp: item_name, expression }}
```

### Parameters
- **item_name** (required) - Variable name for each iteration (e.g., "item")
- **expression** (required) - Liquid expression to evaluate

### Examples
```liquid
{{ products | where_exp: "item", "item.type == 'kitchen'" }}
<!-- Filters products where type equals 'kitchen' -->

{{ users | where_exp: "user", "user.age > 18" }}
<!-- Filters users older than 18 -->

{{ items | where_exp: "item", "item.price < 100 and item.available == true" }}
<!-- Complex filtering with multiple conditions -->
```

### Notes
- More powerful than basic `where` filter
- Supports complex expressions and operators
- Can reference nested properties and use comparisons

---

## reject

Creates an array excluding objects with a given property value.

### Syntax
```liquid
{{ array | reject: property_name }}
{{ array | reject: property_name, expected_value }}
```

### Parameters
- **property_name** (required) - The property to filter by
- **expected_value** (optional) - The value to reject

### Examples
```liquid
{{ [{"type": "fruit"}, {"type": "vegetable"}] | reject: "type", "fruit" }}
<!-- Output: [{"type": "vegetable"}] -->

{{ [{"active": true}, {"active": false}] | reject: "active" }}
<!-- Output: [{"active": false}] -->
```

---

## reject_exp

Creates an array excluding objects that match a Liquid expression.

### Syntax
```liquid
{{ array | reject_exp: item_name, expression }}
```

### Parameters
- **item_name** (required) - Variable name for each iteration
- **expression** (required) - Liquid expression to evaluate

### Examples
```liquid
{{ products | reject_exp: "item", "item.type == 'kitchen'" }}
<!-- Excludes products where type equals 'kitchen' -->

{{ users | reject_exp: "user", "user.active == false" }}
<!-- Excludes inactive users -->
```

### Notes
- Opposite of `where_exp`
- Removes items that match the expression

---

## uniq

Removes duplicate elements from an array.

### Syntax
```liquid
{{ array | uniq }}
```

### Examples
```liquid
{{ [1, 2, 2, 3, 3, 1] | uniq }}
<!-- Output: [1, 2, 3] -->

{{ ["a", "b", "a", "c", "b"] | uniq }}
<!-- Output: ["a", "b", "c"] -->
```

---

## slice

Extracts a subset of an array or string.

### Syntax
```liquid
{{ array | slice: start_index }}
{{ array | slice: start_index, length }}
```

### Parameters
- **start_index** (required) - Starting index (0-based, negative values count from end)
- **length** (optional) - Number of elements to extract (default: 1)

### Examples
```liquid
{{ [1, 2, 3, 4, 5] | slice: 1, 3 }}
<!-- Output: [2, 3, 4] -->

{{ [1, 2, 3, 4, 5] | slice: -2 }}
<!-- Output: [4] -->

{{ "hello" | slice: 1, 3 }}
<!-- Output: ell -->
```

---

## compact

Removes null values from an array.

### Syntax
```liquid
{{ array | compact }}
```

### Examples
```liquid
{{ [1, null, 2, null, 3] | compact }}
<!-- Output: [1, 2, 3] -->

{{ ["a", null, "b", "", "c"] | compact }}
<!-- Output: ["a", "b", "", "c"] -->
```

### Notes
- Only removes `null` values, not empty strings or other falsy values

---

## concat

Concatenates multiple arrays together.

### Syntax
```liquid
{{ array1 | concat: array2 }}
```

### Parameters
- **array2** (required) - The array to concatenate

### Examples
```liquid
{{ [1, 2] | concat: [3, 4] }}
<!-- Output: [1, 2, 3, 4] -->

{{ ["a", "b"] | concat: ["c", "d", "e"] }}
<!-- Output: ["a", "b", "c", "d", "e"] -->
```

---

## push

Adds an element to the end of an array (non-destructive).

### Syntax
```liquid
{{ array | push: element }}
```

### Parameters
- **element** (required) - The element to add

### Examples
```liquid
{{ [1, 2] | push: 3 }}
<!-- Output: [1, 2, 3] -->

{{ ["a", "b"] | push: "c" }}
<!-- Output: ["a", "b", "c"] -->
```

---

## pop

Removes the last element from an array (non-destructive).

### Syntax
```liquid
{{ array | pop }}
```

### Examples
```liquid
{{ [1, 2, 3] | pop }}
<!-- Output: [1, 2] -->

{{ ["a", "b", "c"] | pop }}
<!-- Output: ["a", "b"] -->

{{ [] | pop }}
<!-- Output: [] -->
```

---

## shift

Removes the first element from an array (non-destructive).

### Syntax
```liquid
{{ array | shift }}
```

### Examples
```liquid
{{ [1, 2, 3] | shift }}
<!-- Output: [2, 3] -->

{{ ["a", "b", "c"] | shift }}
<!-- Output: ["b", "c"] -->

{{ [] | shift }}
<!-- Output: [] -->
```

---

## unshift

Adds an element to the beginning of an array (non-destructive).

### Syntax
```liquid
{{ array | unshift: element }}
```

### Parameters
- **element** (required) - The element to add

### Examples
```liquid
{{ [2, 3] | unshift: 1 }}
<!-- Output: [1, 2, 3] -->

{{ ["b", "c"] | unshift: "a" }}
<!-- Output: ["a", "b", "c"] -->
```

---

## find

Finds the first element that matches a property value.

### Syntax
```liquid
{{ array | find: property_name }}
{{ array | find: property_name, expected_value }}
```

### Parameters
- **property_name** (required) - The property to search by
- **expected_value** (optional) - The value to match

### Examples
```liquid
{{ [{"name": "Alice"}, {"name": "Bob"}] | find: "name", "Bob" }}
<!-- Output: {"name": "Bob"} -->

{{ [{"active": false}, {"active": true}] | find: "active" }}
<!-- Output: {"active": true} -->
```

---

## find_exp

Finds the first element that matches a Liquid expression.

### Syntax
```liquid
{{ array | find_exp: item_name, expression }}
```

### Parameters
- **item_name** (required) - Variable name for each iteration
- **expression** (required) - Liquid expression to evaluate

### Examples
```liquid
{{ products | find_exp: "item", "item.type == 'kitchen'" }}
<!-- Returns first product where type equals 'kitchen' -->

{{ users | find_exp: "user", "user.role == 'admin'" }}
<!-- Returns first admin user -->
```

---

## find_index

Finds the index of the first element that matches a property value.

### Syntax
```liquid
{{ array | find_index: property_name }}
{{ array | find_index: property_name, expected_value }}
```

### Parameters
- **property_name** (required) - The property to search by
- **expected_value** (optional) - The value to match

### Examples
```liquid
{{ [{"name": "Alice"}, {"name": "Bob"}] | find_index: "name", "Bob" }}
<!-- Output: 1 -->

{{ [{"active": false}, {"active": true}] | find_index: "active" }}
<!-- Output: 1 -->
```

---

## find_index_exp

Finds the index of the first element that matches a Liquid expression.

### Syntax
```liquid
{{ array | find_index_exp: item_name, expression }}
```

### Parameters
- **item_name** (required) - Variable name for each iteration
- **expression** (required) - Liquid expression to evaluate

### Examples
```liquid
{{ products | find_index_exp: "item", "item.type == 'kitchen'" }}
<!-- Returns index of first kitchen product -->

{{ users | find_index_exp: "user", "user.email == 'admin@example.com'" }}
<!-- Returns index of user with specific email -->
```

---

## sum

Sums numeric values in an array.

### Syntax
```liquid
{{ array | sum }}
{{ array | sum: property_name }}
```

### Parameters
- **property_name** (optional) - Property to sum from objects

### Examples
```liquid
{{ [1, 2, 3, 4] | sum }}
<!-- Output: 10 -->

{{ [{"price": 10}, {"price": 20}, {"price": 5}] | sum: "price" }}
<!-- Output: 35 -->
```

---

## group_by

Groups array elements by a property value.

### Syntax
```liquid
{{ array | group_by: property_name }}
```

### Parameters
- **property_name** (required) - The property to group by

### Examples
```liquid
{{ [{"type": "fruit", "name": "apple"}, {"type": "vegetable", "name": "carrot"}] | group_by: "type" }}
<!-- Output: [
  {"name": "fruit", "items": [{"type": "fruit", "name": "apple"}]},
  {"name": "vegetable", "items": [{"type": "vegetable", "name": "carrot"}]}
] -->
```

---

## group_by_exp

Groups array elements by the result of a Liquid expression.

### Syntax
```liquid
{{ array | group_by_exp: item_name, expression }}
```

### Parameters
- **item_name** (required) - Variable name for each iteration
- **expression** (required) - Liquid expression to evaluate for grouping

### Examples
```liquid
{{ members | group_by_exp: "item", "item.graduation_year" }}
<!-- Groups members by graduation year -->

{{ posts | group_by_exp: "post", "post.date | date: '%Y'" }}
<!-- Groups posts by year using date filter -->

{{ products | group_by_exp: "item", "item.price | divided_by: 100 | floor" }}
<!-- Groups products by price range (hundreds) -->
```

### Notes
- More flexible than basic `group_by`
- Can use filters and complex expressions for grouping
- Result includes calculated group keys

---

## has

Checks if an array contains items with a certain property value.

### Syntax
```liquid
{{ array | has: property_name }}
{{ array | has: property_name, expected_value }}
```

### Parameters
- **property_name** (required) - The property to check
- **expected_value** (optional) - The value to check for

### Examples
```liquid
{{ [{"active": true}, {"active": false}] | has: "active", true }}
<!-- Output: true -->

{{ [{"published": false}] | has: "published" }}
<!-- Output: false -->
```

---

## has_exp

Checks if an array contains items that match a Liquid expression.

### Syntax
```liquid
{{ array | has_exp: item_name, expression }}
```

### Parameters
- **item_name** (required) - Variable name for each iteration
- **expression** (required) - Liquid expression to evaluate

### Examples
```liquid
{{ products | has_exp: "item", "item.active == true" }}
<!-- Returns true if any product is active -->

{{ users | has_exp: "user", "user.age > 65" }}
<!-- Returns true if any user is over 65 -->

{{ orders | has_exp: "order", "order.total > 1000" }}
<!-- Returns true if any order exceeds $1000 -->
```

### Notes
- Returns boolean result
- Useful for conditional logic
- More powerful than basic `has` filter

## Usage Patterns

### Data Processing Pipeline
```liquid
{% assign processed = products 
  | where: "available", true
  | map: "category"
  | uniq
  | sort %}
```

### Complex Filtering with Expressions
```liquid
{% assign featured_products = products
  | where_exp: "item", "item.featured == true and item.price < 100"
  | reject_exp: "item", "item.sold_out == true"
  | sort_natural: "name" %}
```

### Statistical Operations
```liquid
{% assign total_value = orders | sum: "amount" %}
{% assign categories = products | group_by: "category" %}
```

### Array Manipulation
```liquid
{% assign enhanced_list = basic_list
  | push: "new_item"
  | concat: additional_items
  | uniq %}
```

### Searching and Finding
```liquid
{% assign user = users | find: "id", current_user_id %}
{% assign admin_index = users | find_index_exp: "user", "user.role == 'admin'" %}
```

## Performance Tips

1. **Filter early** - Use `where` and `reject` before expensive operations
2. **Cache results** - Store complex operations in variables
3. **Chain efficiently** - Order filters to minimize data processing
4. **Use expression filters for complex logic** - More efficient than multiple simple filters

```liquid
{% assign filtered_products = all_products 
  | where: "published", true 
  | where_exp: "item", "item.price > 0 and item.stock > 0"
  | sort: "price" 
  | slice: 0, 10 %}
```

## Error Handling

Most array filters handle invalid input gracefully:

```liquid
{{ null | size }}           <!-- Output: 0 -->
{{ "" | first }}            <!-- Output: (empty) -->
{{ [1,2,3] | find: "x" }}   <!-- Output: null -->
{{ [] | where_exp: "item", "item.active" }}  <!-- Output: [] -->
```

## Advanced Examples

### Complex Expression Filtering
```liquid
{% assign premium_customers = customers
  | where_exp: "customer", "customer.orders.size > 5 and customer.total_spent > 1000"
  | group_by_exp: "customer", "customer.signup_date | date: '%Y'"
  | sort: "name" %}
```

### Multi-level Processing
```liquid
{% assign top_categories = products
  | group_by: "category"
  | sort: "name"
  | map: "items"
  | map: "size"
  | slice: 0, 3 %}
```

### Dynamic Grouping
```liquid
{% assign quarterly_sales = orders
  | where_exp: "order", "order.status == 'completed'"
  | group_by_exp: "order", "order.date | date: '%Y-Q' | append: order.date | date: '%m' | divided_by: 3 | plus: 1"
  | map: "items"
  | map: "total"
  | sum %}
``` 