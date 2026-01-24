import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'filters/responsive.dart';
import 'tags/alignment.dart';
import 'tags/alert_dialog.dart';
import 'tags/about_dialog.dart';
import 'tags/app_bar.dart';
import 'tags/autocomplete.dart';
import 'tags/avatar.dart';
import 'tags/background.dart';
import 'tags/bottom_app_bar.dart';
import 'tags/bottom_sheet.dart';
import 'tags/bottom_nav.dart';
import 'tags/date_picker.dart';
import 'tags/badge.dart';
import 'tags/breakpoint.dart';
import 'tags/button.dart';
import 'tags/button_variants.dart';
import 'tags/card.dart';
import 'tags/chip.dart';
import 'tags/child.dart';
import 'tags/checkbox.dart';
import 'tags/column.dart';
import 'tags/container.dart';
import 'tags/custom_scroll_view.dart';
import 'tags/data_table.dart';
import 'tags/decorated_box.dart';
import 'tags/dismissible.dart';
import 'tags/drawer.dart';
import 'tags/dropdown.dart';
import 'tags/expansion_tile.dart';
import 'tags/form.dart';
import 'tags/form_field.dart';
import 'tags/fade_transition.dart';
import 'tags/grid.dart';
import 'tags/hero.dart';
import 'tags/icon.dart';
import 'tags/icon_button.dart';
import 'tags/image.dart';
import 'tags/layout_builder.dart';
import 'tags/list.dart';
import 'tags/list_separator.dart';
import 'tags/list_view_builder.dart';
import 'tags/list_tile_checkbox.dart';
import 'tags/list_tile_radio.dart';
import 'tags/list_tile_switch.dart';
import 'tags/list_tile.dart';
import 'tags/lua.dart';
import 'tags/margin.dart';
import 'tags/material_banner.dart';
import 'tags/navigator.dart';
import 'tags/navigation_bar.dart';
import 'tags/navigation_drawer.dart';
import 'tags/navigation_rail.dart';
import 'tags/paginated_data_table.dart';
import 'tags/padding.dart';
import 'tags/page_view.dart';
import 'tags/popup_menu.dart';
import 'tags/progress.dart';
import 'tags/radio.dart';
import 'tags/row.dart';
import 'tags/reorderable_list.dart';
import 'tags/scroll_view.dart';
import 'tags/segmented.dart';
import 'tags/selectable_text.dart';
import 'tags/shader_mask.dart';
import 'tags/size.dart';
import 'tags/simple_dialog.dart';
import 'tags/spacer.dart';
import 'tags/snackbar.dart';
import 'tags/snack_bar_action.dart';
import 'tags/sliver_app_bar.dart';
import 'tags/sliver_fill_remaining.dart';
import 'tags/sliver_grid.dart';
import 'tags/sliver_list.dart';
import 'tags/sliver_padding.dart';
import 'tags/sliver_persistent_header.dart';
import 'tags/sliver_to_box_adapter.dart';
import 'tags/switch.dart';
import 'tags/tabs.dart';
import 'tags/text.dart';
import 'tags/textfield.dart';
import 'tags/text_form_field.dart';
import 'tags/time_picker.dart';
import 'tags/time_picker_dialog.dart';
import 'tags/toggle_buttons.dart';
import 'tags/stepper.dart';
import 'tags/tab_bar_view.dart';
import 'tags/tab_bar.dart';
import 'tags/table.dart';
import 'tags/slider.dart';
import 'tags/scaffold.dart';
import 'tags/floating_action_button.dart';
import 'tags/property_resolver.dart';
import 'tags/tag_helpers.dart';
import 'generated_tag_registry.dart';
import 'generated/widget_tag_registry.dart';
import 'generated/type_registry.dart' as generated_types;

/// Tracks if global tag registration has been completed.
bool _flutterTagsRegistered = false;

/// Tracks if manual tags have been registered to global TagRegistry.
bool _manualTagsRegistered = false;

/// Lazily-initialized map of manual tag creators.
Map<String, TagCreator>? _manualTagCreators;

