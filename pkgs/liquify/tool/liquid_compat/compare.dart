import 'dart:convert';
import 'dart:io';

import 'package:liquify/liquify.dart';

Future<void> main(List<String> args) async {
  final fixtures = jsonDecode(File(args[0]).readAsStringSync()) as List;
  final reference = jsonDecode(File(args[1]).readAsStringSync()) as List;
  if (reference.length != fixtures.length) {
    throw StateError('Ruby Liquid returned the wrong number of results.');
  }

  var differences = 0;
  var matchedRejections = 0;
  for (var index = 0; index < fixtures.length; index++) {
    final fixture = fixtures[index] as Map<String, dynamic>;
    final ruby = reference[index] as Map<String, dynamic>;
    final sync = await _runFixture(fixture, async: false);
    final async = await _runFixture(fixture, async: true);
    if (_matches(ruby, sync) && _matches(ruby, async)) {
      final rejected = ruby.containsKey('error');
      if (rejected) matchedRejections++;
      stdout.writeln(
        'MATCH ${fixture['label']}${rejected ? ' (both reject)' : ''}',
      );
      continue;
    }

    differences++;
    stdout.writeln('DIFF  ${fixture['label']}');
    stdout.writeln('  Shopify Liquid ${jsonEncode(ruby)}');
    stdout.writeln('  Liquify sync   ${jsonEncode(sync.result)}');
    stdout.writeln('  Liquify async  ${jsonEncode(async.result)}');
  }

  stdout.writeln(
    '${fixtures.length - differences} matched, $differences differed.',
  );
  stdout.writeln('$matchedRejections matching rejections.');
  if (differences > 0) exitCode = 1;
}

typedef _Attempt = ({Map<String, String> result, Object? error});

Future<_Attempt> _runFixture(
  Map<String, dynamic> fixture, {
  required bool async,
}) async {
  try {
    final partials = fixture['partials'] as Map<String, dynamic>? ?? {};
    final template = Template.parse(
      fixture['source'] as String,
      data: fixture['data'] as Map<String, dynamic>? ?? {},
      root: MapRoot(partials.cast<String, String>(), throwOnMissing: true),
    );
    final output = async ? await template.renderAsync() : template.render();
    return (result: {'output': output}, error: null);
  } catch (error) {
    return (result: {'error': error.toString()}, error: error);
  }
}

bool _matches(Map<String, dynamic> ruby, _Attempt actual) {
  if (ruby.containsKey('output')) {
    return ruby['output'] == actual.result['output'];
  }
  final error = actual.error;
  final reference = ruby['error'];
  return error != null &&
      reference is String &&
      _equivalentRejection(reference, error);
}

bool _equivalentRejection(String reference, Object actual) {
  if (actual is TemplateNotFoundException) {
    return reference ==
        'Liquid::FileSystemError: Liquid error: Missing partial: ${actual.path}';
  }
  if (actual is! ArgumentError || actual.message is! String) return false;

  final message = (actual.message as String).toLowerCase();
  if (reference.startsWith('Liquid::SyntaxError:')) {
    return message == 'render template name must be a quoted string' &&
        reference.endsWith('Template name must be a quoted string');
  }

  const argumentPrefix = 'Liquid::ArgumentError: Liquid error: ';
  if (!reference.startsWith(argumentPrefix)) return false;
  final reason = reference.substring(argumentPrefix.length);
  if (reason.toLowerCase() == message) return true;
  return RegExp(r'^comparison of .+ with .+ failed$').hasMatch(reason) &&
      RegExp(r'^cannot compare \w+ with \w+$').hasMatch(message);
}
