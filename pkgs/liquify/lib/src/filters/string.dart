import 'package:liquify/src/filter_registry.dart';
import 'package:liquify/src/filters/module.dart';

/// Appends a string to the end of another string.
///
/// [value]: The original string.
/// [arguments]: A list containing the string to append.
///
/// Example:
/// ```dart
/// append('Hello', [' World']) // Returns: 'Hello World'
/// ```
FilterFunction append =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      if (arguments.isEmpty) throw ArgumentError('append expects 1 argument');
      String str = value.toString();
      String arg = arguments[0].toString();
      return str + arg;
    };

/// Prepends a string to the beginning of another string.
///
/// [value]: The original string.
/// [arguments]: A list containing the string to prepend.
///
/// Example:
/// ```dart
/// prepend('World', ['Hello ']) // Returns: 'Hello World'
/// ```
FilterFunction prepend =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      if (arguments.isEmpty) throw ArgumentError('prepend expects 1 argument');
      String str = value.toString();
      String arg = arguments[0].toString();
      return arg + str;
    };

/// Removes leading characters from a string.
///
/// [value]: The original string.
/// [arguments]: An optional list containing the characters to remove.
///
/// Examples:
/// ```dart
/// lstrip('  Hello', []) // Returns: 'Hello'
/// lstrip('xxHello', ['x']) // Returns: 'Hello'
/// ```
FilterFunction lstrip =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      String str = value.toString();
      if (arguments.isEmpty) {
        return str.trimLeft();
      } else {
        String chars = RegExp.escape(arguments[0].toString());
        return str.replaceFirst(RegExp('^[$chars]+'), '');
      }
    };

/// Converts a string to lowercase.
///
/// [value]: The string to convert.
///
/// Example:
/// ```dart
/// downcase('HELLO') // Returns: 'hello'
/// ```
FilterFunction downcase =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      return value.toString().toLowerCase();
    };

/// Converts a string to uppercase.
///
/// [value]: The string to convert.
///
/// Example:
/// ```dart
/// upcase('hello') // Returns: 'HELLO'
/// ```
FilterFunction upcase =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      return value.toString().toUpperCase();
    };

/// Removes all occurrences of a substring from a string.
///
/// [value]: The original string.
/// [arguments]: A list containing the substring to remove.
///
/// Example:
/// ```dart
/// remove('Hello World', ['o']) // Returns: 'Hell Wrld'
/// ```
FilterFunction remove =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      if (arguments.isEmpty) throw ArgumentError('remove expects 1 argument');
      String str = value.toString();
      String arg = arguments[0].toString();
      return str.replaceAll(arg, '');
    };

/// Removes the first occurrence of a substring from a string.
///
/// [value]: The original string.
/// [arguments]: A list containing the substring to remove.
///
/// Example:
/// ```dart
/// removeFirst('Hello Hello World', ['Hello ']) // Returns: 'Hello World'
/// ```
FilterFunction removeFirst =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      if (arguments.isEmpty) {
        throw ArgumentError('remove_first expects 1 argument');
      }
      String str = value.toString();
      String arg = arguments[0].toString();
      return str.replaceFirst(arg, '');
    };

/// Removes the last occurrence of a substring from a string.
///
/// [value]: The original string.
/// [arguments]: A list containing the substring to remove.
///
/// Example:
/// ```dart
/// removeLast('Hello Hello World', ['Hello ']) // Returns: 'Hello World'
/// ```
FilterFunction removeLast =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      if (arguments.isEmpty) {
        throw ArgumentError('remove_last expects 1 argument');
      }
      String str = value.toString();
      String arg = arguments[0].toString();
      int index = str.lastIndexOf(arg);
      if (index == -1) return str;
      return str.substring(0, index) + str.substring(index + arg.length);
    };

/// Removes trailing characters from a string.
///
/// [value]: The original string.
/// [arguments]: An optional list containing the characters to remove.
///
/// Examples:
/// ```dart
/// rstrip('Hello  ', []) // Returns: 'Hello'
/// rstrip('Helloxx', ['x']) // Returns: 'Hello'
/// ```
FilterFunction rstrip =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      String str = value.toString();
      if (arguments.isEmpty) {
        return str.trimRight();
      } else {
        String chars = RegExp.escape(arguments[0].toString());
        return str.replaceFirst(RegExp('[$chars]+\$'), '');
      }
    };

