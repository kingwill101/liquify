import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liquify/liquify.dart';
import 'package:liquify_flutter/liquify_flutter.dart';
import 'package:petitparser/petitparser.dart';
import 'package:zenrouter/zenrouter.dart';

void main() {
  runApp(const LiquifyExampleApp());
}

IconData _iconDataForName(String name) {
  switch (name) {
    case 'star':
      return Icons.star;
    case 'favorite':
      return Icons.favorite;
    case 'home':
      return Icons.home;
    case 'search':
      return Icons.search;
    case 'person':
      return Icons.person;
  }
  return Icons.circle;
}

class LiquifyExampleApp extends StatelessWidget {
  const LiquifyExampleApp({super.key, this.rootFuture, this.forceSync = false});

  final Future<AssetBundleRoot>? rootFuture;
  final bool forceSync;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7DD3FC),
          brightness: Brightness.dark,
        ),
        toggleButtonsTheme: const ToggleButtonsThemeData(
          color: Color(0xFF94A3B8),
          selectedColor: Color(0xFFF1F5F9),
          fillColor: Color(0xFF1F2937),
          borderColor: Color(0xFF2B3443),
          selectedBorderColor: Color(0xFF3B82F6),
          borderRadius: BorderRadius.all(Radius.circular(12)),
          constraints: BoxConstraints(minHeight: 40, minWidth: 40),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0F141C),
          labelStyle: const TextStyle(color: Color(0xFFC0C7D5)),
          hintStyle: const TextStyle(color: Color(0xFF6B7280)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3B4453)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3B4453)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF7DD3FC)),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF94A3B8)),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF93C5FD),
          ),
        ),
        scaffoldBackgroundColor: _AppShellState._backgroundColor,
      ),
      home: SafeArea(
        child: AppShell(rootFuture: rootFuture, forceSync: forceSync),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.rootFuture, this.forceSync = false});

  final Future<AssetBundleRoot>? rootFuture;
  final bool forceSync;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static final Uint8List _demoImageBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=',
  );

  static const _backgroundColor = Color(0xFF101216);
  static const _homeAppId = 'home';
  static const _calculatorAppId = 'calculator';
  static const _imageViewerAppId = 'image_viewer';
  static const _layoutGalleryAppId = 'layout_gallery';
  static const _luaDemoAppId = 'lua_demo';
  static const _controlsHubAppId = 'controls';
  static const _controlsInputsAppId = 'controls_inputs';
  static const _controlsSelectionAppId = 'controls_selection';
  static const _controlsNavigationAppId = 'controls_navigation';
  static const _controlsPickersAppId = 'controls_pickers';
  static const _controlsFeedbackAppId = 'controls_feedback';
  static const _controlsMotionAppId = 'controls_motion';
  static const _controlsDataAppId = 'controls_data';
  static const Set<String> _asyncAppIds = {
    _homeAppId,
    _controlsMotionAppId,
    _luaDemoAppId, // Lua callbacks require async rendering
  };
  static const Set<String> _luaAppIds = {
    _luaDemoAppId,
    _calculatorAppId,
  };
  static const List<String> _controlsAppIds = [
    _controlsHubAppId,
    _controlsInputsAppId,
    _controlsSelectionAppId,
    _controlsNavigationAppId,
    _controlsPickersAppId,
    _controlsFeedbackAppId,
    _controlsMotionAppId,
    _controlsDataAppId,
  ];

  late final Future<AssetBundleRoot> _rootFuture;
  final NavigationPath _path = NavigationPath.create();
  final Map<String, Map<String, dynamic>> _luaSharedState = {};
  final ValueNotifier<String> _expression = ValueNotifier('128 × 12');
  final ValueNotifier<String> _display = ValueNotifier('1,536');
  final ValueNotifier<double> _sliderValue = ValueNotifier(0.35);
  final ValueNotifier<int> _segmentIndex = ValueNotifier(0);
  final ValueNotifier<int> _toggleIndex = ValueNotifier(1);
  final ValueNotifier<bool> _notificationsEnabled = ValueNotifier(true);
  final ValueNotifier<String> _deliveryTiming = ValueNotifier('Daily');
  final ValueNotifier<String> _chipChoice = ValueNotifier('Daily');
  final ValueNotifier<Set<String>> _chipFilters =
      ValueNotifier(<String>{'Email'});
  final ValueNotifier<bool> _chipInputSelected = ValueNotifier(false);
  final ValueNotifier<int> _chipActionCount = ValueNotifier(3);
  final ValueNotifier<bool> _autoSyncEnabled = ValueNotifier(true);
  final ValueNotifier<bool> _quietHoursEnabled = ValueNotifier(false);
  final ValueNotifier<bool> _motionEnabled = ValueNotifier(true);
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  final ValueNotifier<String> _profileName = ValueNotifier('Avery');
  final ValueNotifier<String> _profileEmail =
      ValueNotifier('avery@example.com');
  final ValueNotifier<int> _buttonTapCount = ValueNotifier(0);
  final ValueNotifier<String> _dropdownValue = ValueNotifier('Morning');
  final ValueNotifier<int> _stepIndex = ValueNotifier(0);
  final ValueNotifier<DateTime> _scheduledDate =
      ValueNotifier(DateTime(2025, 12, 24));
  final ValueNotifier<TimeOfDay> _scheduledTime =
      ValueNotifier(const TimeOfDay(hour: 9, minute: 30));
  final ValueNotifier<int> _iconToggleIndex = ValueNotifier(0);
  final ValueNotifier<int> _navIndex = ValueNotifier(0);
  final ValueNotifier<int> _railIndex = ValueNotifier(0);
  final ValueNotifier<List<Map<String, dynamic>>> _reorderItems =
      ValueNotifier([
    {'id': 'draft', 'title': 'Draft spec', 'meta': 'PM review'},
    {'id': 'build', 'title': 'Build widgets', 'meta': 'In progress'},
    {'id': 'ship', 'title': 'Ship update', 'meta': 'Next sprint'},
  ]);
  final ValueNotifier<List<Map<String, dynamic>>> _dataTableRows =
      ValueNotifier([
    {
      'id': 'prototype',
      'selected': true,
      'cells': ['Prototype', 'Avery', 'Review'],
    },
    {
      'id': 'widgets',
      'selected': false,
      'cells': ['Widget pass', 'Morgan', 'Build'],
    },
    {
      'id': 'handoff',
      'selected': false,
      'cells': ['Launch prep', 'Riley', 'Ready'],
    },
    {
      'id': 'publish',
      'selected': false,
      'cells': ['Publish', 'Kai', 'Queued'],
    },
  ]);
  final ValueNotifier<int?> _dataSortColumn = ValueNotifier(0);
  final ValueNotifier<bool> _dataSortAscending = ValueNotifier(true);
  final ValueNotifier<int> _dataRowsPerPage = ValueNotifier(3);
  final ValueNotifier<int> _dataPageStart = ValueNotifier(0);
  double? _lastResultValue;
  bool _justEvaluated = false;
  late final Parser<num> _calculatorParser = _buildCalculatorParser();
  static const List<String> _segmentLabels = [
    'Daily',
    'Weekly',
    'Monthly',
  ];
  static const List<String> _toggleLabels = [
    'Focus',
    'List',
    'Chart',
  ];
  static const List<Map<String, String>> _dropdownItems = [
    {'label': 'Morning', 'value': 'Morning', 'icon': 'star'},
    {'label': 'Afternoon', 'value': 'Afternoon', 'icon': 'favorite'},
    {'label': 'Evening', 'value': 'Evening', 'icon': 'home'},
  ];
  static final List<DropdownMenuItem<Object?>> _dropdownMenuItems =
      _dropdownItems
          .map(
            (item) => DropdownMenuItem<Object?>(
              value: item['value'],
              child: Row(
                children: [
                  Icon(_iconDataForName(item['icon'] ?? 'circle'), size: 16),
                  const SizedBox(width: 8),
                  Text(item['label'] ?? ''),
                ],
              ),
            ),
          )
          .toList();
  static const List<Map<String, String>> _stepItems = [
    {'title': 'Plan', 'subtitle': 'Outline goals'},
    {'title': 'Build', 'subtitle': 'Implement'},
    {'title': 'Ship', 'subtitle': 'Release'},
  ];
  static final List<Step> _stepperSteps = _stepItems
      .map(
        (item) => Step(
          title: Text(item['title'] ?? ''),
          content: Text(item['subtitle'] ?? ''),
          isActive: true,
        ),
      )
      .toList();
  static const List<String> _iconToggleIcons = [
    'home',
    'search',
    'settings',
  ];
  static const List<Map<String, String>> _navItems = [
    {'label': 'Home', 'icon': 'home'},
    {'label': 'Search', 'icon': 'search'},
    {'label': 'Profile', 'icon': 'person'},
  ];
  static final List<BottomNavigationBarItem> _navBottomItems = _navItems
      .map(
        (item) => BottomNavigationBarItem(
          icon: Icon(_iconDataForName(item['icon'] ?? 'circle')),
          label: item['label'] ?? '',
        ),
      )
      .toList();
  static final List<NavigationRailDestination> _navRailDestinations = _navItems
      .map(
        (item) => NavigationRailDestination(
          icon: Icon(_iconDataForName(item['icon'] ?? 'circle')),
          label: Text(item['label'] ?? ''),
        ),
      )
      .toList();
  static const List<Map<String, String>> _listPreviewItems = [
    {'title': 'Inbox', 'meta': '12 unread'},
    {'title': 'Tasks', 'meta': '5 due today'},
    {'title': 'Notes', 'meta': '2 new'},
  ];
  static const List<List<String>> _tableRows = [
    ['Stage', 'Owner', 'ETA'],
    ['Plan', 'Avery', '2d'],
    ['Build', 'Morgan', '5d'],
    ['Ship', 'Riley', '2w'],
  ];
  static const Map<int, Map<String, num>> _tableColumnWidths = {
    0: {'flex': 2},
    1: {'flex': 1.2},
    2: {'flex': 1},
  };
  static const Map<String, Object> _tableBorder = {
    'color': '#2f3747',
    'width': 1,
  };
  static const List<Map<String, Object>> _dataTableColumns = [
    {'label': 'Task'},
    {'label': 'Owner'},
    {'label': 'Status'},
  ];
  static const List<int> _dataRowsPerPageOptions = [3, 5, 10];
  static const String _startAppId =
      String.fromEnvironment('LIQUIFY_START_APP', defaultValue: '');
  static const String _startPageId =
      String.fromEnvironment('LIQUIFY_START_PAGE', defaultValue: '');

  final List<Map<String, String>> _apps = const [
    {
      'id': _calculatorAppId,
      'title': 'Calculator',
      'action': 'nav:calculator',
      'subtitle': 'Fast numeric layout with actions.',
      'icon': 'star',
      'accent': '#f5b74a',
    },
    {
      'id': _imageViewerAppId,
      'title': 'Image Viewer',
      'action': 'nav:image_viewer',
      'subtitle': 'Test cards, icons, and layout.',
      'icon': 'favorite',
      'accent': '#7dd3fc',
    },
    {
      'id': _layoutGalleryAppId,
      'title': 'Layout Gallery',
      'action': 'nav:layout_gallery',
      'subtitle': 'Rows, columns, stacks, and grids.',
      'icon': 'view_quilt',
      'accent': '#a78bfa',
    },
    {
      'id': _luaDemoAppId,
      'title': 'Lua Callbacks',
      'action': 'nav:lua_demo',
      'subtitle': 'Over-the-wire UI interactions.',
      'icon': 'code',
      'accent': '#fb923c',
    },
    {
      'id': _controlsHubAppId,
      'title': 'Controls',
      'action': 'nav:controls',
      'subtitle': 'Pick a control set to explore.',
      'icon': 'tune',
      'accent': '#34d399',
    },
  ];

  @override
  void initState() {
    super.initState();
    _rootFuture = widget.rootFuture ??
        AssetBundleRoot.load(
          basePath: 'assets/apps',
          throwOnMissing: true,
        );
    _searchController.addListener(_handleSearchChanged);
    if (_startAppId.isNotEmpty) {
      if (_startPageId.isNotEmpty) {
        _path.push(LiquidPageRoute(_startAppId, _startPageId));
      } else {
        _path.push(LiquidAppRoute(_startAppId));
      }
    } else {
      _path.push(HomeRoute());
    }
  }

  @override
  void dispose() {
    _expression.dispose();
    _display.dispose();
    _sliderValue.dispose();
    _segmentIndex.dispose();
    _toggleIndex.dispose();
    _notificationsEnabled.dispose();
    _deliveryTiming.dispose();
    _chipChoice.dispose();
    _chipFilters.dispose();
    _chipInputSelected.dispose();
    _chipActionCount.dispose();
    _autoSyncEnabled.dispose();
    _quietHoursEnabled.dispose();
    _motionEnabled.dispose();
    _buttonTapCount.dispose();
    _searchQuery.dispose();
    _profileName.dispose();
    _profileEmail.dispose();
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _dropdownValue.dispose();
    _stepIndex.dispose();
    _scheduledDate.dispose();
    _scheduledTime.dispose();
    _iconToggleIndex.dispose();
    _navIndex.dispose();
    _railIndex.dispose();
    _reorderItems.dispose();
    _dataTableRows.dispose();
    _dataSortColumn.dispose();
    _dataSortAscending.dispose();
    _dataRowsPerPage.dispose();
    _dataPageStart.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    _searchQuery.value = _searchController.text;
  }

  @visibleForTesting
  void debugOpenHome() {
    _path.reset();
    _path.push(HomeRoute());
  }

  @visibleForTesting
  void debugOpenApp(String appId) {
    _path.reset();
    _path.push(LiquidAppRoute(appId));
  }

  @visibleForTesting
  void debugOpenPage(String appId, String pageId) {
    _path.reset();
    _path.push(LiquidPageRoute(appId, pageId));
  }

  @visibleForTesting
  List<String> get debugAppIds =>
      _apps.map((app) => app['id']).whereType<String>().toList();

  @visibleForTesting
  List<String> get debugControlAppIds =>
      List<String>.unmodifiable(_controlsAppIds);

  void _handleAction(
    String appId,
    String action,
    Map<String, dynamic> event,
  ) {
    if (action.startsWith('page:')) {
      final target = action.substring(5);
      if (target == 'back') {
        _path.pop();
        return;
      }
      _path.push(LiquidPageRoute(appId, target));
      return;
    }
    if (action.startsWith('nav:')) {
      final target = action.substring(4);
      if (target == 'back') {
        _path.pop();
        return;
      }
      if (target == 'home') {
        _path.push(HomeRoute());
        return;
      }
      _path.push(LiquidAppRoute(target));
      return;
    }
    if (appId == _calculatorAppId) {
      _handleCalculatorAction(action, event);
      return;
    }
    if (_controlsAppIds.contains(appId)) {
      _handleControlsAction(action, event);
      return;
    }
  }

  void _handleCalculatorAction(String value, Map<String, dynamic> event) {
    switch (value) {
      case 'FC':
        _expression.value = '';
        _display.value = '0';
        _lastResultValue = null;
        _justEvaluated = false;
        break;
      case 'MC':
      case 'MR':
      case 'M+':
      case 'M-':
        break;
      case '+/-':
        _expression.value = _toggleLastNumber(_expression.value);
        _display.value = _expression.value.isEmpty ? '0' : _expression.value;
        _justEvaluated = false;
        break;
      case '%':
        _expression.value = _applyPercent(_expression.value);
        _display.value = _expression.value.isEmpty ? '0' : _expression.value;
        _justEvaluated = false;
        break;
      case 'pi':
        _appendValue(math.pi.toStringAsPrecision(8));
        break;
      case '⌫':
        if (_expression.value.isNotEmpty) {
          _expression.value =
              _expression.value.substring(0, _expression.value.length - 1);
        }
        _display.value = _expression.value.isEmpty ? '0' : _expression.value;
        _justEvaluated = false;
        break;
      case '=':
        if (_expression.value.isEmpty) {
          _display.value = '0';
          _lastResultValue = null;
          _justEvaluated = false;
          break;
        }
        final result = _evaluateExpression(_expression.value);
        if (result == null) {
          _display.value = 'Err';
          _lastResultValue = null;
          _justEvaluated = false;
        } else {
          _display.value = _formatNumber(result);
          _lastResultValue = result;
          _justEvaluated = true;
        }
        break;
      default:
        if (_isOperator(value)) {
          _appendOperator(value);
        } else {
          _appendValue(value);
        }
    }
  }

  void _handleControlsAction(String value, Map<String, dynamic> event) {
    switch (value) {
      case 'controls:segment':
        final index = event['index'];
        if (index is num) {
          _segmentIndex.value = index.toInt();
        }
        break;
      case 'controls:toggle':
        final index = event['index'];
        if (index is num) {
          _toggleIndex.value = index.toInt();
        }
        break;
      case 'controls:slider':
        final sliderValue = event['value'];
        if (sliderValue is num) {
          _sliderValue.value = sliderValue.toDouble().clamp(0, 1);
        }
        break;
      case 'controls:checkbox':
        final flag = event['value'];
        if (flag is bool) {
          _notificationsEnabled.value = flag;
        }
        break;
      case 'controls:radio':
        final selection = event['value'];
        if (selection != null) {
          _deliveryTiming.value = selection.toString();
        }
        break;
      case 'controls:chip_action':
        _chipActionCount.value = _chipActionCount.value + 1;
        break;
      case 'controls:chip_choice':
        final selected = event['selected'];
        final value = event['value'];
        if (selected is bool && selected && value != null) {
          _chipChoice.value = value.toString();
        }
        break;
      case 'controls:chip_filter':
        final selected = event['selected'];
        final value = event['value'];
        if (selected is bool && value != null) {
          final label = value.toString();
          final next = Set<String>.from(_chipFilters.value);
          if (selected) {
            next.add(label);
          } else {
            next.remove(label);
          }
          _chipFilters.value = next;
        }
        break;
      case 'controls:chip_input':
        final selected = event['selected'];
        if (selected is bool) {
          _chipInputSelected.value = selected;
        }
        break;
      case 'controls:chip_delete':
        _chipInputSelected.value = false;
        break;
      case 'controls:switch_auto_sync':
        _autoSyncEnabled.value = !_autoSyncEnabled.value;
        break;
      case 'controls:switch_quiet_hours':
        _quietHoursEnabled.value = !_quietHoursEnabled.value;
        break;
      case 'controls:motion_toggle':
        _motionEnabled.value = !_motionEnabled.value;
        break;
      case 'controls:search_clear':
        _searchController.clear();
        break;
      case 'controls:profile_name':
        final name = event['value'];
        if (name != null) {
          _profileName.value = name.toString();
        }
        break;
      case 'controls:profile_email':
        final email = event['value'];
        if (email != null) {
          _profileEmail.value = email.toString();
        }
        break;
      case 'controls:button_tap':
        _buttonTapCount.value = _buttonTapCount.value + 1;
        break;
      case 'controls:dropdown':
        final value = event['value'];
        if (value != null) {
          _dropdownValue.value = value.toString();
        }
        break;
      case 'controls:step':
        final index = event['index'];
        if (index is num) {
          _stepIndex.value = index.toInt();
        }
        break;
      case 'controls:date_pick':
        final value = event['value'];
        if (value is String) {
          final parsed = DateTime.tryParse(value);
          if (parsed != null) {
            _scheduledDate.value = parsed;
          }
        }
        break;
      case 'controls:time_pick':
        final value = event['value'];
        if (value is String) {
          final parts = value.split(':');
          if (parts.length >= 2) {
            final hour = int.tryParse(parts[0]);
            final minute = int.tryParse(parts[1]);
            if (hour != null && minute != null) {
              _scheduledTime.value =
                  TimeOfDay(hour: hour, minute: minute);
            }
          }
        }
        break;
      case 'controls:icon_toggle':
        final index = event['index'];
        if (index is num) {
          _iconToggleIndex.value = index.toInt();
        }
        break;
      case 'controls:nav_select':
        final index = event['index'];
        if (index is num) {
          _navIndex.value = index.toInt();
        }
        break;
      case 'controls:rail_select':
        final index = event['index'];
        if (index is num) {
          _railIndex.value = index.toInt();
        }
        break;
      case 'controls:reorder':
        final oldIndex = event['oldIndex'];
        final newIndex = event['newIndex'];
        if (oldIndex is num && newIndex is num) {
          final items = List<Map<String, dynamic>>.from(_reorderItems.value);
          var from = oldIndex.toInt();
          var to = newIndex.toInt();
          if (from < to) {
            to -= 1;
          }
          if (from >= 0 && from < items.length && to >= 0) {
            final item = items.removeAt(from);
            if (to > items.length) {
              to = items.length;
            }
            items.insert(to, item);
            _reorderItems.value = items;
          }
        }
        break;
      case 'controls:data_sort':
        final columnIndex = event['columnIndex'];
        final ascending = event['ascending'];
        if (columnIndex is num) {
          final index = columnIndex.toInt();
          final isAscending = ascending is bool ? ascending : true;
          _dataSortColumn.value = index;
          _dataSortAscending.value = isAscending;
          _sortTableRows(index, isAscending);
        }
        break;
      case 'controls:data_row':
        final rowIndex = event['rowIndex'];
        final selected = event['value'];
        if (rowIndex is num && selected is bool) {
          final rows = List<Map<String, dynamic>>.from(_dataTableRows.value);
          final index = rowIndex.toInt();
          if (index >= 0 && index < rows.length) {
            final row = Map<String, dynamic>.from(rows[index]);
            row['selected'] = selected;
            rows[index] = row;
            _dataTableRows.value = rows;
          }
        }
        break;
      case 'controls:rows_per_page':
        final value = event['value'];
        if (value is num) {
          _dataRowsPerPage.value = value.toInt();
        }
        break;
      case 'controls:page_changed':
        final value = event['value'];
        if (value is num) {
          _dataPageStart.value = value.toInt();
        }
        break;
      default:
        break;
    }
  }

  void _sortTableRows(int columnIndex, bool ascending) {
    final rows = List<Map<String, dynamic>>.from(_dataTableRows.value);
    rows.sort((a, b) {
      final aValue = _cellValue(a, columnIndex);
      final bValue = _cellValue(b, columnIndex);
      final comparison = aValue.compareTo(bValue);
      return ascending ? comparison : -comparison;
    });
    _dataTableRows.value = rows;
  }

  String _cellValue(Map<String, dynamic> row, int columnIndex) {
    final cells = row['cells'];
    if (cells is List && columnIndex >= 0 && columnIndex < cells.length) {
      return cells[columnIndex]?.toString() ?? '';
    }
    return '';
  }

  void _appendValue(String token) {
    if (_justEvaluated) {
      _expression.value = token;
      _display.value = _expression.value;
      _justEvaluated = false;
      return;
    }
    _appendToken(token);
  }

  void _appendOperator(String token) {
    final tokens = _tokenize(_expression.value);
    if (_justEvaluated) {
      final base = _lastResultValue ?? _parseNumber(_display.value);
      if (base == null) {
        return;
      }
      _expression.value = '${_formatNumber(base)} $token';
      _display.value = _expression.value;
      _justEvaluated = false;
      return;
    }
    if (tokens.isEmpty) {
      final base = _lastResultValue ?? _parseNumber(_display.value);
      if (base == null) {
        return;
      }
      _expression.value = '${_formatNumber(base)} $token';
      _display.value = _expression.value;
      return;
    }
    if (_isOperator(tokens.last)) {
      tokens[tokens.length - 1] = token;
      _expression.value = tokens.join(' ');
      _display.value = _expression.value;
      return;
    }
    _appendToken(token);
  }

  void _appendToken(String token) {
    if (_expression.value.isEmpty) {
      _expression.value = token;
    } else {
      _expression.value = '${_expression.value} $token';
    }
    _display.value = _expression.value;
  }

  String _toggleLastNumber(String expression) {
    final tokens = _tokenize(expression);
    if (tokens.isEmpty) {
      return expression;
    }
    final last = tokens.last;
    final number = _parseNumber(last);
    if (number == null) {
      return expression;
    }
    final toggled = -number;
    tokens[tokens.length - 1] = _formatNumber(toggled);
    return tokens.join(' ');
  }

  String _applyPercent(String expression) {
    final tokens = _tokenize(expression);
    if (tokens.isEmpty) {
      return expression;
    }
    final last = tokens.last;
    final number = _parseNumber(last);
    if (number == null) {
      return expression;
    }
    tokens[tokens.length - 1] = _formatNumber(number / 100);
    return tokens.join(' ');
  }

  double? _evaluateExpression(String expression) {
    if (expression.trim().isEmpty) {
      return null;
    }
    final normalized = _normalizeExpression(expression);
    final result = _calculatorParser.parse(normalized);
    if (result is Success<num>) {
      return result.value.toDouble();
    }
    return null;
  }

  List<String> _tokenize(String expression) {
    return expression.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  }

  bool _isOperator(String token) {
    return token == '+' ||
        token == '-' ||
        token == '−' ||
        token == '×' ||
        token == '÷' ||
        token == '^';
  }

  String _normalizeExpression(String expression) {
    return expression
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll('π', 'pi')
        .replaceAll(',', '');
  }

  double? _parseNumber(String token) {
    if (token == '(' || token == ')') {
      return null;
    }
    if (token == 'pi') {
      return math.pi;
    }
    return double.tryParse(token);
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    final text = value.toStringAsFixed(8);
    return text
        .replaceFirst(RegExp(r'\\.0+$'), '')
        .replaceFirst(RegExp(r'(\\.\\d+?)0+$'), r'$1');
  }

  StackTransition<T> _transition<T extends RouteTarget>(Widget page) {
    if (widget.forceSync) {
      return StackTransition.none(page);
    }
    return StackTransition.material(page);
  }

  @override
  Widget build(BuildContext context) {
    return NavigationStack(
      path: _path,
      resolver: (route) {
        if (route is HomeRoute) {
          return _transition(
            _buildLiquidScreen(
              appId: _homeAppId,
              template: 'home/app.liquid',
              data: {
                'apps': _apps,
              },
            ),
          );
        }
        if (route is LiquidPageRoute) {
          if (_luaAppIds.contains(route.appId)) {
            return _transition(
              _buildLuaPage(
                route.appId,
                template: '${route.appId}/pages/${route.pageId}.liquid',
                data: const {},
              ),
            );
          }
          return _transition(
            _buildLiquidScreen(
              appId: route.appId,
              template: '${route.appId}/pages/${route.pageId}.liquid',
              data: const {},
            ),
          );
        }
        if (route is LiquidAppRoute) {
          final page = _luaAppIds.contains(route.appId)
              ? _buildLuaPage(
                  route.appId,
                  data: route.appId == _calculatorAppId
                      ? const {'expression': '', 'display': '0'}
                      : const {},
                )
              : _controlsAppIds.contains(route.appId)
                  ? AnimatedBuilder(
                      animation: Listenable.merge([
                        _sliderValue,
                        _segmentIndex,
                        _toggleIndex,
                        _notificationsEnabled,
                        _deliveryTiming,
                        _chipChoice,
                        _chipFilters,
                        _chipInputSelected,
                        _chipActionCount,
                        _autoSyncEnabled,
                        _quietHoursEnabled,
                        _motionEnabled,
                        _searchQuery,
                        _profileName,
                        _profileEmail,
                        _buttonTapCount,
                        _dropdownValue,
                        _stepIndex,
                        _scheduledDate,
                        _scheduledTime,
                        _iconToggleIndex,
                        _navIndex,
                        _railIndex,
                        _reorderItems,
                        _dataTableRows,
                        _dataSortColumn,
                        _dataSortAscending,
                        _dataRowsPerPage,
                        _dataPageStart,
                      ]),
                      builder: (context, child) {
                        return _buildLiquidScreen(
                          appId: route.appId,
                          template: '${route.appId}/app.liquid',
                          data: {
                            'segment_labels': _segmentLabels,
                            'segment_index': _segmentIndex.value,
                            'toggle_labels': _toggleLabels,
                            'toggle_index': _toggleIndex.value,
                            'slider_value': _sliderValue.value,
                            'notifications_enabled': _notificationsEnabled.value,
                            'delivery_timing': _deliveryTiming.value,
                            'chip_choice': _chipChoice.value,
                            'chip_filter_email':
                                _chipFilters.value.contains('Email'),
                            'chip_filter_push':
                                _chipFilters.value.contains('Push'),
                            'chip_filter_sms':
                                _chipFilters.value.contains('SMS'),
                            'chip_input_selected': _chipInputSelected.value,
                            'chip_action_count': _chipActionCount.value,
                            'switch_auto_sync': _autoSyncEnabled.value,
                            'switch_quiet_hours': _quietHoursEnabled.value,
                            'motion_enabled': _motionEnabled.value,
                            'search_controller': _searchController,
                            'search_query': _searchQuery.value.isEmpty
                                ? 'Start typing to see the value.'
                                : _searchQuery.value,
                            'profile_name': _profileName.value,
                            'profile_email': _profileEmail.value,
                            'button_tap_count': _buttonTapCount.value,
                            'dropdown_items': _dropdownItems,
                            'dropdown_menu_items': _dropdownMenuItems,
                            'dropdown_value': _dropdownValue.value,
                            'step_items': _stepItems,
                            'stepper_steps': _stepperSteps,
                            'step_index': _stepIndex.value,
                            'scheduled_date': _scheduledDate.value,
                            'scheduled_time': _scheduledTime.value,
                            'icon_toggle_icons': _iconToggleIcons,
                            'icon_toggle_index': _iconToggleIndex.value,
                            'nav_items': _navItems,
                            'nav_bottom_items': _navBottomItems,
                            'nav_rail_destinations': _navRailDestinations,
                            'nav_index': _navIndex.value,
                            'rail_index': _railIndex.value,
                            'list_preview_items': _listPreviewItems,
                            'reorder_items': _reorderItems.value,
                            'table_rows': _tableRows,
                            'table_column_widths': _tableColumnWidths,
                            'table_border': _tableBorder,
                            'data_table_columns': _dataTableColumns,
                            'data_table_rows': _dataTableRows.value,
                            'data_sort_column': _dataSortColumn.value,
                            'data_sort_ascending': _dataSortAscending.value,
                            'data_rows_per_page': _dataRowsPerPage.value,
                            'data_rows_per_page_options':
                                _dataRowsPerPageOptions,
                            'data_page_start': _dataPageStart.value,
                          },
                    );
                  },
                )
              : _buildLiquidScreen(
                  appId: route.appId,
                  template: '${route.appId}/app.liquid',
                  data: route.appId == _imageViewerAppId
                      ? {
                          'demo_image_bytes': _demoImageBytes,
                        }
                      : const {},
                );
          return _transition(page);
        }
        return _transition(
          _buildLiquidScreen(
            appId: _homeAppId,
            template: 'home/app.liquid',
            data: {
              'apps': _apps,
            },
          ),
        );
      },
    );
  }

  Widget _buildLuaPage(
    String appId, {
    String? template,
    Map<String, dynamic> data = const {},
  }) {
    final sharedState =
        _luaSharedState.putIfAbsent(appId, () => <String, dynamic>{});
    return FutureBuilder<AssetBundleRoot>(
      future: _rootFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ColoredBox(
          color: _backgroundColor,
          child: LiquidPage(
            template: template ?? '$appId/app.liquid',
            root: snapshot.data!,
            data: data,
            sharedState: sharedState,
            onAction: (action) => _handleAction(appId, action, {}),
          ),
        );
      },
    );
  }

  Widget _buildLiquidScreen({
    required String appId,
    required String template,
    required Map<String, dynamic> data,
  }) {
    return ColoredBox(
      color: _backgroundColor,
      child: LiquidScreen(
        rootFuture: _rootFuture,
        template: template,
        data: {
          ...data,
          'appId': appId,
          'actions': AppActions(
            (action, event) => _handleAction(appId, action, event),
          ),
        },
        useAsync: widget.forceSync ? false : _asyncAppIds.contains(appId),
        allowSyncLua: widget.forceSync,
      ),
    );
  }
}

