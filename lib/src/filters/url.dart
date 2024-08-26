import 'package:liquify/src/filter_registry.dart';
import 'package:liquify/src/filters/module.dart';

/// Converts any value to a string, returning an empty string for null values.
///
/// @param x The value to stringify.
/// @return A string representation of the input value.
String stringify(dynamic x) {
  return x?.toString() ?? '';
}

/// Decodes a URL-encoded string.
///
/// Usage: {{ value | url_decode }}
///
/// @param value The URL-encoded string to decode.
/// @return The decoded string.
///
/// Example:
/// Input: "hello%20world"
/// Output: "hello world"
FilterFunction urlDecode = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  return Uri.decodeComponent(stringify(value)).replaceAll('+', ' ');
};

/// Encodes a string for use in a URL.
///
/// Usage: {{ value | url_encode }}
///
/// @param value The string to encode.
/// @return The URL-encoded string.
///
/// Example:
/// Input: "hello world"
/// Output: "hello+world"
FilterFunction urlEncode = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  return Uri.encodeComponent(stringify(value)).replaceAll('%20', '+');
};

/// Escapes a string using CGI escape characters.
///
/// Usage: {{ value | cgi_escape }}
///
/// @param value The string to escape.
/// @return The CGI-escaped string.
///
/// Example:
/// Input: "hello world!"
/// Output: "hello+world%21"
FilterFunction cgiEscape = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  return Uri.encodeComponent(stringify(value))
      .replaceAll('%20', '+')
      .replaceAllMapped(RegExp(r"[!'()*]"), (match) {
    return '%${match.group(0)!.codeUnitAt(0).toRadixString(16).toUpperCase()}';
  });
};

/// Escapes a string for use in a URI.
///
/// Usage: {{ value | uri_escape }}
///
/// @param value The string to escape.
/// @return The URI-escaped string.
///
/// Example:
/// Input: "hello world[]"
/// Output: "hello%20world[]"
FilterFunction uriEscape = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  return Uri.encodeFull(stringify(value))
      .replaceAll('%5B', '[')
      .replaceAll('%5D', ']');
};

/// Enum representing different modes for the slugify filter.
enum SlugifyMode { raw, defaultMode, pretty, ascii, latin, none }

/// Converts a string into a URL slug.
///
/// Usage: {{ value | slugify: [mode], [cased] }}
///
/// @param value The string to convert to a slug.
/// @param arguments A list containing optional arguments:
///   - mode (String): Slugify mode ('raw', 'pretty', 'ascii', 'latin', 'none', default: 'default')
///   - cased (bool): If true, preserves case (default: false)
/// @return The slugified string.
///
/// Examples:
/// {{ "Hello World!" | slugify }}                 => "hello-world"
/// {{ "Hello World!" | slugify: 'pretty' }}       => "hello-world"
/// {{ "Hello World!" | slugify: 'raw' }}          => "hello-world!"
/// {{ "Héllö Wörld!" | slugify: 'ascii' }}        => "hello-world"
/// {{ "Héllö Wörld!" | slugify: 'latin' }}        => "hello-world"
/// {{ "Hello World!" | slugify: 'default', true }} => "Hello-World"
FilterFunction slugify = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  String mode = arguments.isNotEmpty ? arguments[0] as String : 'default';
  bool cased = arguments.length > 1 ? arguments[1] as bool : false;

  String str = stringify(value);

  RegExp spacesReplacer = RegExp(r'\s+');

  switch (mode) {
    case 'none':
      // Do nothing
      return str;
    case 'raw':
      // Replace spaces with a single hyphen, preserve other characters
      str = str.trim().replaceAll(spacesReplacer, '-');
      break;
    case 'pretty':
      // Preserve certain characters, replace spaces with hyphens
      str = str
          .replaceAll(RegExp(r'[^\w\s._~!$&' '()+,;=@-]'), '')
          .trim()
          .replaceAll(spacesReplacer, '-');
      break;
    case 'ascii':
      // Remove non-ASCII characters, replace spaces with hyphens
      str = str
          .replaceAll(RegExp(r'[^\x00-\x7F]+'), '') // Remove non-ASCII
          .replaceAll(
              RegExp(r'[^\w\s-]'), '') // Remove non-alphanumeric except hyphen
          .trim()
          .replaceAll(spacesReplacer, '-');
      break;
    case 'latin':
      // Transliterate Latin characters, then process like default
      str = removeAccents(str);
      // Process like default case
      str = str
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .trim()
          .replaceAll(spacesReplacer, '-');
      break;
    case 'default':
    default:
      // Remove non-word characters (except hyphens), replace spaces with hyphens
      str = str
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .trim()
          .replaceAll(spacesReplacer, '-');
      break;
  }

  // Apply lowercase for all modes except 'none', unless cased is true
  if (mode != 'none' && !cased) {
    str = str.toLowerCase();
  }

  return str;
};

/// Removes accents from Latin characters.
///
/// @param str The string containing accented characters.
/// @return The string with accents removed.
String removeAccents(String str) {
  return str
      .replaceAllMapped(RegExp(r'[àáâãäå]'), (match) => 'a')
      .replaceAll('æ', 'ae')
      .replaceAll('ç', 'c')
      .replaceAllMapped(RegExp(r'[èéêë]'), (match) => 'e')
      .replaceAllMapped(RegExp(r'[ìíîï]'), (match) => 'i')
      .replaceAll('ð', 'd')
      .replaceAll('ñ', 'n')
      .replaceAllMapped(RegExp(r'[òóôõöø]'), (match) => 'o')
      .replaceAllMapped(RegExp(r'[ùúûü]'), (match) => 'u')
      .replaceAllMapped(RegExp(r'[ýÿ]'), (match) => 'y')
      .replaceAll('ß', 'ss')
      .replaceAll('œ', 'oe')
      .replaceAll('þ', 'th')
      .replaceAll('ẞ', 'SS')
      .replaceAll('Œ', 'OE')
      .replaceAll('Þ', 'TH');
}

class UrlModule extends Module {
  @override
  void register() {
    filters['url_decode'] = urlDecode;
    filters['url_encode'] = urlEncode;
    filters['cgi_escape'] = cgiEscape;
    filters['uri_escape'] = uriEscape;
    filters['slugify'] = slugify;
  }
}
