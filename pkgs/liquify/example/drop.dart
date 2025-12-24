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
