// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class NavigatorTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  NavigatorTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildNavigator(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildNavigator(config, children));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('navigator').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endnavigator').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'navigator',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _NavigatorConfig _parseConfig(Evaluator evaluator) {
    final config = _NavigatorConfig();
    Object? onPopPageValue;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'pages':
          config.pagesValue = value;
          break;
        case 'restorationScopeId':
          config.restorationScopeId = value?.toString();
          break;
        case 'requestFocus':
          config.requestFocus = toBool(value);
          break;
        case 'observers':
          if (value is List<NavigatorObserver>) {
            config.observers = value;
          }
          break;
        case 'transitionDelegate':
          if (value is TransitionDelegate) {
            config.transitionDelegate = value;
          }
          break;
        case 'reportsRouteUpdateToEngine':
          config.reportsRouteUpdateToEngine = toBool(value);
          break;
        case 'clip':
        case 'clipBehavior':
          config.clipBehavior = parseClip(value);
          break;
        case 'onPopPage':
          onPopPageValue = value;
          break;
        default:
          handleUnknownArg('navigator', name);
          break;
      }
    }

    if (onPopPageValue is PopPageCallback) {
      config.onPopPage = onPopPageValue;
    }
    return config;
  }

  List<Page<dynamic>> _resolvePages(List<Widget> children, Object? pagesValue) {
    final pages = <Page<dynamic>>[];
    if (pagesValue is Page) {
      pages.add(pagesValue);
    } else if (pagesValue is List) {
      for (final entry in pagesValue) {
        if (entry is Page) {
          pages.add(entry);
        } else if (entry is Widget) {
          pages.add(_wrapWidget(entry, pages.length));
        }
      }
    } else {
      for (final child in children) {
        pages.add(_wrapWidget(child, pages.length));
      }
    }
    if (pages.isEmpty) {
      pages.add(_wrapWidget(const SizedBox.shrink(), 0));
    }
    return pages;
  }

  Page<dynamic> _wrapWidget(Widget widget, int index) {
    return MaterialPage(
      key: ValueKey('nav_page_$index'),
      name: 'page_$index',
      child: widget,
    );
  }

  Widget _buildNavigator(_NavigatorConfig config, List<Widget> children) {
    final pages = _resolvePages(children, config.pagesValue);
    return Navigator(
      pages: pages,
      onPopPage: config.onPopPage ?? _defaultOnPopPage,
      observers: config.observers ?? const <NavigatorObserver>[],
      transitionDelegate:
          config.transitionDelegate ??
          const DefaultTransitionDelegate<dynamic>(),
      reportsRouteUpdateToEngine: config.reportsRouteUpdateToEngine ?? true,
      restorationScopeId: config.restorationScopeId,
      requestFocus: config.requestFocus ?? true,
      clipBehavior: config.clipBehavior ?? Clip.hardEdge,
    );
  }

  static bool _defaultOnPopPage(Route<dynamic> route, dynamic result) {
    return route.didPop(result);
  }
}

class _NavigatorConfig {
  Object? pagesValue;
  String? restorationScopeId;
  bool? requestFocus;
  List<NavigatorObserver>? observers;
  TransitionDelegate<dynamic>? transitionDelegate;
  bool? reportsRouteUpdateToEngine;
  Clip? clipBehavior;
  PopPageCallback? onPopPage;
}