class LiquidScreen extends StatefulWidget {
  const LiquidScreen({
    super.key,
    required this.rootFuture,
    required this.template,
    required this.data,
    this.useAsync = false,
    this.allowSyncLua = false,
  });

  final Future<AssetBundleRoot> rootFuture;
  final String template;
  final Map<String, dynamic> data;
  final bool useAsync;
  final bool allowSyncLua;

  @override
  State<LiquidScreen> createState() => _LiquidScreenState();
}

class _LiquidScreenState extends State<LiquidScreen> {
  Future<Widget>? _renderFuture;
  int? _lastDataHash;
  Size? _lastSize;
  String? _lastTemplate;
  static const bool _verbose =
      bool.fromEnvironment('LIQUIFY_TEST_VERBOSE', defaultValue: false);

  /// Cached environment - reused across builds to avoid re-registration.
  Environment? _cachedEnvironment;
  
  /// Tracks if Flutter tags have been registered to the cached environment.
  bool _environmentConfigured = false;

  Widget _decorateEmptyRender(Widget widget) {
    if (!kDebugMode) {
      return widget;
    }
    if (widget is SizedBox && widget.width == 0 && widget.height == 0) {
      final template = _lastTemplate ?? widget.toStringShort();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No widgets rendered for $template.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return widget;
  }

  @override
  void didUpdateWidget(LiquidScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.template != widget.template ||
        oldWidget.rootFuture != widget.rootFuture) {
      _renderFuture = null;
      _lastDataHash = null;
      _lastSize = null;
      _lastTemplate = null;
      _cachedEnvironment = null;
      _environmentConfigured = false;
    }
  }

