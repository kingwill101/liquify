# Drop Objects Examples

This document demonstrates how to create custom object models that integrate seamlessly with Liquid templates using the Drop pattern.

## Overview

The drop objects example showcases:
- Custom object model creation
- Property access patterns
- Method invocation from templates
- Nested object hierarchies
- Custom filter integration

## Complete Example Code

```dart
import 'package:liquify/liquify.dart';

void main() {
  // Create an instance of ProductDrop
  final product = ProductDrop(
    name: 'Smartphone',
    price: 599.99,
    manufacturer: ManufacturerDrop(
      name: 'TechCorp',
      country: 'Japan',
    ),
  );

  FilterRegistry.register('discounted_price', (input, args, namedArgs) {
    if (input is! num || args.isEmpty || args[0] is! num) {
      return input;
    }

    num price = input;
    num discountPercentage = args[0];

    if (discountPercentage < 0 || discountPercentage > 100) {
      return price;
    }

    return price - (price * discountPercentage / 100);
  });

  // Define and render templates
  final templates = [
    '{{ product.name }} costs \${{ product.price }}',
    'Manufacturer: {{ product.manufacturer.name }}',
    'Country of origin: {{ product.manufacturer.country }}',
    'Discounted price: {{ product.price | discounted_price: 10 }}',
    'Is expensive? {{ product.is_expensive }}',
  ];

  for (final template in templates) {
    final result = Template.parse(
      template,
      data: {
        'product': product,
      },
    );
    print(result.render());
  }
}
```

## Product Drop Implementation

### Complete Product Class

```dart
class ProductDrop extends Drop {
  final String name;
  final double price;
  final ManufacturerDrop manufacturer;

  ProductDrop({
    required this.name,
    required this.price,
    required this.manufacturer,
  });

  @override
  Map<String, dynamic> get attrs => {
        'name': name,
        'price': price,
        'manufacturer': manufacturer,
      };

  @override
  List<Symbol> get invokable => [
        ...super.invokable,
        #is_expensive,
      ];

  @override
  invoke(Symbol symbol, [List<dynamic>? args]) {
    switch (symbol) {
      case #is_expensive:
        return price > 500 ? 'Yes' : 'No';
      default:
        return liquidMethodMissing(symbol);
    }
  }
}
```

### Key Features

#### Drop Base Class
```dart
class ProductDrop extends Drop
```
- Extends the Liquid `Drop` base class
- Provides template integration capabilities
- Enables property and method access from templates

#### Property Mapping
```dart
@override
Map<String, dynamic> get attrs => {
  'name': name,
  'price': price,
  'manufacturer': manufacturer,
};
```
- Maps object properties to template-accessible names
- Returns a map of property names to values
- Supports nested objects and complex data types

#### Method Invocation
```dart
@override
List<Symbol> get invokable => [
  ...super.invokable,
  #is_expensive,
];

@override
invoke(Symbol symbol, [List<dynamic>? args]) {
  switch (symbol) {
    case #is_expensive:
      return price > 500 ? 'Yes' : 'No';
    default:
      return liquidMethodMissing(symbol);
  }
}
```
- Declares callable methods from templates
- Implements method logic with optional parameters
- Provides fallback for undefined methods

## Manufacturer Drop Implementation

### Complete Manufacturer Class

```dart
class ManufacturerDrop extends Drop {
  final String name;
  final String country;

  ManufacturerDrop({
    required this.name,
    required this.country,
  });

  @override
  Map<String, dynamic> get attrs => {
        'name': name,
        'country': country,
      };
}
```

### Features Demonstrated

#### Simple Drop Pattern
- Minimal implementation for basic property access
- No custom methods, just property mapping
- Demonstrates nested object relationships

#### Nested Object Access
```liquid
{{ product.manufacturer.name }}
{{ product.manufacturer.country }}
```
- Allows deep property access through object hierarchies
- Maintains type safety and encapsulation

## Template Usage Examples

### Property Access

```liquid
{{ product.name }} costs ${{ product.price }}
```
**Output:** `Smartphone costs $599.99`

- Direct property access using dot notation
- Automatic type conversion for template output

### Nested Property Access

```liquid
Manufacturer: {{ product.manufacturer.name }}
Country of origin: {{ product.manufacturer.country }}
```
**Output:** 
```
Manufacturer: TechCorp
Country of origin: Japan
```

- Navigates nested object relationships
- Accesses properties of embedded Drop objects

### Method Invocation

```liquid
Is expensive? {{ product.is_expensive }}
```
**Output:** `Is expensive? Yes`

- Calls custom methods defined in the Drop class
- Returns computed values based on object state

### Filter Integration

```liquid
Discounted price: {{ product.price | discounted_price: 10 }}
```
**Output:** `Discounted price: 539.991`

- Combines Drop properties with custom filters
- Enables complex data transformations

## Custom Filter Implementation

```dart
FilterRegistry.register('discounted_price', (input, args, namedArgs) {
  if (input is! num || args.isEmpty || args[0] is! num) {
    return input;
  }

  num price = input;
  num discountPercentage = args[0];

  if (discountPercentage < 0 || discountPercentage > 100) {
    return price;
  }

  return price - (price * discountPercentage / 100);
});
```

### Features

- **Type Validation**: Ensures input is numeric
- **Parameter Validation**: Checks for valid discount percentage
- **Error Handling**: Returns original value for invalid input
- **Business Logic**: Implements discount calculation

## Complete Expected Output

```
Smartphone costs $599.99
Manufacturer: TechCorp
Country of origin: Japan
Discounted price: 539.991
Is expensive? Yes
```

