import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

class BottomNavSpec {
  final List<BottomNavigationBarItem> items = [];
}

class NavigationRailSpec {
  final List<NavigationRailDestination> destinations = [];
}

class NavigationBarSpec {
  final List<NavigationDestination> destinations = [];
}

const String _bottomNavSpecKey = '_liquify_flutter_bottom_nav_spec';
const String _navigationRailSpecKey = '_liquify_flutter_navigation_rail_spec';
const String _navigationBarSpecKey = '_liquify_flutter_navigation_bar_spec';

BottomNavSpec? getBottomNavSpec(Environment environment) {
  final value = environment.getRegister(_bottomNavSpecKey);
  if (value is BottomNavSpec) {
    return value;
  }
  return null;
}

void setBottomNavSpec(Environment environment, BottomNavSpec? spec) {
  if (spec == null) {
    environment.removeRegister(_bottomNavSpecKey);
  } else {
    environment.setRegister(_bottomNavSpecKey, spec);
  }
}

BottomNavSpec requireBottomNavSpec(Evaluator evaluator, String tagName) {
  final spec = getBottomNavSpec(evaluator.context);
  if (spec == null) {
    throw Exception('$tagName tag must be used inside bottom_nav');
  }
  return spec;
}

NavigationRailSpec? getNavigationRailSpec(Environment environment) {
  final value = environment.getRegister(_navigationRailSpecKey);
  if (value is NavigationRailSpec) {
    return value;
  }
  return null;
}

void setNavigationRailSpec(Environment environment, NavigationRailSpec? spec) {
  if (spec == null) {
    environment.removeRegister(_navigationRailSpecKey);
  } else {
    environment.setRegister(_navigationRailSpecKey, spec);
  }
}

NavigationRailSpec requireNavigationRailSpec(
  Evaluator evaluator,
  String tagName,
) {
  final spec = getNavigationRailSpec(evaluator.context);
  if (spec == null) {
    throw Exception('$tagName tag must be used inside navigation_rail');
  }
  return spec;
}

NavigationBarSpec? getNavigationBarSpec(Environment environment) {
  final value = environment.getRegister(_navigationBarSpecKey);
  if (value is NavigationBarSpec) {
    return value;
  }
  return null;
}

void setNavigationBarSpec(Environment environment, NavigationBarSpec? spec) {
  if (spec == null) {
    environment.removeRegister(_navigationBarSpecKey);
  } else {
    environment.setRegister(_navigationBarSpecKey, spec);
  }
}

NavigationBarSpec requireNavigationBarSpec(
  Evaluator evaluator,
  String tagName,
) {
  final spec = getNavigationBarSpec(evaluator.context);
  if (spec == null) {
    throw Exception('$tagName tag must be used inside navigation_bar');
  }
  return spec;
}