  int _hashData(Map<String, dynamic> data) {
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Object.hashAll(entries.map((entry) {
      return Object.hash(entry.key, _hashValue(entry.value));
    }));
  }

  int _hashValue(Object? value) {
    if (value is Map) {
      final entries = value.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      return Object.hashAll(entries.map((entry) {
        return Object.hash(entry.key.toString(), _hashValue(entry.value));
      }));
    }
    if (value is Iterable) {
      return Object.hashAll(value.map(_hashValue));
    }
    return value?.hashCode ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AssetBundleRoot>(
      future: widget.rootFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Failed to load templates: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final mediaQuery = MediaQuery.of(context);
        final padding = mediaQuery.padding;
        final size = mediaQuery.size;
        final mergedData = <String, dynamic>{
          ...widget.data,
          'screen': {
            'width': size.width,
            'height': size.height,
            'orientation': mediaQuery.orientation.name,
            'devicePixelRatio': mediaQuery.devicePixelRatio,
            'safeTop': padding.top,
            'safeBottom': padding.bottom,
            'safeLeft': padding.left,
            'safeRight': padding.right,
            'safeWidth': size.width - padding.left - padding.right,
            'safeHeight': size.height - padding.top - padding.bottom,
          },
        };
        
        // Reuse cached environment or create new one
        final environment = _cachedEnvironment ??= Environment();
        
        // Register tags/filters only once per environment instance
        if (!_environmentConfigured) {
          environment.setRegister('_liquify_flutter_strict_props', true);
          environment.setRegister('_liquify_flutter_strict_tags', true);
          environment.setRegister('_liquify_flutter_generated_only', true);
          environment.setRegister('_liquify_flutter_rebuild', () {
            if (!mounted) return;
            // Schedule rebuild after current frame to avoid re-entering Lua
            // while callbacks are still executing on the Lua call stack.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _renderFuture = null; // Force re-render
              });
            });
          });
          if (widget.allowSyncLua) {
            environment.setRegister('_liquify_flutter_allow_sync_lua', true);
          }
          registerFlutterTags(environment: environment);
          _environmentConfigured = true;
        }
        
        // Update context-specific register every build (context changes)
        environment.setRegister('_liquify_flutter_context', context);
        
        final templateInstance = FlutterTemplate.fromFile(
          widget.template,
          snapshot.data!,
          environment: environment,
          data: mergedData,
        );
        if (!widget.useAsync) {
          if (_verbose) {
            final stopwatch = Stopwatch()..start();
            debugPrint('LiquidScreen render start ${widget.template}');
            final widgetResult = templateInstance.render();
            stopwatch.stop();
            debugPrint(
              'LiquidScreen render ${widget.template} in ${stopwatch.elapsed}',
            );
            return widgetResult;
          }
          return _decorateEmptyRender(templateInstance.render());
        }

        final dataHash = _hashData(mergedData);
        final shouldRefresh = _renderFuture == null ||
            _lastTemplate != widget.template ||
            _lastDataHash != dataHash ||
            _lastSize != size;
        if (shouldRefresh) {
          _lastTemplate = widget.template;
          _lastDataHash = dataHash;
          _lastSize = size;
          if (_verbose) {
            _renderFuture = () async {
              final stopwatch = Stopwatch()..start();
              debugPrint('LiquidScreen async render start ${widget.template}');
              final widgetResult = await templateInstance.renderAsync();
              stopwatch.stop();
              debugPrint(
                'LiquidScreen async render ${widget.template} in ${stopwatch.elapsed}',
              );
              return widgetResult;
            }();
          } else {
            _renderFuture = templateInstance.renderAsync();
          }
        }
        return FutureBuilder<Widget>(
          future: _renderFuture,
          builder: (context, renderSnapshot) {
            if (renderSnapshot.hasError) {
              final details = FlutterErrorDetails(
                exception: renderSnapshot.error!,
                stack: renderSnapshot.stackTrace,
                context: ErrorDescription('LiquidScreen render'),
              );
              FlutterError.reportError(details);
              debugPrint(
                'LiquidScreen render error: ${renderSnapshot.error}\n${renderSnapshot.stackTrace}',
              );
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Failed to render template: ${renderSnapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (!renderSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _decorateEmptyRender(renderSnapshot.data!);
          },
        );
      },
    );
  }
}