/// Gets or creates the map of manual tag creators (built once, reused).
Map<String, TagCreator> _getManualTagCreators() {
  return _manualTagCreators ??= {
    'row': (content, filters) => RowTag(content, filters),
    'column': (content, filters) => ColumnTag(content, filters),
    'container': (content, filters) => ContainerTag(content, filters),
    'child': (content, filters) => ChildTag(content, filters),
    'margin': (content, filters) => MarginTag(content, filters),
    'padding': (content, filters) => PaddingTag(content, filters),
    'alignment': (content, filters) => AlignmentTag(content, filters),
    'fade_transition': (content, filters) =>
        FadeTransitionTag(content, filters),
    'hero': (content, filters) => HeroTag(content, filters),
    'scaffold': (content, filters) => ScaffoldTag(content, filters),
    'app_bar': (content, filters) => AppBarTag(content, filters),
    'bottom_app_bar': (content, filters) => BottomAppBarTag(content, filters),
    'drawer': (content, filters) => DrawerTag(content, filters),
    'size': (content, filters) => SizeTag(content, filters),
    'background': (content, filters) => BackgroundTag(content, filters),
    'decorated_box': (content, filters) => DecoratedBoxTag(
      DecorationPosition.background,
      'decorated_box',
      content,
      filters,
    ),
    'foreground_decorated_box': (content, filters) => DecoratedBoxTag(
      DecorationPosition.foreground,
      'foreground_decorated_box',
      content,
      filters,
    ),
    'shader_mask': (content, filters) => ShaderMaskTag(content, filters),
    'breakpoint': (content, filters) => BreakpointTag(content, filters),
    'card': (content, filters) => CardTag(content, filters),
    'alert_dialog': (content, filters) => AlertDialogTag(content, filters),
    'simple_dialog': (content, filters) => SimpleDialogTag(content, filters),
    'about_dialog': (content, filters) => AboutDialogTag(content, filters),
    'material_banner': (content, filters) =>
        MaterialBannerTag(content, filters),
    'snackbar': (content, filters) => SnackBarTag(content, filters),
    'snack_bar': (content, filters) => SnackBarTag(content, filters),
    'snack_bar_action': (content, filters) =>
        SnackBarActionTag(content, filters),
    'bottom_sheet': (content, filters) => BottomSheetTag(content, filters),
    'popup_menu': (content, filters) => PopupMenuTag(content, filters),
    'popup_menu_item': (content, filters) => PopupMenuItemTag(content, filters),
    'popup_menu_divider': (content, filters) =>
        PopupMenuDividerTag(content, filters),
    'lua': (content, filters) => LuaTag(content, filters),
    'segmented': (content, filters) => SegmentedControlTag(content, filters),
    'segmented_control': (content, filters) =>
        SegmentedControlTag(content, filters),
    'toggle_buttons': (content, filters) => ToggleButtonsTag(content, filters),
    'dropdown': (content, filters) => DropdownTag(content, filters),
    'expansion_tile': (content, filters) => ExpansionTileTag(content, filters),
    'stepper': (content, filters) => StepperTag(content, filters),
    'date_picker': (content, filters) => DatePickerTag(content, filters),
    'time_picker': (content, filters) => TimePickerTag(content, filters),
    'time_picker_dialog': (content, filters) =>
        TimePickerDialogTag(content, filters),
    'layout_builder': (content, filters) => LayoutBuilderTag(content, filters),
    'tabs': (content, filters) => TabsTag(content, filters),
    'tab': (content, filters) => TabTag(content, filters),
    'tab_bar': (content, filters) => TabBarTag(content, filters),
    'tab_bar_view': (content, filters) => TabBarViewTag(content, filters),
    'text': (content, filters) => TextTag(content, filters),
    'selectable_text': (content, filters) =>
        SelectableTextTag(content, filters),
    'chip': (content, filters) => ChipTag.chip(content, filters),
    'action_chip': (content, filters) => ChipTag.action(content, filters),
    'choice_chip': (content, filters) => ChipTag.choice(content, filters),
    'filter_chip': (content, filters) => ChipTag.filter(content, filters),
    'input_chip': (content, filters) => ChipTag.input(content, filters),
    'badge': (content, filters) => BadgeTag(content, filters),
    'avatar': (content, filters) => AvatarTag(content, filters),
    'button': (content, filters) => ButtonTag(content, filters),
    'elevated_button': (content, filters) => MaterialButtonTag(
      MaterialButtonVariant.elevated,
      'elevated_button',
      content,
      filters,
    ),
    'outlined_button': (content, filters) => MaterialButtonTag(
      MaterialButtonVariant.outlined,
      'outlined_button',
      content,
      filters,
    ),
    'filled_button': (content, filters) => MaterialButtonTag(
      MaterialButtonVariant.filled,
      'filled_button',
      content,
      filters,
    ),
    'icon_button': (content, filters) => IconButtonTag(
      IconButtonVariant.standard,
      'icon_button',
      content,
      filters,
    ),
    'icon_button_filled': (content, filters) => IconButtonTag(
      IconButtonVariant.filled,
      'icon_button_filled',
      content,
      filters,
    ),
    'icon_button_filled_tonal': (content, filters) => IconButtonTag(
      IconButtonVariant.filledTonal,
      'icon_button_filled_tonal',
      content,
      filters,
    ),
    'icon_button_outlined': (content, filters) => IconButtonTag(
      IconButtonVariant.outlined,
      'icon_button_outlined',
      content,
      filters,
    ),
    'floating_action_button': (content, filters) =>
        FloatingActionButtonTag(content, filters),
    'text_button': (content, filters) => ButtonTag(content, filters),
    'spacer': (content, filters) => SpacerTag(content, filters),
    'slider': (content, filters) => SliderTag(content, filters),
    'checkbox': (content, filters) => CheckboxTag(content, filters),
    'radio': (content, filters) => RadioTag(content, filters),
    'progress': (content, filters) =>
        ProgressTag('progress', null, content, filters),
    'linear_progress': (content, filters) =>
        ProgressTag('linear_progress', 'linear', content, filters),
    'circular_progress': (content, filters) =>
        ProgressTag('circular_progress', 'circular', content, filters),
    'list_tile': (content, filters) => ListTileTag(content, filters),
    'checkbox_list_tile': (content, filters) =>
        CheckboxListTileTag(content, filters),
    'radio_list_tile': (content, filters) => RadioListTileTag(content, filters),
    'switch_list_tile': (content, filters) =>
        SwitchListTileTag(content, filters),
    'icon': (content, filters) => IconTag(content, filters),
    'textfield': (content, filters) => TextFieldTag(content, filters),
    'text_field': (content, filters) => TextFieldTag(content, filters),
    'text_form_field': (content, filters) => TextFormFieldTag(content, filters),
    'autocomplete': (content, filters) => AutocompleteTag(content, filters),
    'form': (content, filters) => FormTag(content, filters),
    'form_field': (content, filters) => FormFieldTag(content, filters),
    'scroll_view': (content, filters) =>
        ScrollViewTag('scroll_view', content, filters),
    'single_child_scroll_view': (content, filters) =>
        ScrollViewTag('single_child_scroll_view', content, filters),
    'custom_scroll_view': (content, filters) =>
        CustomScrollViewTag(content, filters),
    'page_view': (content, filters) => PageViewTag(content, filters),
    'sliver_list': (content, filters) => SliverListTag(content, filters),
    'sliver_grid': (content, filters) => SliverGridTag(content, filters),
    'sliver_app_bar': (content, filters) => SliverAppBarTag(content, filters),
    'sliver_padding': (content, filters) => SliverPaddingTag(content, filters),
    'sliver_to_box_adapter': (content, filters) =>
        SliverToBoxAdapterTag(content, filters),
    'sliver_fill_remaining': (content, filters) =>
        SliverFillRemainingTag(content, filters),
    'sliver_persistent_header': (content, filters) =>
        SliverPersistentHeaderTag(content, filters),
    'switch': (content, filters) => SwitchTag(content, filters),
    'list': (content, filters) => ListTag('list', content, filters),
    'list_view': (content, filters) => ListTag('list_view', content, filters),
    'dismissible': (content, filters) => DismissibleTag(content, filters),
    'list_separator': (content, filters) => ListSeparatorTag(content, filters),
    'list_view_builder': (content, filters) =>
        ListViewBuilderTag(content, filters),
    'reorderable_list': (content, filters) =>
        ReorderableListTag('reorderable_list', content, filters),
    'reorderable_list_view': (content, filters) =>
        ReorderableListTag('reorderable_list_view', content, filters),
    'reorderable_list_view_builder': (content, filters) =>
        ReorderableListTag('reorderable_list_view_builder', content, filters),
    'grid': (content, filters) => GridTag('grid', content, filters),
    'grid_view': (content, filters) => GridTag('grid_view', content, filters),
    'table': (content, filters) => TableTag(content, filters),
    'data_table': (content, filters) => DataTableTag(content, filters),
    'paginated_data_table': (content, filters) =>
        PaginatedDataTableTag(content, filters),
    'image': (content, filters) => ImageTag(content, filters),
    'bottom_nav': (content, filters) =>
        BottomNavTag('bottom_nav', content, filters),
    'bottom_navigation_bar': (content, filters) =>
        BottomNavTag('bottom_navigation_bar', content, filters),
    'bottom_nav_item': (content, filters) => BottomNavItemTag(content, filters),
    'navigation_bar': (content, filters) => NavigationBarTag(content, filters),
    'navigation_bar_destination': (content, filters) =>
        NavigationBarDestinationTag(content, filters),
    'navigation_rail': (content, filters) =>
        NavigationRailTag(content, filters),
    'navigation_destination': (content, filters) =>
        NavigationDestinationTag(content, filters),
    'navigation_drawer': (content, filters) =>
        NavigationDrawerTag(content, filters),
    'navigation_drawer_destination': (content, filters) =>
        NavigationDrawerDestinationTag(content, filters),
    'drawer_header': (content, filters) => DrawerHeaderTag(content, filters),
    'navigator': (content, filters) => NavigatorTag(content, filters),
  };
}

