import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('wrap tag configures alignment and spacing', (tester) async {
    await pumpTemplate(
      tester,
      '{% wrap alignment: "center" crossAxisAlignment: "center" '
      'runAlignment: "spaceBetween" spacing: 4 runSpacing: 6 direction: "vertical" %}'
      '{% text value: "A" %}{% text value: "B" %}{% endwrap %}',
    );

    final wrap = tester.widget<Wrap>(find.byType(Wrap));
    expect(wrap.alignment, WrapAlignment.center);
    expect(wrap.crossAxisAlignment, WrapCrossAlignment.center);
    expect(wrap.runAlignment, WrapAlignment.spaceBetween);
    expect(wrap.spacing, 4);
    expect(wrap.runSpacing, 6);
    expect(wrap.direction, Axis.vertical);
  });

  testWidgets('align and center tags wrap children', (tester) async {
    await pumpTemplate(
      tester,
      '{% align alignment: "topLeft" widthFactor: 0.5 heightFactor: 0.25 %}'
      '{% text value: "X" %}{% endalign %}'
      '{% center %}{% text value: "Y" %}{% endcenter %}',
    );

    final alignFinder = find.ancestor(of: find.text('X'), matching: find.byType(Align));
    final align = tester.widget<Align>(alignFinder.first);
    expect(align.alignment, Alignment.topLeft);
    expect(align.widthFactor, 0.5);
    expect(align.heightFactor, 0.25);

    final centerFinder = find.ancestor(of: find.text('Y'), matching: find.byType(Center));
    expect(centerFinder, findsOneWidget);
  });

  testWidgets('expanded and flexible tags wrap children', (tester) async {
    await pumpTemplate(
      tester,
      '{% row %}'
      '{% expanded flex: 2 %}{% text value: "A" %}{% endexpanded %}'
      '{% flexible fit: "tight" flex: 3 %}{% text value: "B" %}{% endflexible %}'
      '{% endrow %}',
    );

    final row = tester.widget<Row>(find.byType(Row));
    expect(row.children.length, 2);
    expect(row.children[0], isA<Expanded>());
    expect((row.children[0] as Expanded).flex, 2);
    expect(row.children[1], isA<Flexible>());
    final flexible = row.children[1] as Flexible;
    expect(flexible.flex, 3);
    expect(flexible.fit, FlexFit.tight);
  });

  testWidgets('positioned tag builds Positioned inside Stack', (tester) async {
    await pumpTemplate(
      tester,
      '{% stack %}'
      '{% positioned left: 5 top: 7 width: 20 height: 30 %}'
      '{% text value: "P" %}{% endpositioned %}'
      '{% endstack %}',
    );

    final positioned = tester.widget<Positioned>(find.byType(Positioned));
    expect(positioned.left, 5);
    expect(positioned.top, 7);
    expect(positioned.width, 20);
    expect(positioned.height, 30);
  });

  testWidgets('fitted_box and aspect_ratio tags set properties', (tester) async {
    const template =
      '{% container width: 100 height: 50 %}'
      '{% aspect_ratio aspectRatio: 2 %}'
      '{% fitted_box fit: "cover" alignment: "bottomRight" clipBehavior: "hardEdge" %}'
      '{% text value: "AR" %}'
      '{% endfitted_box %}'
      '{% endaspect_ratio %}'
      '{% endcontainer %}';

    await pumpTemplate(tester, template);

    final fittedFinder = find.byType(FittedBox);
    expect(fittedFinder, findsOneWidget);
    final fitted = tester.widget<FittedBox>(fittedFinder.first);
    expect(fitted.fit, BoxFit.cover);
    expect(fitted.alignment, Alignment.bottomRight);
    expect(fitted.clipBehavior, Clip.hardEdge);

    final aspectFinder = find.byType(AspectRatio);
    expect(aspectFinder, findsOneWidget);
    final aspect = tester.widget<AspectRatio>(aspectFinder.first);
    expect(aspect.aspectRatio, 2);
  });

  testWidgets('opacity tag sets opacity', (tester) async {
    await pumpTemplate(
      tester,
      '{% opacity opacity: 0.7 %}{% text value: "O" %}{% endopacity %}',
    );

    final opacity = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacity.opacity, 0.7);
  });

  testWidgets('clip tags apply clip behavior and radius', (tester) async {
    await pumpTemplate(
      tester,
      '{% clip_r_rect borderRadius: 8 %}{% text value: "R" %}{% endclip_r_rect %}'
      '{% clip_oval clipBehavior: "hardEdge" %}{% text value: "O" %}{% endclip_oval %}'
      '{% clip_rect %}{% text value: "C" %}{% endclip_rect %}',
    );

    final rrectFinder = find.ancestor(
      of: find.text('R'),
      matching: find.byType(ClipRRect),
    );
    final rrect = tester.widget<ClipRRect>(rrectFinder.first);
    expect(rrect.borderRadius, BorderRadius.circular(8));

    final ovalFinder = find.ancestor(
      of: find.text('O'),
      matching: find.byType(ClipOval),
    );
    final oval = tester.widget<ClipOval>(ovalFinder.first);
    expect(oval.clipBehavior, Clip.hardEdge);

    final rectFinder = find.ancestor(
      of: find.text('C'),
      matching: find.byType(ClipRect),
    );
    final rect = tester.widget<ClipRect>(rectFinder.first);
    expect(rect.clipBehavior, Clip.hardEdge);
  });
}
