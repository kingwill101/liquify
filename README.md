# Liquify

<p align="center">
  <img src="pkgs/liquify/assets/logo.png" alt="Liquify Logo" width="200">
</p>

[![GitHub release](https://img.shields.io/github/release/kingwill101/liquify?include_prereleases=&sort=semver&color=blue)](https://github.com/kingwill101/liquify/releases/)
[![Pub Version](https://img.shields.io/pub/v/liquify)](https://pub.dev/packages/liquify)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/kingwill101/liquify/.github%2Fworkflows%2Fdart.yml)
[![License](https://img.shields.io/badge/License-MIT-blue)](#license)
[![issues - liquify](https://img.shields.io/github/issues/kingwill101/liquify)](https://github.com/kingwill101/liquify/issues)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow?logo=buy-me-a-coffee)](https://www.buymeacoffee.com/kingwill101)

A comprehensive Dart implementation of the [Liquid](https://shopify.github.io/liquid/) template language, originally created by Shopify.

## Packages

This is a monorepo containing the following packages:

| Package | Description | Pub |
|---------|-------------|-----|
| [liquify](pkgs/liquify/) | Core Liquid template engine for Dart | [![Pub Version](https://img.shields.io/pub/v/liquify)](https://pub.dev/packages/liquify) |

## Features

- ✅ Full support for standard Liquid syntax and semantics
- ✅ Synchronous and asynchronous rendering
- 🔒 Environment-scoped filters and tags for security and isolation
- 🛡️ Strict mode for security sandboxing
- ⚡ Template-level customization via environment setup callbacks
- 🔧 Extensible architecture for custom tags and filters
- 🚀 High-performance parsing and rendering
- 📁 File system abstraction for template resolution
- 🎨 Layout and block inheritance support

## Quick Start

Add Liquify to your `pubspec.yaml`:

```yaml
dependencies:
  liquify: ^1.4.3
```

Basic usage:

```dart
import 'package:liquify/liquify.dart';

void main() async {
  final template = Template.parse(
    'Hello, {{ name | upcase }}!',
    data: {'name': 'World'},
  );
  
  print(template.render()); // Hello, WORLD!
}
```

For more examples and detailed documentation, see the [liquify package README](pkgs/liquify/README.md).

## Documentation

- [Package Documentation](pkgs/liquify/README.md)
- [API Reference](https://pub.dev/documentation/liquify/latest/)
- [Examples](pkgs/liquify/example/)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the [MIT License](pkgs/liquify/LICENSE).

## Acknowledgements

- Shopify for the original Liquid template language
- The Dart team for the excellent language and tools
- [LiquidJS](https://github.com/harttle/liquidjs) for their comprehensive set of filters
- [liquid_dart](https://github.com/ergonlabs/liquid_dart) for their initial Dart implementation