/// Registers manual tags to global TagRegistry and optionally to environment.
void _registerManualTags(Environment? environment) {
  final creators = _getManualTagCreators();

  // Register to global TagRegistry only once
  if (!_manualTagsRegistered) {
    final existing = TagRegistry.tags.toSet();
    for (final entry in creators.entries) {
      if (!existing.contains(entry.key)) {
        TagRegistry.register(entry.key, entry.value);
      }
    }
    _manualTagsRegistered = true;
  }

  // Batch register to environment's local tags if provided
  if (environment != null) {
    final localTags =
        environment.getRegister('tags') as Map<String, TagCreator>? ??
        <String, TagCreator>{};
    localTags.addAll(creators);
    environment.setRegister('tags', localTags);
  }
}

void registerFlutterTags({Environment? environment}) {
  // Only register global tags once
  if (!_flutterTagsRegistered) {
    registerBuiltInTags();
    _flutterTagsRegistered = true;
  }
  final generatedOnly =
      environment?.getRegister('_liquify_flutter_generated_only') == true ||
      const bool.fromEnvironment('LIQUIFY_GENERATED_ONLY', defaultValue: false);
  if (environment != null) {
    registerFlutterFilters(environment);
    ensurePropertyResolver(environment);
    setStrictPropertyParsing(
      environment.getRegister('_liquify_flutter_strict_props') == true,
    );
    setStrictTagParsing(
      environment.getRegister('_liquify_flutter_strict_tags') == true ||
          environment.getRegister('_liquify_flutter_strict_props') == true,
    );
    environment.setRegister(
      'liquify_flutter_type_registry',
      generated_types.generatedTypeRegistry,
    );
    environment.setRegister(
      'liquify_flutter_type_parsers',
      generated_types.generatedValueParsers,
    );
    environment.setRegister(
      'liquify_flutter_type_parsers_evaluator',
      generated_types.generatedEvaluatorParsers,
    );
  }
  registerGeneratedWidgetTags(environment);
  if (generatedOnly) {
    // Just register lua tag for generated-only mode
    if (environment != null) {
      final localTags =
          environment.getRegister('tags') as Map<String, TagCreator>? ??
          <String, TagCreator>{};
      localTags['lua'] = (content, filters) => LuaTag(content, filters);
      environment.setRegister('tags', localTags);
    }
    if (!TagRegistry.tags.contains('lua')) {
      TagRegistry.register(
        'lua',
        (content, filters) => LuaTag(content, filters),
      );
    }
  }
  if (!generatedOnly) {
    registerGeneratedTags(environment);
    _registerManualTags(environment);
  }
}
