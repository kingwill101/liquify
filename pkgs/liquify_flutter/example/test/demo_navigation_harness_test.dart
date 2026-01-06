import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:liquify_flutter_example/main.dart';
import 'test_utils.dart';

List<String> _listPageIds(String appId) {
  final dir = Directory('assets/apps/$appId/pages');
  if (!dir.existsSync()) {
    return const [];
  }
  final ids = <String>[];
  for (final entity in dir.listSync()) {
    if (entity is! File) {
      continue;
    }
    final name = entity.path.split(Platform.pathSeparator).last;
    if (!name.endsWith('.liquid')) {
      continue;
    }
    ids.add(name.substring(0, name.length - '.liquid'.length));
  }
  ids.sort();
  return ids;
}

void main() {
  testWidgets('demo navigation harness (opt-in)', (tester) async {
    const enabled =
        bool.fromEnvironment('LIQUIFY_DEMO_HARNESS', defaultValue: false);
    if (!enabled) {
      return;
    }

    final flutterErrors = <FlutterErrorDetails>[];
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      flutterErrors.add(details);
      if (originalOnError != null) {
        originalOnError(details);
      }
    };
    addTearDown(() {
      FlutterError.onError = originalOnError;
    });

    debugPrint('Harness: buildTestApp start');
    final app = await buildTestApp(tester);
    debugPrint('Harness: buildTestApp done');
    await tester.pumpWidget(app);
    debugPrint('Harness: pumpWidget done');
    await pumpForRender(tester);
    debugPrint('Harness: initial pump done');

    final state = tester.state(find.byType(AppShell)) as dynamic;
    final appIds = <String>{
      ...state.debugAppIds as List<String>,
      ...state.debugControlAppIds as List<String>,
    }.toList()
      ..sort();

    Future<void> assertNoErrors(String label) async {
      await pumpForRender(tester);
      final exception = tester.takeException();
      if (exception != null) {
        fail('Unhandled exception on $label: $exception');
      }
      if (flutterErrors.isNotEmpty) {
        final first = flutterErrors.first.exceptionAsString();
        fail('FlutterError on $label: $first');
      }
    }

    state.debugOpenHome();
    debugPrint('Harness: home');
    await assertNoErrors('home');

    for (final appId in appIds) {
      if (appId == 'home') {
        continue;
      }
      debugPrint('Harness: app=$appId');
      state.debugOpenApp(appId);
      await assertNoErrors('app:$appId');

      final pages = _listPageIds(appId);
      for (final pageId in pages) {
        debugPrint('Harness: app=$appId page=$pageId');
        state.debugOpenPage(appId, pageId);
        await assertNoErrors('page:$appId/$pageId');
      }
    }
  });
}
