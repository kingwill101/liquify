import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_utils.dart';

void main() {
  testWidgets('about_dialog renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% about_dialog %}{% endabout_dialog %}
      '''
    );
    expect(find.byType(AboutDialog), findsWidgets);
  });
  testWidgets('absorb_pointer renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% absorb_pointer %}{% endabsorb_pointer %}
      '''
    );
    expect(find.byType(AbsorbPointer), findsWidgets);
  });
  testWidgets('action_chip renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% action_chip label: "Sample" %}{% endaction_chip %}
      '''
    );
    expect(find.byType(ActionChip), findsWidgets);
  });
  testWidgets('alert_dialog renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% alert_dialog %}{% endalert_dialog %}
      '''
    );
    expect(find.byType(AlertDialog), findsWidgets);
  });
  testWidgets('align renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% align %}{% endalign %}
      '''
    );
    expect(find.byType(Align), findsWidgets);
  });
  testWidgets('animated_align renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% animated_align alignment: "center" duration: "200ms" %}{% endanimated_align %}
      '''
    );
    expect(find.byType(AnimatedAlign), findsWidgets);
  });
  testWidgets('animated_container renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% animated_container duration: "200ms" %}{% endanimated_container %}
      '''
    );
    expect(find.byType(AnimatedContainer), findsWidgets);
  });
  testWidgets('animated_default_text_style renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% animated_default_text_style duration: "200ms" style: style %}{% endanimated_default_text_style %}
      '''
      ,data: {
        'style': const TextStyle(fontSize: 14),
      }
    );
    expect(find.byType(AnimatedDefaultTextStyle), findsWidgets);
  });
  testWidgets('animated_opacity renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% animated_opacity duration: "200ms" opacity: 1 %}{% endanimated_opacity %}
      '''
    );
    expect(find.byType(AnimatedOpacity), findsWidgets);
  });
  testWidgets('animated_padding renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% animated_padding duration: "200ms" padding: 8 %}{% endanimated_padding %}
      '''
    );
    expect(find.byType(AnimatedPadding), findsWidgets);
  });
  testWidgets('animated_positioned renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% stack %}{% animated_positioned duration: "200ms" left: 0 top: 0 %}{% text data: "Sample" %}{% endanimated_positioned %}{% endstack %}
      '''
    );
    expect(find.byType(AnimatedPositioned), findsWidgets);
  });
  testWidgets('animated_rotation renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% animated_rotation duration: "200ms" turns: 1 %}{% endanimated_rotation %}
      '''
    );
    expect(find.byType(AnimatedRotation), findsWidgets);
  });
  testWidgets('animated_scale renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% animated_scale duration: "200ms" scale: 1 %}{% endanimated_scale %}
      '''
    );
    expect(find.byType(AnimatedScale), findsWidgets);
  });
  testWidgets('animated_slide renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% animated_slide duration: "200ms" offset: "0.1,0.1" %}{% endanimated_slide %}
      '''
    );
    expect(find.byType(AnimatedSlide), findsWidgets);
  });
  testWidgets('app_bar renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% app_bar %}{% endapp_bar %}
      '''
    );
    expect(find.byType(AppBar), findsWidgets);
  });
  testWidgets('aspect_ratio renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% aspect_ratio aspectRatio: 1 %}{% endaspect_ratio %}
      '''
    );
    expect(find.byType(AspectRatio), findsWidgets);
  });
  testWidgets('autocomplete renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% autocomplete optionsBuilder: optionsBuilder %}{% endautocomplete %}
      '''
      ,data: {
        'optionsBuilder': (TextEditingValue value) async => <Object>["Option 1", "Option 2"],
      }
    );
    expect(find.byType(Autocomplete), findsWidgets);
  });
  testWidgets('badge renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% badge %}{% endbadge %}
      '''
    );
    expect(find.byType(Badge), findsWidgets);
  });
  testWidgets('baseline renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% baseline baseline: 1 baselineType: "alphabetic" %}{% endbaseline %}
      '''
    );
    expect(find.byType(Baseline), findsWidgets);
  });
  testWidgets('bottom_app_bar renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% bottom_app_bar %}{% endbottom_app_bar %}
      '''
    );
    expect(find.byType(BottomAppBar), findsWidgets);
  });
  testWidgets('calendar_date_picker renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% calendar_date_picker firstDate: "2024-01-01" initialDate: "2024-01-01" lastDate: "2024-01-01" onDateChanged: onDateChanged %}{% endcalendar_date_picker %}
      '''
      ,data: {
        'onDateChanged': (dynamic _) {},
      }
    );
    expect(find.byType(CalendarDatePicker), findsWidgets);
  });
  testWidgets('card renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% card %}{% endcard %}
      '''
    );
    expect(find.byType(Card), findsWidgets);
  });
  testWidgets('center renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% center %}{% endcenter %}
      '''
    );
    expect(find.byType(Center), findsWidgets);
  });
  testWidgets('checkbox renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% checkbox onChanged: onChanged value: true %}{% endcheckbox %}
      '''
      ,data: {
        'onChanged': (dynamic _) {},
      }
    );
    expect(find.byType(Checkbox), findsWidgets);
  });
  testWidgets('checkbox_list_tile renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% checkbox_list_tile onChanged: onChanged value: true %}{% endcheckbox_list_tile %}
      '''
      ,data: {
        'onChanged': (dynamic _) {},
      }
    );
    expect(find.byType(CheckboxListTile), findsWidgets);
  });
  testWidgets('chip renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% chip label: "Sample" %}{% endchip %}
      '''
    );
    expect(find.byType(Chip), findsWidgets);
  });
  testWidgets('choice_chip renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% choice_chip label: "Sample" selected: true %}{% endchoice_chip %}
      '''
    );
    expect(find.byType(ChoiceChip), findsWidgets);
  });
  testWidgets('circle_avatar renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% circle_avatar %}{% endcircle_avatar %}
      '''
    );
    expect(find.byType(CircleAvatar), findsWidgets);
  });
  testWidgets('circular_progress_indicator renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% circular_progress_indicator %}{% endcircular_progress_indicator %}
      '''
    );
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
  testWidgets('clip_oval renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% clip_oval %}{% endclip_oval %}
      '''
    );
    expect(find.byType(ClipOval), findsWidgets);
  });
  testWidgets('clip_path renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% clip_path %}{% endclip_path %}
      '''
    );
    expect(find.byType(ClipPath), findsWidgets);
  });
  testWidgets('clip_r_rect renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% clip_r_rect %}{% endclip_r_rect %}
      '''
    );
    expect(find.byType(ClipRRect), findsWidgets);
  });
  testWidgets('clip_rect renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% clip_rect %}{% endclip_rect %}
      '''
    );
    expect(find.byType(ClipRect), findsWidgets);
  });
  testWidgets('colored_box renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% colored_box color: "#FF0000" %}{% text data: "Sample" %}{% endcolored_box %}
      '''
    );
    expect(find.byType(ColoredBox), findsWidgets);
  });
  testWidgets('column renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% column %}{% endcolumn %}
      '''
    );
    expect(find.byType(Column), findsWidgets);
  });
  testWidgets('constrained_box renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% constrained_box constraints: constraints %}{% endconstrained_box %}
      '''
      ,data: {
        'constraints': const BoxConstraints(minWidth: 0, maxWidth: 100, minHeight: 0, maxHeight: 100),
      }
    );
    expect(find.byType(ConstrainedBox), findsWidgets);
  });
  testWidgets('container renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% container %}{% endcontainer %}
      '''
    );
    expect(find.byType(Container), findsWidgets);
  });
  testWidgets('custom_scroll_view renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% custom_scroll_view %}{% endcustom_scroll_view %}
      '''
    );
    expect(find.byType(CustomScrollView), findsWidgets);
  });
  testWidgets('data_table renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% data_table columns: columns rows: rows %}{% enddata_table %}
      '''
      ,data: {
        'columns': const [DataColumn(label: Text('Name'))],
        'rows': const [DataRow(cells: [DataCell(Text('Alice'))])],
      }
    );
    expect(find.byType(DataTable), findsWidgets);
  });
  testWidgets('date_picker_dialog renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% date_picker_dialog firstDate: "2024-01-01" lastDate: "2024-01-01" %}{% enddate_picker_dialog %}
      '''
    );
    expect(find.byType(DatePickerDialog), findsWidgets);
  });
  testWidgets('decorated_box renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% decorated_box decoration: decoration %}{% enddecorated_box %}
      '''
      ,data: {
        'decoration': const BoxDecoration(color: Color(0xFFFF0000)),
      }
    );
    expect(find.byType(DecoratedBox), findsWidgets);
  });
  testWidgets('default_tab_controller renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% default_tab_controller length: 1 %}{% enddefault_tab_controller %}
      '''
    );
    expect(find.byType(DefaultTabController), findsWidgets);
  });
  testWidgets('default_text_style renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% default_text_style style: style %}{% enddefault_text_style %}
      '''
      ,data: {
        'style': const TextStyle(fontSize: 14),
      }
    );
    expect(find.byType(DefaultTextStyle), findsWidgets);
  });
  testWidgets('dismissible renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% dismissible key: "item1" %}{% text data: "Swipe me" %}{% enddismissible %}
      '''
    );
    expect(find.byType(Dismissible), findsWidgets);
  });
  testWidgets('divider renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% divider %}{% enddivider %}
      '''
    );
    expect(find.byType(Divider), findsWidgets);
  });
  testWidgets('drawer renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% drawer %}{% enddrawer %}
      '''
    );
    expect(find.byType(Drawer), findsWidgets);
  });
  testWidgets('drawer_header renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% drawer_header %}{% enddrawer_header %}
      '''
    );
    expect(find.byType(DrawerHeader), findsWidgets);
  });
  testWidgets('dropdown_button renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% dropdown_button items: items onChanged: onChanged %}{% enddropdown_button %}
      '''
      ,data: {
        'items': [const DropdownMenuItem(value: "Sample", child: Text("Sample"))],
        'onChanged': (dynamic _) {},
      }
    );
    expect(find.byType(DropdownButton), findsWidgets);
  });
  testWidgets('elevated_button renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% elevated_button onPressed: onPressed %}{% endelevated_button %}
      '''
      ,data: {
        'onPressed': TapActionDrop(() {}),
      }
    );
    expect(find.byType(ElevatedButton), findsWidgets);
  });
  testWidgets('expanded renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% row %}{% expanded %}{% text data: "Sample" %}{% endexpanded %}{% endrow %}
      '''
    );
    expect(find.byType(Expanded), findsWidgets);
  });
  testWidgets('expansion_tile renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% expansion_tile title: "Sample" %}{% endexpansion_tile %}
      '''
    );
    expect(find.byType(ExpansionTile), findsWidgets);
  });
  testWidgets('fade_transition renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% fade_transition opacity: opacity %}{% endfade_transition %}
      '''
      ,data: {
        'opacity': const AlwaysStoppedAnimation<double>(1.0),
      }
    );
    expect(find.byType(FadeTransition), findsWidgets);
  });
  testWidgets('filled_button renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% filled_button onPressed: onPressed %}{% endfilled_button %}
      '''
      ,data: {
        'onPressed': TapActionDrop(() {}),
      }
    );
    expect(find.byType(FilledButton), findsWidgets);
  });
  testWidgets('filter_chip renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% filter_chip label: "Sample" onSelected: onSelected %}{% endfilter_chip %}
      '''
      ,data: {
        'onSelected': (dynamic _) {},
      }
    );
    expect(find.byType(FilterChip), findsWidgets);
  });
  testWidgets('fitted_box renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% fitted_box %}{% endfitted_box %}
      '''
    );
    expect(find.byType(FittedBox), findsWidgets);
  });
  testWidgets('flex renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% flex direction: "horizontal" %}{% endflex %}
      '''
    );
    expect(find.byType(Flex), findsWidgets);
  });
  testWidgets('flexible renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% row %}{% flexible %}{% text data: "Sample" %}{% endflexible %}{% endrow %}
      '''
    );
    expect(find.byType(Flexible), findsWidgets);
  });
  testWidgets('floating_action_button renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% floating_action_button onPressed: onPressed %}{% endfloating_action_button %}
      '''
      ,data: {
        'onPressed': TapActionDrop(() {}),
      }
    );
    expect(find.byType(FloatingActionButton), findsWidgets);
  });
  testWidgets('form renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% form %}{% endform %}
      '''
    );
    expect(find.byType(Form), findsWidgets);
  });
  testWidgets('form_field renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% form_field builder: builder %}{% endform_field %}
      '''
      ,data: {
        'builder': (dynamic state) => const Text('Field'),
      }
    );
    expect(find.byWidgetPredicate((widget) => widget is FormField), findsWidgets);
  });
  testWidgets('fractional_translation renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% fractional_translation translation: "0.1,0.1" %}{% endfractional_translation %}
      '''
    );
    expect(find.byType(FractionalTranslation), findsWidgets);
  });
  testWidgets('fractionally_sized_box renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% fractionally_sized_box %}{% endfractionally_sized_box %}
      '''
    );
    expect(find.byType(FractionallySizedBox), findsWidgets);
  });
  testWidgets('gesture_detector renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% gesture_detector %}{% endgesture_detector %}
      '''
    );
    expect(find.byType(GestureDetector), findsWidgets);
  });
  testWidgets('grid_view renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% grid_view gridDelegate: gridDelegate %}{% text data: "Item" %}{% endgrid_view %}
      '''
      ,data: {
        'gridDelegate': const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
      }
    );
    expect(find.byType(GridView), findsWidgets);
  });
  testWidgets('hero renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% hero tag: "sample" %}{% endhero %}
      '''
    );
    expect(find.byType(Hero), findsWidgets);
  });
  testWidgets('icon renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% icon icon: "add" %}{% endicon %}
      '''
    );
    expect(find.byType(Icon), findsWidgets);
  });
  testWidgets('icon_button renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% icon_button icon: "add" onPressed: onPressed %}{% endicon_button %}
      '''
      ,data: {
        'onPressed': TapActionDrop(() {}),
      }
    );
    expect(find.byType(IconButton), findsWidgets);
  });
  testWidgets('icon_theme renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% icon_theme data: data %}{% endicon_theme %}
      '''
      ,data: {
        'data': const IconThemeData(size: 16),
      }
    );
    expect(find.byType(IconTheme), findsWidgets);
  });
  testWidgets('ignore_pointer renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% ignore_pointer ignoring: true %}{% text data: "Sample" %}{% endignore_pointer %}
      '''
    );
    expect(find.byType(IgnorePointer), findsWidgets);
  });
  testWidgets('image renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% image image: image width: 1 height: 1 %}{% endimage %}
      '''
      ,data: {
        'image': MemoryImage(Uint8List.fromList(const <int>[0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A,0x00,0x00,0x00,0x0D,0x49,0x48,0x44,0x52,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x08,0x06,0x00,0x00,0x00,0x1F,0x15,0xC4,0x89,0x00,0x00,0x00,0x0A,0x49,0x44,0x41,0x54,0x78,0x9C,0x63,0x00,0x01,0x00,0x00,0x05,0x00,0x01,0x0D,0x0A,0x2D,0xB4,0x00,0x00,0x00,0x00,0x49,0x45,0x4E,0x44,0xAE,0x42,0x60,0x82])),
      }
    );
    expect(find.byType(Image), findsWidgets);
  });
  testWidgets('indexed_stack renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% indexed_stack %}{% endindexed_stack %}
      '''
    );
    expect(find.byType(IndexedStack), findsWidgets);
  });
  testWidgets('input_chip renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% input_chip label: "Sample" %}{% endinput_chip %}
      '''
    );
    expect(find.byType(InputChip), findsWidgets);
  });
  testWidgets('intrinsic_height renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% intrinsic_height %}{% endintrinsic_height %}
      '''
    );
    expect(find.byType(IntrinsicHeight), findsWidgets);
  });
  testWidgets('intrinsic_width renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% intrinsic_width %}{% endintrinsic_width %}
      '''
    );
    expect(find.byType(IntrinsicWidth), findsWidgets);
  });
  testWidgets('layout_builder renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% layout_builder builder: builder %}{% endlayout_builder %}
      '''
      ,data: {
        'builder': (BuildContext context, BoxConstraints constraints) => const SizedBox(),
      }
    );
    expect(find.byType(LayoutBuilder), findsWidgets);
  });
  testWidgets('limited_box renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% limited_box %}{% endlimited_box %}
      '''
    );
    expect(find.byType(LimitedBox), findsWidgets);
  });
  testWidgets('linear_progress_indicator renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% linear_progress_indicator %}{% endlinear_progress_indicator %}
      '''
    );
    expect(find.byType(LinearProgressIndicator), findsWidgets);
  });
  testWidgets('list_tile renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% list_tile %}{% endlist_tile %}
      '''
    );
    expect(find.byType(ListTile), findsWidgets);
  });
  testWidgets('list_view renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% list_view %}{% endlist_view %}
      '''
    );
    expect(find.byType(ListView), findsWidgets);
  });
  testWidgets('listener renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% listener %}{% endlistener %}
      '''
    );
    expect(find.byType(Listener), findsWidgets);
  });
  testWidgets('material_banner renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% material_banner actions: actions content: "Sample" %}{% endmaterial_banner %}
      '''
      ,data: {
        'actions': const [TextButton(onPressed: null, child: Text('OK'))],
      }
    );
    expect(find.byType(MaterialBanner), findsWidgets);
  });
  testWidgets('merge_semantics renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% merge_semantics %}{% endmerge_semantics %}
      '''
    );
    expect(find.byType(MergeSemantics), findsWidgets);
  });
  testWidgets('mouse_region renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% mouse_region %}{% endmouse_region %}
      '''
    );
    expect(find.byType(MouseRegion), findsWidgets);
  });
  testWidgets('navigation_drawer renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% navigation_drawer %}{% endnavigation_drawer %}
      '''
    );
    expect(find.byType(NavigationDrawer), findsWidgets);
  });
  testWidgets('offstage renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% offstage %}{% endoffstage %}
      '''
    );
    expect(find.byType(Offstage), findsWidgets);
  });
  testWidgets('opacity renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% opacity opacity: 1 %}{% endopacity %}
      '''
    );
    expect(find.byType(Opacity), findsWidgets);
  });
  testWidgets('outlined_button renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% outlined_button onPressed: onPressed %}{% endoutlined_button %}
      '''
      ,data: {
        'onPressed': TapActionDrop(() {}),
      }
    );
    expect(find.byType(OutlinedButton), findsWidgets);
  });
  testWidgets('overflow_box renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% overflow_box %}{% endoverflow_box %}
      '''
    );
    expect(find.byType(OverflowBox), findsWidgets);
  });
  testWidgets('page_view renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% page_view %}{% text data: "Page" %}{% endpage_view %}
      '''
    );
    expect(find.byType(PageView), findsWidgets);
  });
  testWidgets('physical_model renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% physical_model color: "#FF0000" %}{% endphysical_model %}
      '''
    );
    expect(find.byType(PhysicalModel), findsWidgets);
  });
  testWidgets('placeholder renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% placeholder %}{% endplaceholder %}
      '''
    );
    expect(find.byType(Placeholder), findsWidgets);
  });
  testWidgets('popup_menu_button renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% popup_menu_button itemBuilder: itemBuilder %}{% endpopup_menu_button %}
      '''
      ,data: {
        'itemBuilder': (BuildContext context) => [const PopupMenuItem(value: "Sample", child: Text("Sample"))],
      }
    );
    expect(find.byType(PopupMenuButton), findsWidgets);
  });
  testWidgets('positioned renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% stack %}{% positioned left: 0 top: 0 %}{% text data: "Sample" %}{% endpositioned %}{% endstack %}
      '''
    );
    expect(find.byType(Positioned), findsWidgets);
  });
  testWidgets('reorderable_list_view renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% reorderable_list_view onReorder: onReorder %}{% text data: "Item" key: "item1" %}{% endreorderable_list_view %}
      '''
      ,data: {
        'onReorder': (int oldIndex, int newIndex) {},
      }
    );
    expect(find.byType(ReorderableListView), findsWidgets);
  });
  testWidgets('repaint_boundary renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% repaint_boundary %}{% endrepaint_boundary %}
      '''
    );
    expect(find.byType(RepaintBoundary), findsWidgets);
  });
  testWidgets('rotated_box renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% rotated_box quarterTurns: 1 %}{% endrotated_box %}
      '''
    );
    expect(find.byType(RotatedBox), findsWidgets);
  });
  testWidgets('row renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% row %}{% endrow %}
      '''
    );
    expect(find.byType(Row), findsWidgets);
  });
  testWidgets('safe_area renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% safe_area %}{% endsafe_area %}
      '''
    );
    expect(find.byType(SafeArea), findsWidgets);
  });
  testWidgets('scaffold renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% scaffold %}{% endscaffold %}
      '''
    );
    expect(find.byType(Scaffold), findsWidgets);
  });
  testWidgets('segmented_button renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% segmented_button segments: segments selected: selected %}{% endsegmented_button %}
      '''
      ,data: {
        'segments': [ButtonSegment(value: "Sample", label: const Text("Sample"))],
        'selected': <Object?>{"Sample"},
      }
    );
    expect(find.byType(SegmentedButton), findsWidgets);
  });
  testWidgets('selectable_text renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% selectable_text data: "Sample" %}{% endselectable_text %}
      '''
    );
    expect(find.byType(SelectableText), findsWidgets);
  });
  testWidgets('shader_mask renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% shader_mask shaderCallback: shaderCallback %}{% endshader_mask %}
      '''
      ,data: {
        'shaderCallback': (Rect bounds) => const LinearGradient(colors: [Color(0xFFFF0000), Color(0xFF0000FF)]).createShader(bounds),
      }
    );
    expect(find.byType(ShaderMask), findsWidgets);
  });
  testWidgets('simple_dialog renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% simple_dialog %}{% endsimple_dialog %}
      '''
    );
    expect(find.byType(SimpleDialog), findsWidgets);
  });
  testWidgets('single_child_scroll_view renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% single_child_scroll_view %}{% endsingle_child_scroll_view %}
      '''
    );
    expect(find.byType(SingleChildScrollView), findsWidgets);
  });
  testWidgets('sized_box renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% sized_box width: 120 height: 80 %}{% endsized_box %}
      '''
    );
    expect(find.byType(SizedBox), findsWidgets);
  });
  testWidgets('sized_overflow_box renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% sized_overflow_box size: "20,20" %}{% text data: "Sample" %}{% endsized_overflow_box %}
      '''
    );
    expect(find.byType(SizedOverflowBox), findsWidgets);
  });
  testWidgets('slider renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% slider onChanged: onChanged value: 1 %}{% endslider %}
      '''
      ,data: {
        'onChanged': (dynamic _) {},
      }
    );
    expect(find.byType(Slider), findsWidgets);
  });
  testWidgets('spacer renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% row %}{% spacer %}{% endspacer %}{% endrow %}
      '''
    );
    expect(find.byType(Spacer), findsWidgets);
  });
  testWidgets('stack renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% stack %}{% endstack %}
      '''
    );
    expect(find.byType(Stack), findsWidgets);
  });
  testWidgets('stepper renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% stepper steps: steps %}{% endstepper %}
      '''
      ,data: {
        'steps': const [Step(title: Text('Step 1'), content: Text('Content'))],
      }
    );
    expect(find.byType(Stepper), findsWidgets);
  });
  testWidgets('switch renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% switch onChanged: onChanged value: true %}{% endswitch %}
      '''
      ,data: {
        'onChanged': (dynamic _) {},
      }
    );
    expect(find.byType(Switch), findsWidgets);
  });
  testWidgets('switch_list_tile renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% switch_list_tile onChanged: onChanged value: true %}{% endswitch_list_tile %}
      '''
      ,data: {
        'onChanged': (dynamic _) {},
      }
    );
    expect(find.byType(SwitchListTile), findsWidgets);
  });
  testWidgets('tab renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% tab text: "Tab 1" %}{% endtab %}
      '''
    );
    expect(find.byType(Tab), findsWidgets);
  });
  testWidgets('tab_bar renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% default_tab_controller length: 2 %}{% tab_bar tabs: tabs %}{% endtab_bar %}{% enddefault_tab_controller %}
      '''
      ,data: {
        'tabs': const [Tab(text: 'Tab 1'), Tab(text: 'Tab 2')],
      }
    );
    expect(find.byType(TabBar), findsWidgets);
  });
  testWidgets('tab_bar_view renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% default_tab_controller length: 2 %}{% tab_bar_view %}{% text data: "Page 1" %}{% text data: "Page 2" %}{% endtab_bar_view %}{% enddefault_tab_controller %}
      '''
    );
    expect(find.byType(TabBarView), findsWidgets);
  });
  testWidgets('table renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% table %}{% endtable %}
      '''
    );
    expect(find.byType(Table), findsWidgets);
  });
  testWidgets('text renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% text data: "Sample" %}{% endtext %}
      '''
    );
    expect(find.byType(Text), findsWidgets);
  });
  testWidgets('text_button renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% text_button onPressed: onPressed %}{% endtext_button %}
      '''
      ,data: {
        'onPressed': TapActionDrop(() {}),
      }
    );
    expect(find.byType(TextButton), findsWidgets);
  });
  testWidgets('text_field renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% text_field %}{% endtext_field %}
      '''
    );
    expect(find.byType(TextField), findsWidgets);
  });
  testWidgets('text_form_field renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% text_form_field %}{% endtext_form_field %}
      '''
    );
    expect(find.byType(TextFormField), findsWidgets);
  });
  testWidgets('time_picker_dialog renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% time_picker_dialog initialTime: initialTime %}{% endtime_picker_dialog %}
      '''
      ,data: {
        'initialTime': const TimeOfDay(hour: 10, minute: 30),
      }
    );
    expect(find.byType(TimePickerDialog), findsWidgets);
  });
  testWidgets('toggle_buttons renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% toggle_buttons isSelected: isSelected %}{% text data: "A" %}{% text data: "B" %}{% endtoggle_buttons %}
      '''
      ,data: {
        'isSelected': [true, false],
      }
    );
    expect(find.byType(ToggleButtons), findsWidgets);
  });
  testWidgets('tooltip renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% tooltip message: "Hint" %}{% text data: "Hover" %}{% endtooltip %}
      '''
    );
    expect(find.byType(Tooltip), findsWidgets);
  });
  testWidgets('transform renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% transform transform: "1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1" %}{% endtransform %}
      '''
    );
    expect(find.byType(Transform), findsWidgets);
  });
  testWidgets('unconstrained_box renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% unconstrained_box %}{% endunconstrained_box %}
      '''
    );
    expect(find.byType(UnconstrainedBox), findsWidgets);
  });
  testWidgets('visibility renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% visibility %}{% endvisibility %}
      '''
    );
    expect(find.byType(Visibility), findsWidgets);
  });
  testWidgets('wrap renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% wrap %}{% endwrap %}
      '''
    );
    expect(find.byType(Wrap), findsWidgets);
  });
}
