import 'package:liquify/src/filter_registry.dart';

final Map<String, String> _escapeMap = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&#34;',
  "'": '&#39;',
};

final Map<String, String> _unescapeMap = {
  '&amp;': '&',
  '&lt;': '<',
  '&gt;': '>',
  '&#34;': '"',
  '&#39;': "'",
};

String _stringify(dynamic value) => value?.toString() ?? '';

/// Escapes HTML special characters in a string.
///
/// Usage: {{ value | escape }}
///
/// Example:
/// Input: {{ "<p>Hello & welcome</p>" | escape }}
/// Output: &lt;p&gt;Hello &amp; welcome&lt;/p&gt;
FilterFunction escape = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  final str = _stringify(value);
  return str.replaceAllMapped(
    RegExp('[&<>"\']'),
    (Match match) => _escapeMap[match.group(0)] ?? '',
  );
};

/// Alias for the `escape` filter.
///
/// Usage: {{ value | xml_escape }}
///
/// Example:
/// Input: {{ "<p>Hello & welcome</p>" | xml_escape }}
/// Output: &lt;p&gt;Hello &amp; welcome&lt;/p&gt;
FilterFunction xmlEscape = escape;

/// Unescapes HTML entities in a string.
///
/// Usage: {{ value | unescape }}
///
/// Example:
/// Input: {{ "&lt;p&gt;Hello &amp; welcome&lt;/p&gt;" | unescape }}
/// Output: <p>Hello & welcome</p>
FilterFunction unescape = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  final str = _stringify(value);
  // TODO: Implement memory limit check if needed
  return str.replaceAllMapped(
    RegExp(r'&(amp|lt|gt|#34|#39);'),
    (Match m) => _unescapeMap[m.group(0)] ?? m.group(0)!,
  );
};

/// Escapes HTML special characters in a string, but doesn't re-escape entities.
///
/// Usage: {{ value | escape_once }}
///
/// Example:
/// Input: {{ "&lt;p&gt;Hello &amp; welcome&lt;/p&gt;" | escape_once }}
/// Output: &lt;p&gt;Hello &amp; welcome&lt;/p&gt;
FilterFunction escapeOnce = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  final unescaped = unescape(value, arguments, namedArguments);
  return escape(unescaped, arguments, namedArguments);
};

/// Converts newlines to HTML line breaks.
///
/// Usage: {{ value | newline_to_br }}
///
/// Example:
/// Input: {{ "Hello\nWorld" | newline_to_br }}
/// Output: Hello<br />\nWorld
FilterFunction newlineToBr = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  final str = _stringify(value);
  // TODO: Implement memory limit check if needed
  return str.replaceAll(RegExp(r'\r?\n'), '<br />\n');
};

/// Strips all HTML tags from a string.
///
/// Usage: {{ value | strip_html }}
///
/// Example:
/// Input: {{ "<p>Hello <b>World</b></p>" | strip_html }}
/// Output: Hello World
FilterFunction stripHtml = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  final str = _stringify(value);
  // TODO: Implement memory limit check if needed
  return str.replaceAll(
    RegExp(
        r'<script[\s\S]*?<\/script>|<style[\s\S]*?<\/style>|<.*?>|<!--[\s\S]*?-->'),
    '',
  );
};

/// Strips all newlines from a string.
///
/// Usage: {{ value | strip_newlines }}
///
/// Example:
/// Input: {{ "Hello\nWorld" | strip_newlines }}
/// Output: HelloWorld
FilterFunction stripNewlines = (dynamic value, List<dynamic> arguments,
    Map<String, dynamic> namedArguments) {
  final str = _stringify(value);
  return str.replaceAll(RegExp(r'\r?\n'), '');
};

/// Map of HTML filter names to their corresponding functions.
final Map<String, FilterFunction> filters = {
  'escape': escape,
  'xml_escape': xmlEscape,
  'unescape': unescape,
  'escape_once': escapeOnce,
  'newline_to_br': newlineToBr,
  'strip_html': stripHtml,
  'strip_newlines': stripNewlines,
};