class HomeRoute extends RouteTarget {}

class LiquidAppRoute extends RouteTarget {
  LiquidAppRoute(this.appId);

  final String appId;

  @override
  List<Object?> get props => [appId];
}

class LiquidPageRoute extends RouteTarget {
  LiquidPageRoute(this.appId, this.pageId);

  final String appId;
  final String pageId;

  @override
  List<Object?> get props => [appId, pageId];
}

class AppActions extends Drop {
  AppActions(this.onAction) {
    invokable = [#tap, #clicked];
  }

  final void Function(String action, Map<String, dynamic> event) onAction;

  @override
  dynamic invoke(Symbol symbol) {
    final action = attrs['action']?.toString();
    final event = attrs['event'];
    if (action == null || action.isEmpty) {
      return null;
    }
    if (event is Map) {
      onAction(action, Map<String, dynamic>.from(event));
    } else {
      onAction(action, <String, dynamic>{});
    }
    return null;
  }
}

Parser<num> _buildCalculatorParser() {
  final builder = ExpressionBuilder<num>();
  builder.primitive(
    (pattern('+-').optional() &
            digit().plus() &
            (char('.') & digit().plus()).optional() &
            (pattern('eE') & pattern('+-').optional() & digit().plus())
                .optional())
        .flatten(message: 'number expected')
        .trim()
        .map(num.parse),
  );
  builder.primitive(string('pi').trim().map((_) => math.pi));
  builder.primitive(char('π').trim().map((_) => math.pi));
  builder.group().wrapper(
    char('(').trim(),
    char(')').trim(),
    (left, value, right) => value,
  );
  builder.group().prefix(char('-').trim(), (op, a) => -a);
  builder.group().right(char('^').trim(), (a, op, b) => math.pow(a, b));
  builder.group()
    ..left(char('*').trim(), (a, op, b) => a * b)
    ..left(char('/').trim(), (a, op, b) => a / b);
  builder.group()
    ..left(char('+').trim(), (a, op, b) => a + b)
    ..left(char('-').trim(), (a, op, b) => a - b);
  return builder.build().end();
}