/// Splits a string into an array of substrings.
///
/// [value]: The string to split.
/// [arguments]: A list containing the delimiter.
///
/// Example:
/// ```dart
/// split('Hello World', [' ']) // Returns: ['Hello', 'World']
/// ```
FilterFunction split =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      if (arguments.isEmpty) throw ArgumentError('split expects 1 argument');
      String str = value.toString();
      String delimiter = arguments[0].toString();
      List<String> result = str.split(delimiter);
      while (result.isNotEmpty && result.last.isEmpty) {
        result.removeLast();
      }
      return result;
    };

/// Removes leading and trailing characters from a string.
///
/// [value]: The original string.
/// [arguments]: An optional list containing the characters to remove.
///
/// Examples:
/// ```dart
/// strip('  Hello  ', []) // Returns: 'Hello'
/// strip('xxHelloxx', ['x']) // Returns: 'Hello'
/// ```
FilterFunction strip =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      String str = value.toString();
      if (arguments.isEmpty) {
        return str.trim();
      } else {
        String chars = RegExp.escape(arguments[0].toString());
        return str
            .replaceFirst(RegExp('^[$chars]+'), '')
            .replaceFirst(RegExp('[$chars]+\$'), '');
      }
    };

/// Removes all newline characters from a string.
///
/// [value]: The string to process.
///
/// Example:
/// ```dart
/// stripNewlines('Hello\nWorld') // Returns: 'HelloWorld'
/// ```
FilterFunction stripNewlines =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      return value.toString().replaceAll(RegExp(r'\r?\n'), '');
    };

/// Capitalizes the first character of a string and lowercases the rest.
///
/// [value]: The string to capitalize.
///
/// Example:
/// ```dart
/// capitalize('hello WORLD') // Returns: 'Hello world'
/// ```
FilterFunction capitalize =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      String str = value.toString();
      if (str.isEmpty) return str;
      return str[0].toUpperCase() + str.substring(1).toLowerCase();
    };

/// Replaces all occurrences of a substring with another substring.
///
/// [value]: The original string.
/// [arguments]: A list containing the substring to replace and the replacement.
///
/// Example:
/// ```dart
/// replace('Hello World', ['o', 'a']) // Returns: 'Hella Warld'
/// ```
FilterFunction replace =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      if (arguments.length < 2) {
        throw ArgumentError('replace expects 2 arguments');
      }
      String str = value.toString();
      String pattern = arguments[0].toString();
      String replacement = arguments[1].toString();
      return str.replaceAll(pattern, replacement);
    };

/// Replaces the first occurrence of a substring with another substring.
///
/// [value]: The original string.
/// [arguments]: A list containing the substring to replace and the replacement.
///
/// Example:
/// ```dart
/// replaceFirst('Hello Hello World', ['Hello', 'Hi']) // Returns: 'Hi Hello World'
/// ```
FilterFunction replaceFirst =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      if (arguments.length < 2) {
        throw ArgumentError('replace_first expects 2 arguments');
      }
      String str = value.toString();
      String pattern = arguments[0].toString();
      String replacement = arguments[1].toString();
      return str.replaceFirst(pattern, replacement);
    };

/// Replaces the last occurrence of a substring with another substring.
///
/// [value]: The original string.
/// [arguments]: A list containing the substring to replace and the replacement.
///
/// Example:
/// ```dart
/// replaceLast('Hello Hello World', ['Hello', 'Hi']) // Returns: 'Hello Hi World'
/// ```
FilterFunction replaceLast =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      if (arguments.length < 2) {
        throw ArgumentError('replace_last expects 2 arguments');
      }
      String str = value.toString();
      String pattern = arguments[0].toString();
      String replacement = arguments[1].toString();
      int index = str.lastIndexOf(pattern);
      if (index == -1) return str;
      return str.substring(0, index) +
          replacement +
          str.substring(index + pattern.length);
    };

/// Truncates a string to a specified length.
///
/// [value]: The string to truncate.
/// [arguments]: A list containing the length and optional ellipsis.
///
/// Examples:
/// ```dart
/// truncate('Hello World', [5]) // Returns: 'He...'
/// truncate('Hello World', [5, '---']) // Returns: 'He---'
/// ```
FilterFunction truncate =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      String str = value.toString();
      int length = arguments.isNotEmpty ? arguments[0] as int : 50;
      String ellipsis = arguments.length > 1 ? arguments[1].toString() : '...';
      if (str.length <= length) return str;
      return str.substring(0, length - ellipsis.length) + ellipsis;
    };

