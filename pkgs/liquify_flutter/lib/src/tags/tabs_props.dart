import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

class TabsSpec {
  final List<TabEntry> entries = [];
}

class TabEntry {
  TabEntry({required this.tab, required this.view});

  final Tab tab;
  final Widget view;
}

const String _tabsSpecKey = '_liquify_flutter_tabs_spec';

TabsSpec? getTabsSpec(Environment environment) {
  final value = environment.getRegister(_tabsSpecKey);
  if (value is TabsSpec) {
    return value;
  }
  return null;
}

void setTabsSpec(Environment environment, TabsSpec? spec) {
  if (spec == null) {
    environment.removeRegister(_tabsSpecKey);
  } else {
    environment.setRegister(_tabsSpecKey, spec);
  }
}

TabsSpec requireTabsSpec(Evaluator evaluator, String tagName) {
  final spec = getTabsSpec(evaluator.context);
  if (spec == null) {
    throw Exception('$tagName tag must be used inside tabs');
  }
  return spec;
}
