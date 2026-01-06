import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder, {
    int maxPumps = 30,
    Duration step = const Duration(milliseconds: 100),
  }) async {
    for (var i = 0; i < maxPumps; i++) {
      await tester.pump(step);
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
    fail('Timed out waiting for widget: $finder');
  }

  Future<void> openApp(
    WidgetTester tester,
    String appId,
    Finder readyFinder,
  ) async {
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('calculator')),
      maxPumps: 150,
    );
    final appButton = find.byKey(ValueKey(appId));
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(
        appButton,
        240,
        scrollable: scrollable.first,
      );
    }
    await tester.tap(appButton);
    await tester.pump(const Duration(milliseconds: 300));
    await pumpUntilFound(tester, readyFinder);
  }

  Future<void> runWithoutFlutterErrors(
    WidgetTester tester,
    String label,
    Future<void> Function() action,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterErrorDetails? capturedError;
    FlutterError.onError = (details) {
      capturedError ??= details;
    };
    try {
      await action();
    } finally {
      FlutterError.onError = originalOnError;
    }
    if (capturedError != null) {
      fail('Flutter error while $label: ${capturedError!.exception}');
    }
    final exception = tester.takeException();
    if (exception != null) {
      fail('Exception while $label: $exception');
    }
  }

  Future<void> returnHome(WidgetTester tester) async {
    await pumpForRender(tester);
    final appsButton = find.text('Apps');
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(
        appsButton,
        240,
        scrollable: scrollable.first,
      );
    } else {
      await tester.ensureVisible(appsButton);
    }
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(appsButton);
    await pumpForRender(tester);
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('calculator')),
      maxPumps: 150,
    );
  }

  Future<void> returnControlsHub(WidgetTester tester) async {
    await pumpForRender(tester);
    final controlsButton = find.text('Controls');
    await tester.ensureVisible(controlsButton);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(controlsButton);
    await pumpForRender(tester);
    await pumpUntilFound(
      tester,
      find.text('Controls Hub'),
      maxPumps: 150,
    );
  }

  Future<void> openControlsDemo(
    WidgetTester tester,
    String demoId,
    String readyLabel,
  ) async {
    final demoButton = find.byKey(ValueKey(demoId));
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(demoButton, 240, scrollable: scrollable.first);
    } else {
      await tester.ensureVisible(demoButton);
    }
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(demoButton);
    await tester.pump(const Duration(milliseconds: 300));
    await pumpUntilFound(tester, find.text(readyLabel));
  }

  testWidgets('calculator updates display after taps', (tester) async {
    final app = await buildTestApp(tester);
    await tester.pumpWidget(app);
    await openApp(tester, 'calculator', find.text('FC'));

    await tester.tap(find.text('FC'));
    await tester.pump();
    await tester.tap(find.text('7'));
    await tester.pump();
    await tester.tap(find.text('×'));
    await tester.pump();
    await tester.tap(find.text('8'));
    await tester.pump();
    await tester.tap(find.text('='));
    await pumpForRender(tester);

    expect(find.text('7 × 8'), findsOneWidget);
    expect(find.text('56'), findsOneWidget);
  });

  testWidgets('layout gallery tabs render', (tester) async {
    final app = await buildTestApp(tester);
    await tester.pumpWidget(app);
    await openApp(tester, 'layout_gallery', find.text('Row + Expanded'));

    Future<void> tapTab(String label, String expected) async {
      final originalOnError = FlutterError.onError;
      FlutterErrorDetails? capturedError;
      FlutterError.onError = (details) {
        capturedError = details;
      };
      final tabFinder = find.text(label);
      await tester.ensureVisible(tabFinder);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(tabFinder);
      await tester.pump(const Duration(milliseconds: 300));
      await pumpUntilFound(tester, find.text(expected));
      FlutterError.onError = originalOnError;
      if (capturedError != null) {
        fail('Flutter error while opening tab "$label": '
            '${capturedError!.exception}');
      }
      final exception = tester.takeException();
      if (exception != null) {
        fail('Exception while opening tab "$label": $exception');
      }
      expect(find.text(expected), findsOneWidget);
    }

    await tapTab('Row', 'Row + Expanded');
    await tapTab('Column', 'Column stack');
    await tapTab('Stack', 'Stack + Positioned');
    await tapTab('Wrap', 'Wrap + Chips');
    await tapTab('Grid', 'Grid tiles');
    await tapTab('Flex', 'Flexible split');
    await tapTab('Fit', 'Fitted + Aspect Ratio');
    await tapTab('Extras', 'Intrinsic + Constraints');
    await tapTab('Clip', 'Clips + Opacity');
    await tapTab('Slivers', 'Sliver basics');
  });

  testWidgets('app harness opens calculator and history', (tester) async {
    final app = await buildTestApp(tester);
    await tester.pumpWidget(app);
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('calculator')),
      maxPumps: 150,
    );

    await runWithoutFlutterErrors(tester, 'opening calculator', () async {
      await openApp(tester, 'calculator', find.text('FC'));
    });

    await runWithoutFlutterErrors(tester, 'opening calculator history',
        () async {
      final historyButton = find.text('History');
      await tester.tap(historyButton);
      await tester.pump(const Duration(milliseconds: 300));
      await pumpUntilFound(tester, find.text('Recent'));
    });

    await runWithoutFlutterErrors(tester, 'returning from history', () async {
      final backButton = find.text('Back');
      await tester.tap(backButton);
      await tester.pump(const Duration(milliseconds: 300));
      await pumpUntilFound(tester, find.text('FC'));
    });

    await runWithoutFlutterErrors(
      tester,
      'returning home from calculator',
      () async => returnHome(tester),
    );
  });

  testWidgets('app harness opens image viewer', (tester) async {
    final app = await buildTestApp(tester);
    await tester.pumpWidget(app);
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('calculator')),
      maxPumps: 150,
    );

    await runWithoutFlutterErrors(tester, 'opening image viewer', () async {
      await openApp(tester, 'image_viewer', find.text('No image loaded'));
    });

    await runWithoutFlutterErrors(
      tester,
      'returning home from image viewer',
      () async => returnHome(tester),
    );
  });

  testWidgets('app harness opens layout gallery', (tester) async {
    final app = await buildTestApp(tester);
    await tester.pumpWidget(app);
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('calculator')),
      maxPumps: 150,
    );

    await runWithoutFlutterErrors(tester, 'opening layout gallery', () async {
      await openApp(tester, 'layout_gallery', find.text('Row + Expanded'));
    });

    await runWithoutFlutterErrors(
      tester,
      'returning home from layout gallery',
      () async => returnHome(tester),
    );
  });

  testWidgets('app harness opens controls demos', (tester) async {
    final app = await buildTestApp(tester);
    await tester.pumpWidget(app);
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('calculator')),
      maxPumps: 150,
    );

    await runWithoutFlutterErrors(tester, 'opening controls hub', () async {
      await openApp(tester, 'controls', find.text('Controls Hub'));
    });

    final demoButtons = [
      {'id': 'controls_inputs', 'ready': 'Switches + Input'},
      {'id': 'controls_selection', 'ready': 'Segmented + Toggle'},
      {'id': 'controls_navigation', 'ready': 'Navigation'},
      {'id': 'controls_pickers', 'ready': 'Pickers + Steps'},
      {'id': 'controls_feedback', 'ready': 'Dialogs + Overlays'},
      {'id': 'controls_motion', 'ready': 'Animation + Motion'},
      {'id': 'controls_data', 'ready': 'Lists + Tables'},
    ];

    for (final demo in demoButtons) {
      await runWithoutFlutterErrors(
        tester,
        'opening controls ${demo['id']}',
        () async {
          await openControlsDemo(
            tester,
            demo['id']!,
            demo['ready']!,
          );
        },
      );
      await runWithoutFlutterErrors(
        tester,
        'returning to controls hub from ${demo['id']}',
        () async => returnControlsHub(tester),
      );
    }

    await runWithoutFlutterErrors(
      tester,
      'returning home from controls hub',
      () async => returnHome(tester),
    );
  });

  testWidgets('controls demos render interactive widgets', (tester) async {
    final app = await buildTestApp(tester);
    await tester.pumpWidget(app);

    await openApp(tester, 'controls', find.text('Controls Hub'));
    await openControlsDemo(tester, 'controls_inputs', 'Switches + Input');
    expect(find.byType(Slider), findsOneWidget);
    expect(find.byType(Switch), findsWidgets);
    expect(find.byType(TextField), findsWidgets);
    expect(find.byType(TextFormField), findsWidgets);
    expect(find.textContaining('Button taps'), findsOneWidget);
    await returnControlsHub(tester);
    await openControlsDemo(tester, 'controls_selection', 'Segmented + Toggle');
    expect(
      find.byWidgetPredicate((widget) => widget is SegmentedButton<int>),
      findsWidgets,
    );
    expect(find.byType(ToggleButtons), findsWidgets);
    expect(find.byType(Checkbox), findsWidgets);
    expect(
      find.byWidgetPredicate((widget) => widget is RadioListTile<String>),
      findsWidgets,
    );
    expect(find.byType(ChoiceChip), findsWidgets);
    expect(find.byType(FilterChip), findsWidgets);
    expect(find.byType(InputChip), findsOneWidget);
    expect(find.byType(Badge), findsWidgets);
    await returnControlsHub(tester);
    await openControlsDemo(tester, 'controls_navigation', 'Navigation');
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDrawer), findsOneWidget);
    expect(find.byType(Drawer), findsWidgets);
    expect(find.text('Account'), findsOneWidget);
    await returnControlsHub(tester);
    await openControlsDemo(tester, 'controls_pickers', 'Pickers + Steps');
    expect(
      find.byWidgetPredicate((widget) => widget is DropdownButton<String>),
      findsOneWidget,
    );
    expect(find.byType(Stepper), findsOneWidget);
    expect(find.text('2025-12-24'), findsOneWidget);
    expect(find.text('09:30'), findsOneWidget);
    await returnControlsHub(tester);
    await openControlsDemo(tester, 'controls_feedback', 'Dialogs + Overlays');
    expect(find.byType(LinearProgressIndicator), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.byType(AlertDialog), findsWidgets);
    expect(find.byType(BottomSheet), findsOneWidget);
    await returnControlsHub(tester);
    await openControlsDemo(tester, 'controls_motion', 'Animation + Motion');
    expect(find.text('Opacity'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is AnimatedContainer &&
            widget.child is Text &&
            (widget.child as Text).data == 'Container',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is FadeTransition &&
            widget.child is Text &&
            (widget.child as Text).data == 'Fade transition preview',
      ),
      findsOneWidget,
    );
    expect(find.byType(Hero), findsOneWidget);
    await returnControlsHub(tester);
    await openControlsDemo(tester, 'controls_data', 'Lists + Tables');
    expect(find.byType(ReorderableListView), findsWidgets);
    expect(find.byType(ExpansionTile), findsOneWidget);
    expect(find.byType(DataTable), findsWidgets);
    expect(find.byType(PaginatedDataTable), findsOneWidget);
  });
}