## Advanced Drop Patterns

### Dynamic Property Access

```dart
@override
Map<String, dynamic> get attrs {
  final baseAttrs = {
    'name': name,
    'price': price,
    'manufacturer': manufacturer,
  };
  
  // Add computed properties
  baseAttrs['display_price'] = '\$${price.toStringAsFixed(2)}';
  baseAttrs['short_name'] = name.length > 20 ? '${name.substring(0, 17)}...' : name;
  
  return baseAttrs;
}
```

### Parameterized Methods

```dart
@override
List<Symbol> get invokable => [
  ...super.invokable,
  #is_expensive,
  #discount,
  #compare_price,
];

@override
invoke(Symbol symbol, [List<dynamic>? args]) {
  switch (symbol) {
    case #is_expensive:
      final threshold = args?.isNotEmpty == true ? args![0] as num : 500;
      return price > threshold ? 'Yes' : 'No';
    
    case #discount:
      final percentage = args?.isNotEmpty == true ? args![0] as num : 10;
      return price * (1 - percentage / 100);
    
    case #compare_price:
      final other = args?.isNotEmpty == true ? args![0] as num : 0;
      return price > other ? 'Higher' : price < other ? 'Lower' : 'Same';
    
    default:
      return liquidMethodMissing(symbol);
  }
}
```

### Collection Drop Objects

```dart
class ProductCatalogDrop extends Drop {
  final List<ProductDrop> products;
  
  ProductCatalogDrop(this.products);
  
  @override
  Map<String, dynamic> get attrs => {
    'products': products,
    'count': products.length,
    'total_value': products.fold<double>(0, (sum, p) => sum + p.price),
  };
  
  @override
  List<Symbol> get invokable => [
    ...super.invokable,
    #expensive_products,
    #by_manufacturer,
  ];
  
  @override
  invoke(Symbol symbol, [List<dynamic>? args]) {
    switch (symbol) {
      case #expensive_products:
        final threshold = args?.isNotEmpty == true ? args![0] as num : 500;
        return products.where((p) => p.price > threshold).toList();
      
      case #by_manufacturer:
        final manufacturer = args?.isNotEmpty == true ? args![0] as String : '';
        return products.where((p) => p.manufacturer.name == manufacturer).toList();
      
      default:
        return liquidMethodMissing(symbol);
    }
  }
}
```

## Template Usage with Collections

```liquid
{% assign catalog = products_catalog %}
Total products: {{ catalog.count }}
Total value: ${{ catalog.total_value }}

Expensive products:
{% assign expensive = catalog.expensive_products: 800 %}
{% for product in expensive %}
  - {{ product.name }}: ${{ product.price }}
{% endfor %}

TechCorp products:
{% assign techcorp = catalog.by_manufacturer: "TechCorp" %}
{% for product in techcorp %}
  - {{ product.name }}
{% endfor %}
```

## Error Handling in Drops

### Property Access Errors

```dart
@override
Map<String, dynamic> get attrs {
  try {
    return {
      'name': name,
      'price': price,
      'manufacturer': manufacturer,
    };
  } catch (e) {
    return {
      'name': 'Error loading product',
      'price': 0,
      'manufacturer': null,
    };
  }
}
```

### Method Invocation Errors

```dart
@override
invoke(Symbol symbol, [List<dynamic>? args]) {
  try {
    switch (symbol) {
      case #is_expensive:
        return price > 500 ? 'Yes' : 'No';
      default:
        return liquidMethodMissing(symbol);
    }
  } catch (e) {
    return 'Error: ${e.toString()}';
  }
}
```

## Performance Considerations

### Lazy Property Computation

```dart
Map<String, dynamic>? _cachedAttrs;

@override
Map<String, dynamic> get attrs {
  _cachedAttrs ??= {
    'name': name,
    'expensive_calculation': _computeExpensiveValue(),
    'manufacturer': manufacturer,
  };
  return _cachedAttrs!;
}
```

### Method Caching

```dart
final Map<Symbol, dynamic> _methodCache = {};

@override
invoke(Symbol symbol, [List<dynamic>? args]) {
  final cacheKey = symbol;
  if (_methodCache.containsKey(cacheKey)) {
    return _methodCache[cacheKey];
  }
  
  final result = _computeMethod(symbol, args);
  _methodCache[cacheKey] = result;
  return result;
}
```

## Testing Drop Objects

```dart
void testProductDrop() {
  final product = ProductDrop(
    name: 'Test Product',
    price: 100.0,
    manufacturer: ManufacturerDrop(name: 'Test Corp', country: 'USA'),
  );
  
  // Test property access
  assert(product.attrs['name'] == 'Test Product');
  assert(product.attrs['price'] == 100.0);
  
  // Test method invocation
  assert(product.invoke(#is_expensive) == 'No');
  
  // Test template integration
  final template = '{{ product.name }}: {{ product.is_expensive }}';
  final result = Template.parse(template, data: {'product': product}).render();
  assert(result == 'Test Product: No');
}
```

## Related Examples

- [Basic Usage](basic-usage.md) - Template fundamentals
- [Custom Tags](custom-tags.md) - Custom tag development
- [File System Integration](file-system.md) - Template loading

## Best Practices

1. **Extend Drop**: Always extend the Drop base class
2. **Implement attrs**: Provide property mapping for template access
3. **Declare invokable**: List all callable methods explicitly
4. **Handle Missing**: Use liquidMethodMissing for undefined methods
5. **Type Safety**: Validate parameters in method implementations
6. **Error Handling**: Gracefully handle errors in properties and methods
7. **Performance**: Cache expensive computations when possible 