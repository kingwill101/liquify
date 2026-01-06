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

void registerFlutterTags({Environment? environment}) {
  registerBuiltInTags();
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
    _registerTag(
      'lua',
      (content, filters) => LuaTag(content, filters),
      environment,
    );
  }
  if (!generatedOnly) {
    registerGeneratedTags(environment);
    _registerTag(
      'row',
      (content, filters) => RowTag(content, filters),
      environment,
    );
    _registerTag(
      'column',
      (content, filters) => ColumnTag(content, filters),
      environment,
    );
    _registerTag(
      'container',
      (content, filters) => ContainerTag(content, filters),
      environment,
    );
    _registerTag(
      'child',
      (content, filters) => ChildTag(content, filters),
      environment,
    );
    _registerTag(
      'margin',
      (content, filters) => MarginTag(content, filters),
      environment,
    );
    _registerTag(
      'padding',
      (content, filters) => PaddingTag(content, filters),
      environment,
    );
    _registerTag(
      'alignment',
      (content, filters) => AlignmentTag(content, filters),
      environment,
    );
    _registerTag(
      'fade_transition',
      (content, filters) => FadeTransitionTag(content, filters),
      environment,
    );
    _registerTag(
      'hero',
      (content, filters) => HeroTag(content, filters),
      environment,
    );
    _registerTag(
      'scaffold',
      (content, filters) => ScaffoldTag(content, filters),
      environment,
    );
    _registerTag(
      'app_bar',
      (content, filters) => AppBarTag(content, filters),
      environment,
    );
    _registerTag(
      'bottom_app_bar',
      (content, filters) => BottomAppBarTag(content, filters),
      environment,
    );
    _registerTag(
      'drawer',
      (content, filters) => DrawerTag(content, filters),
      environment,
    );
    _registerTag(
      'size',
      (content, filters) => SizeTag(content, filters),
      environment,
    );
    _registerTag(
      'background',
      (content, filters) => BackgroundTag(content, filters),
      environment,
    );
    _registerTag(
      'decorated_box',
      (content, filters) => DecoratedBoxTag(
        DecorationPosition.background,
        'decorated_box',
        content,
        filters,
      ),
      environment,
    );
    _registerTag(
      'foreground_decorated_box',
      (content, filters) => DecoratedBoxTag(
        DecorationPosition.foreground,
        'foreground_decorated_box',
        content,
        filters,
      ),
      environment,
    );
    _registerTag(
      'shader_mask',
      (content, filters) => ShaderMaskTag(content, filters),
      environment,
    );
    _registerTag(
      'breakpoint',
      (content, filters) => BreakpointTag(content, filters),
      environment,
    );
    _registerTag(
      'card',
      (content, filters) => CardTag(content, filters),
      environment,
    );
    _registerTag(
      'alert_dialog',
      (content, filters) => AlertDialogTag(content, filters),
      environment,
    );
    _registerTag(
      'simple_dialog',
      (content, filters) => SimpleDialogTag(content, filters),
      environment,
    );
    _registerTag(
      'about_dialog',
      (content, filters) => AboutDialogTag(content, filters),
      environment,
    );
    _registerTag(
      'material_banner',
      (content, filters) => MaterialBannerTag(content, filters),
      environment,
    );
    _registerTag(
      'snackbar',
      (content, filters) => SnackBarTag(content, filters),
      environment,
    );
    _registerTag(
      'snack_bar',
      (content, filters) => SnackBarTag(content, filters),
      environment,
    );
    _registerTag(
      'snack_bar_action',
      (content, filters) => SnackBarActionTag(content, filters),
      environment,
    );
    _registerTag(
      'bottom_sheet',
      (content, filters) => BottomSheetTag(content, filters),
      environment,
    );
    _registerTag(
      'popup_menu',
      (content, filters) => PopupMenuTag(content, filters),
      environment,
    );
    _registerTag(
      'popup_menu_item',
      (content, filters) => PopupMenuItemTag(content, filters),
      environment,
    );
    _registerTag(
      'popup_menu_divider',
      (content, filters) => PopupMenuDividerTag(content, filters),
      environment,
    );
    _registerTag(
      'lua',
      (content, filters) => LuaTag(content, filters),
      environment,
    );
    _registerTag(
      'segmented',
      (content, filters) => SegmentedControlTag(content, filters),
      environment,
    );
    _registerTag(
      'segmented_control',
      (content, filters) => SegmentedControlTag(content, filters),
      environment,
    );
    _registerTag(
      'toggle_buttons',
      (content, filters) => ToggleButtonsTag(content, filters),
      environment,
    );
    _registerTag(
      'dropdown',
      (content, filters) => DropdownTag(content, filters),
      environment,
    );
    _registerTag(
      'expansion_tile',
      (content, filters) => ExpansionTileTag(content, filters),
      environment,
    );
    _registerTag(
      'stepper',
      (content, filters) => StepperTag(content, filters),
      environment,
    );
    _registerTag(
      'date_picker',
      (content, filters) => DatePickerTag(content, filters),
      environment,
    );
    _registerTag(
      'time_picker',
      (content, filters) => TimePickerTag(content, filters),
      environment,
    );
    _registerTag(
      'time_picker_dialog',
      (content, filters) => TimePickerDialogTag(content, filters),
      environment,
    );
    _registerTag(
      'layout_builder',
      (content, filters) => LayoutBuilderTag(content, filters),
      environment,
    );
    _registerTag(
      'tabs',
      (content, filters) => TabsTag(content, filters),
      environment,
    );
    _registerTag(
      'tab',
      (content, filters) => TabTag(content, filters),
      environment,
    );
    _registerTag(
      'tab_bar',
      (content, filters) => TabBarTag(content, filters),
      environment,
    );
    _registerTag(
      'tab_bar_view',
      (content, filters) => TabBarViewTag(content, filters),
      environment,
    );
    _registerTag(
      'text',
      (content, filters) => TextTag(content, filters),
      environment,
    );
    _registerTag(
      'selectable_text',
      (content, filters) => SelectableTextTag(content, filters),
      environment,
    );
    _registerTag(
      'chip',
      (content, filters) => ChipTag.chip(content, filters),
      environment,
    );
    _registerTag(
      'action_chip',
      (content, filters) => ChipTag.action(content, filters),
      environment,
    );
    _registerTag(
      'choice_chip',
      (content, filters) => ChipTag.choice(content, filters),
      environment,
    );
    _registerTag(
      'filter_chip',
      (content, filters) => ChipTag.filter(content, filters),
      environment,
    );
    _registerTag(
      'input_chip',
      (content, filters) => ChipTag.input(content, filters),
      environment,
    );
    _registerTag(
      'badge',
      (content, filters) => BadgeTag(content, filters),
      environment,
    );
    _registerTag(
      'avatar',
      (content, filters) => AvatarTag(content, filters),
      environment,
    );
    _registerTag(
      'button',
      (content, filters) => ButtonTag(content, filters),
      environment,
    );
    _registerTag(
      'elevated_button',
      (content, filters) => MaterialButtonTag(
        MaterialButtonVariant.elevated,
        'elevated_button',
        content,
        filters,
      ),
      environment,
    );
    _registerTag(
      'outlined_button',
      (content, filters) => MaterialButtonTag(
        MaterialButtonVariant.outlined,
        'outlined_button',
        content,
        filters,
      ),
      environment,
    );
    _registerTag(
      'filled_button',
      (content, filters) => MaterialButtonTag(
        MaterialButtonVariant.filled,
        'filled_button',
        content,
        filters,
      ),
      environment,
    );
    _registerTag(
      'icon_button',
      (content, filters) => IconButtonTag(
        IconButtonVariant.standard,
        'icon_button',
        content,
        filters,
      ),
      environment,
    );
    _registerTag(
      'icon_button_filled',
      (content, filters) => IconButtonTag(
        IconButtonVariant.filled,
        'icon_button_filled',
        content,
        filters,
      ),
      environment,
    );
    _registerTag(
      'icon_button_filled_tonal',
      (content, filters) => IconButtonTag(
        IconButtonVariant.filledTonal,
        'icon_button_filled_tonal',
        content,
        filters,
      ),
      environment,
    );
    _registerTag(
      'icon_button_outlined',
      (content, filters) => IconButtonTag(
        IconButtonVariant.outlined,
        'icon_button_outlined',
        content,
        filters,
      ),
      environment,
    );
    _registerTag(
      'floating_action_button',
      (content, filters) => FloatingActionButtonTag(content, filters),
      environment,
    );
    _registerTag(
      'text_button',
      (content, filters) => ButtonTag(content, filters),
      environment,
    );
    _registerTag(
      'spacer',
      (content, filters) => SpacerTag(content, filters),
      environment,
    );
    _registerTag(
      'slider',
      (content, filters) => SliderTag(content, filters),
      environment,
    );
    _registerTag(
      'checkbox',
      (content, filters) => CheckboxTag(content, filters),
      environment,
    );
    _registerTag(
      'radio',
      (content, filters) => RadioTag(content, filters),
      environment,
    );
    _registerTag(
      'progress',
      (content, filters) => ProgressTag('progress', null, content, filters),
      environment,
    );
    _registerTag(
      'linear_progress',
      (content, filters) =>
          ProgressTag('linear_progress', 'linear', content, filters),
      environment,
    );
    _registerTag(
      'circular_progress',
      (content, filters) =>
          ProgressTag('circular_progress', 'circular', content, filters),
      environment,
    );
    _registerTag(
      'list_tile',
      (content, filters) => ListTileTag(content, filters),
      environment,
    );
    _registerTag(
      'checkbox_list_tile',
      (content, filters) => CheckboxListTileTag(content, filters),
      environment,
    );
    _registerTag(
      'radio_list_tile',
      (content, filters) => RadioListTileTag(content, filters),
      environment,
    );
    _registerTag(
      'switch_list_tile',
      (content, filters) => SwitchListTileTag(content, filters),
      environment,
    );
    _registerTag(
      'icon',
      (content, filters) => IconTag(content, filters),
      environment,
    );
    _registerTag(
      'textfield',
      (content, filters) => TextFieldTag(content, filters),
      environment,
    );
    _registerTag(
      'text_field',
      (content, filters) => TextFieldTag(content, filters),
      environment,
    );
    _registerTag(
      'text_form_field',
      (content, filters) => TextFormFieldTag(content, filters),
      environment,
    );
    _registerTag(
      'autocomplete',
      (content, filters) => AutocompleteTag(content, filters),
      environment,
    );
    _registerTag(
      'form',
      (content, filters) => FormTag(content, filters),
      environment,
    );
    _registerTag(
      'form_field',
      (content, filters) => FormFieldTag(content, filters),
      environment,
    );
    _registerTag(
      'scroll_view',
      (content, filters) => ScrollViewTag('scroll_view', content, filters),
      environment,
    );
    _registerTag(
      'single_child_scroll_view',
      (content, filters) =>
          ScrollViewTag('single_child_scroll_view', content, filters),
      environment,
    );
    _registerTag(
      'custom_scroll_view',
      (content, filters) => CustomScrollViewTag(content, filters),
      environment,
    );
    _registerTag(
      'page_view',
      (content, filters) => PageViewTag(content, filters),
      environment,
    );
    _registerTag(
      'sliver_list',
      (content, filters) => SliverListTag(content, filters),
      environment,
    );
    _registerTag(
      'sliver_grid',
      (content, filters) => SliverGridTag(content, filters),
      environment,
    );
    _registerTag(
      'sliver_app_bar',
      (content, filters) => SliverAppBarTag(content, filters),
      environment,
    );
    _registerTag(
      'sliver_padding',
      (content, filters) => SliverPaddingTag(content, filters),
      environment,
    );
    _registerTag(
      'sliver_to_box_adapter',
      (content, filters) => SliverToBoxAdapterTag(content, filters),
      environment,
    );
    _registerTag(
      'sliver_fill_remaining',
      (content, filters) => SliverFillRemainingTag(content, filters),
      environment,
    );
    _registerTag(
      'sliver_persistent_header',
      (content, filters) => SliverPersistentHeaderTag(content, filters),
      environment,
    );
    _registerTag(
      'switch',
      (content, filters) => SwitchTag(content, filters),
      environment,
    );
    _registerTag(
      'list',
      (content, filters) => ListTag('list', content, filters),
      environment,
    );
    _registerTag(
      'list_view',
      (content, filters) => ListTag('list_view', content, filters),
      environment,
    );
    _registerTag(
      'dismissible',
      (content, filters) => DismissibleTag(content, filters),
      environment,
    );
    _registerTag(
      'list_separator',
      (content, filters) => ListSeparatorTag(content, filters),
      environment,
    );
    _registerTag(
      'list_view_builder',
      (content, filters) => ListViewBuilderTag(content, filters),
      environment,
    );
    _registerTag(
      'reorderable_list',
      (content, filters) =>
          ReorderableListTag('reorderable_list', content, filters),
      environment,
    );
    _registerTag(
      'reorderable_list_view',
      (content, filters) =>
          ReorderableListTag('reorderable_list_view', content, filters),
      environment,
    );
    _registerTag(
      'reorderable_list_view_builder',
      (content, filters) =>
          ReorderableListTag('reorderable_list_view_builder', content, filters),
      environment,
    );
    _registerTag(
      'grid',
      (content, filters) => GridTag('grid', content, filters),
      environment,
    );
    _registerTag(
      'grid_view',
      (content, filters) => GridTag('grid_view', content, filters),
      environment,
    );
    _registerTag(
      'table',
      (content, filters) => TableTag(content, filters),
      environment,
    );
    _registerTag(
      'data_table',
      (content, filters) => DataTableTag(content, filters),
      environment,
    );
    _registerTag(
      'paginated_data_table',
      (content, filters) => PaginatedDataTableTag(content, filters),
      environment,
    );
    _registerTag(
      'image',
      (content, filters) => ImageTag(content, filters),
      environment,
    );
    _registerTag(
      'bottom_nav',
      (content, filters) => BottomNavTag('bottom_nav', content, filters),
      environment,
    );
    _registerTag(
      'bottom_navigation_bar',
      (content, filters) =>
          BottomNavTag('bottom_navigation_bar', content, filters),
      environment,
    );
    _registerTag(
      'bottom_nav_item',
      (content, filters) => BottomNavItemTag(content, filters),
      environment,
    );
    _registerTag(
      'navigation_bar',
      (content, filters) => NavigationBarTag(content, filters),
      environment,
    );
    _registerTag(
      'navigation_bar_destination',
      (content, filters) => NavigationBarDestinationTag(content, filters),
      environment,
    );
    _registerTag(
      'navigation_rail',
      (content, filters) => NavigationRailTag(content, filters),
      environment,
    );
    _registerTag(
      'navigation_destination',
      (content, filters) => NavigationDestinationTag(content, filters),
      environment,
    );
    _registerTag(
      'navigation_drawer',
      (content, filters) => NavigationDrawerTag(content, filters),
      environment,
    );
    _registerTag(
      'navigation_drawer_destination',
      (content, filters) => NavigationDrawerDestinationTag(content, filters),
      environment,
    );
    _registerTag(
      'drawer_header',
      (content, filters) => DrawerHeaderTag(content, filters),
      environment,
    );
    _registerTag(
      'navigator',
      (content, filters) => NavigatorTag(content, filters),
      environment,
    );
  }
}

void _registerTag(String name, TagCreator creator, Environment? environment) {
  if (TagRegistry.tags.contains(name)) {
    return;
  }
  TagRegistry.register(name, creator);
  if (environment != null) {
    environment.registerLocalTag(name, creator);
  }
}