/// Truncates a string to a specified number of words.
///
/// [value]: The string to truncate.
/// [arguments]: A list containing the number of words and optional ellipsis.
///
/// Examples:
/// ```dart
/// truncatewords('Hello World Foo Bar', [2]) // Returns: 'Hello World...'
/// truncatewords('Hello World Foo Bar', [2, '---']) // Returns: 'Hello World---'
/// ```
FilterFunction truncatewords =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      String str = value.toString();
      int words = arguments.isNotEmpty ? arguments[0] as int : 15;
      String ellipsis = arguments.length > 1 ? arguments[1].toString() : '...';
      List<String> wordList = str.split(RegExp(r'\s+'));
      if (words <= 0) words = 1;
      if (wordList.length <= words) return str;
      return wordList.take(words).join(' ') + ellipsis;
    };

/// Normalizes whitespace in a string, replacing multiple spaces with a single space.
///
/// [value]: The string to normalize.
///
/// Example:
/// ```dart
/// normalizeWhitespace('Hello   World') // Returns: 'Hello World'
/// ```
FilterFunction normalizeWhitespace =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      return value.toString().replaceAll(RegExp(r'\s+'), ' ');
    };

/// Counts the number of words in a string.
///
/// [value]: The string to count words in.
/// [arguments]: An optional list containing the counting mode ('cjk' or 'auto').
///
/// Examples:
/// ```dart
/// numberOfWords('Hello World') // Returns: 2
/// numberOfWords('你好世界', ['cjk']) // Returns: 4
/// numberOfWords('Hello 世界', ['auto']) // Returns: 3
/// ```
FilterFunction numberOfWords =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      String str = value.toString().trim();
      if (str.isEmpty) return 0;
      String mode = arguments.isNotEmpty ? arguments[0].toString() : '';

      RegExp rCJKWord = RegExp(
        r'[\u4E00-\u9FFF\uF900-\uFAFF\u3400-\u4DBF\u3040-\u309F\u30A0-\u30FF\uAC00-\uD7AF]',
        unicode: true,
      );
      RegExp rNonCJKWord = RegExp(
        r'[^\u4E00-\u9FFF\uF900-\uFAFF\u3400-\u4DBF\u3040-\u309F\u30A0-\u30FF\uAC00-\uD7AF\s]+',
        unicode: true,
      );

      switch (mode) {
        case 'cjk':
          return rCJKWord.allMatches(str).length +
              rNonCJKWord.allMatches(str).length;
        case 'auto':
          return rCJKWord.hasMatch(str)
              ? rCJKWord.allMatches(str).length +
                    rNonCJKWord.allMatches(str).length
              : str.split(RegExp(r'\s+')).length;
        default:
          return str.split(RegExp(r'\s+')).length;
      }
    };

/// Converts an array to a sentence string.
///
/// [value]: The array to convert.
/// [arguments]: An optional list containing the connector word (default: 'and').
///
/// Examples:
/// ```dart
/// arrayToSentenceString(['apple', 'banana', 'orange']) // Returns: 'apple, banana, and orange'
/// arrayToSentenceString(['apple', 'banana'], ['or']) // Returns: 'apple or banana'
/// ```
FilterFunction arrayToSentenceString =
    (
      dynamic value,
      List<dynamic> arguments,
      Map<String, dynamic> namedArguments,
    ) {
      if (value is! List) throw ArgumentError('Input must be a List');
      String connector = arguments.isNotEmpty ? arguments[0].toString() : 'and';

      switch (value.length) {
        case 0:
          return '';
        case 1:
          return value[0].toString();
        case 2:
          return '${value[0]} $connector ${value[1]}';
        default:
          return '${value.sublist(0, value.length - 1).join(', ')}, $connector ${value.last}';
      }
    };

class StringModule extends Module {
  @override
  void register() {
    filters['append'] = append;
    filters['prepend'] = prepend;
    filters['lstrip'] = lstrip;
    filters['downcase'] = downcase;
    filters['upcase'] = upcase;
    filters['remove'] = remove;
    filters['remove_first'] = removeFirst;
    filters['remove_last'] = removeLast;
    filters['rstrip'] = rstrip;
    filters['split'] = split;
    filters['strip'] = strip;
    filters['strip_newlines'] = stripNewlines;
    filters['capitalize'] = capitalize;
    filters['replace'] = replace;
    filters['replace_first'] = replaceFirst;
    filters['replace_last'] = replaceLast;
    filters['truncate'] = truncate;
    filters['truncatewords'] = truncatewords;
    filters['normalize_whitespace'] = normalizeWhitespace;
    filters['number_of_words'] = numberOfWords;
    filters['array_to_sentence_string'] = arrayToSentenceString;
  }
}
