import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquify_flutter/liquify_flutter.dart';

import 'package:liquify_flutter_example/main.dart';

Future<LiquifyExampleApp> buildTestApp(WidgetTester tester) async {
  final root = (await tester.runAsync<AssetBundleRoot>(
    () => AssetBundleRoot.loadFromDirectory(
      directory: Directory('assets/apps').absolute.path,
      basePath: 'assets/apps',
      throwOnMissing: true,
    ),
  ))!;
  return LiquifyExampleApp(
    rootFuture: SynchronousFuture(root),
    forceSync: true,
  );
}

Future<void> pumpForRender(WidgetTester tester) async {
  const verbose =
      bool.fromEnvironment('LIQUIFY_TEST_VERBOSE', defaultValue: false);
  if (verbose) {
    print('pumpForRender: start');
  }
  await tester.pump();
  if (verbose) {
    print('pumpForRender: done');
  }
}
