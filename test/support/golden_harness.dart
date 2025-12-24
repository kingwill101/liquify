import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:test/test.dart' as t;

export 'package:test/test.dart' hide expect, group, test;

final _goldenRecorder = _GoldenRecorder();

@isTestGroup
void group(String description, void Function() body,
    {String? skip, t.Timeout? timeout, dynamic tags}) {
  final parent = _groupStack;
  t.group(
    description,
    () => runZoned(body, zoneValues: {
      _goldenGroupKey: [...parent, description]
    }),
    skip: skip,
    timeout: timeout,
    tags: tags,
  );
}

@isTest
void test(String description, dynamic Function() body,
    {String? skip, t.Timeout? timeout, dynamic tags, int? retry}) {
  final fullName = _fullTestName(description);
  final scopedName = _goldenRecorder.scopedTestName(
    fullName,
    StackTrace.current,
  );
  t.test(
    description,
    () => runZoned(
      body,
      zoneValues: {_goldenContextKey: _GoldenContext(scopedName)},
    ),
    skip: skip,
    timeout: timeout,
    tags: tags,
    retry: retry,
  );
}

void expect(Object? actual, Object? matcher, {String? reason, dynamic skip}) {
  _goldenRecorder.record(actual, matcher, StackTrace.current);
  t.expect(actual, matcher, reason: reason, skip: skip);
}

List<String> get _groupStack =>
    (Zone.current[_goldenGroupKey] as List<String>?) ?? const <String>[];

String _fullTestName(String description) {
  final groups = _groupStack;
  if (groups.isEmpty) {
    return description;
  }
  return [...groups, description].join(' ');
}

const _goldenGroupKey = #golden.group;
const _goldenContextKey = #golden.context;

class _GoldenContext {
  _GoldenContext(this.name);

  final String name;
  int index = 0;
  final Map<String, int> locationCounts = {};
}

class _GoldenRecorder {
  final Directory _dir = Directory('test/goldens');
  final bool _update = Platform.environment['UPDATE_GOLDENS'] == '1';

  void record(Object? actual, Object? matcher, StackTrace trace) {
    final context = Zone.current[_goldenContextKey] as _GoldenContext?;
    if (context == null) {
      return;
    }

    final normalized = _normalize(actual, matcher);
    final content = _serialize(normalized);
    final index = context.index++;
    final location = _locationKey(trace);
    final occurrence = _nextOccurrence(context, location);
    final filename = _goldenFileName(context.name, location, occurrence, index);
    final file = File('${_dir.path}/$filename');

    if (_update) {
      _dir.createSync(recursive: true);
      file.writeAsStringSync(content);
      return;
    }

    t.expect(file.existsSync(), t.isTrue,
        reason:
            'Missing golden file: ${file.path}. Run with UPDATE_GOLDENS=1 to create it.');

    final expected = file.readAsStringSync();
    if (expected != content) {
      t.expect(content, t.equals(expected));
    }
  }

  String _goldenFileName(
      String testName, String location, int occurrence, int index) {
    final safeName = _truncate(_sanitize(_shortTestName(testName)), 80);
    final hash = _hash('$testName|$location|$occurrence');
    final safeLocation = _truncate(_sanitize(_shortLocation(location)), 60);
    return 'auto__${safeName}__${safeLocation}__${hash}__$index.golden';
  }

  String scopedTestName(String testName, StackTrace trace) {
    final definition = _definitionLocation(trace);
    if (definition == null) {
      return testName;
    }
    return '$definition::$testName';
  }

  int _nextOccurrence(_GoldenContext context, String location) {
    final current = context.locationCounts[location] ?? 0;
    final next = current + 1;
    context.locationCounts[location] = next;
    return next;
  }

  String _locationKey(StackTrace trace) {
    final frames = Trace.from(trace).frames;
    for (final frame in frames) {
      if (!_isTestFrame(frame)) {
        continue;
      }
      final path =
          frame.uri.path.isNotEmpty ? frame.uri.path : frame.uri.toString();
      return '$path:${frame.line}:${frame.column}';
    }
    return 'unknown';
  }

  String? _definitionLocation(StackTrace trace) {
    final frames = Trace.from(trace).frames;
    for (final frame in frames) {
      if (!_isTestFrame(frame)) {
        continue;
      }
      final path =
          frame.uri.path.isNotEmpty ? frame.uri.path : frame.uri.toString();
      return '$path:${frame.line}:${frame.column}';
    }
    return null;
  }

  bool _isTestFrame(Frame frame) {
    final path =
        frame.uri.path.isNotEmpty ? frame.uri.path : frame.uri.toString();
    if (path.contains('golden_harness.dart')) {
      return false;
    }
    if (path.contains('package:test/') || path.contains('package:test_api/')) {
      return false;
    }
    return path.contains('/test/') || path.startsWith('test/');
  }

  String _sanitize(String input) {
    final sanitized = input
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return sanitized.isEmpty ? 'unnamed' : sanitized;
  }

  String _shortTestName(String testName) {
    final parts = testName.split('::');
    return parts.length > 1 ? parts.last : testName;
  }

  String _shortLocation(String location) {
    if (location == 'unknown') {
      return location;
    }
    final parts = location.split(':');
    if (parts.length < 3) {
      return location;
    }
    final line = parts[parts.length - 2];
    final column = parts[parts.length - 1];
    final path = parts.sublist(0, parts.length - 2).join(':');
    final file = path.split('/').last;
    return '$file:$line:$column';
  }

  String _truncate(String input, int maxLength) {
    if (input.length <= maxLength) {
      return input;
    }
    return input.substring(0, maxLength);
  }

  String _hash(String input) {
    var hash = 0x811c9dc5;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  Object? _normalize(Object? value, Object? matcher) {
    if (value is Function) {
      return {'type': 'Function', 'matcher': matcher?.toString()};
    }
    if (value == null || value is num || value is bool) {
      return value;
    }
    if (value is String) {
      return _normalizeString(value);
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is Future) {
      return {'type': value.runtimeType.toString()};
    }
    if (value is Iterable) {
      return value.map((entry) => _normalize(entry, null)).toList();
    }
    if (value is Map) {
      final normalized = <String, Object?>{};
      value.forEach((key, entry) {
        normalized[key.toString()] = _normalize(entry, null);
      });
      return normalized;
    }
    return value.toString();
  }

  String _normalizeString(String value) {
    final tempDirPattern = RegExp(r'liquify_test_[A-Za-z0-9]+');
    return value.replaceAll(tempDirPattern, 'liquify_test_<temp>');
  }

  String _serialize(Object? value) {
    if (value is String) {
      return value;
    }
    return const JsonEncoder.withIndent('  ').convert(value);
  }
}
