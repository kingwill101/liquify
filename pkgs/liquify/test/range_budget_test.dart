import 'package:liquify/liquify.dart';
import 'package:test/test.dart';

void main() {
  Template template(
    String source, {
    Map<String, String> partials = const {},
    Map<String, Object?> data = const {},
  }) => Template.parse(
    source,
    root: MapRoot(partials, throwOnMissing: true),
    data: {'finish': 1000000000, 'start': 999999996, ...data},
    environmentSetup: (environment) => environment.maxRangeSize = 4,
  );

  test('range loops allocate only the requested slice in both modes', () async {
    const source =
        '{% for n in (1..finish) reversed offset:start limit:2 %}{{ n }} {% endfor %}'
        '{% for n in (1..finish) offset:continue limit:2 %}{{ n }} {% endfor %}';
    const expected = '999999998 999999997 999999999 1000000000 ';
    expect(template(source).render(), expected);
    expect(await template(source).renderAsync(), expected);
  });

  test('range budget applies to assignments, loops, and partials', () async {
    for (final source in [
      '{% assign values = (1..5) %}{{ values | size }}',
      '{% for n in (1..5) %}{{ n }}{% endfor %}',
      "{% render 'items' %}",
    ]) {
      final subject = template(
        source,
        partials: {'items.liquid': '{% for n in (1..5) %}{{ n }}{% endfor %}'},
      );
      expect(subject.render, throwsRangeError, reason: source);
      await expectLater(
        subject.renderAsync(),
        throwsRangeError,
        reason: source,
      );
    }
  });

  test('ranges at the budget still render normally', () async {
    const source = '{% assign values = (-2..1) %}{{ values | join: "," }}';
    expect(template(source).render(), '-2,-1,0,1');
    expect(await template(source).renderAsync(), '-2,-1,0,1');
  });

  test(
    'range endpoints truncate finite decimals and default null to zero',
    () async {
      const source =
          '{% assign values = (low..high) %}{{ values | join: "," }}|'
          '{% for n in (missing..high) %}{{ n }}{% endfor %}';
      const data = {'low': -1.9, 'high': 1.9};
      expect(template(source, data: data).render(), '-1,0,1|01');
      expect(await template(source, data: data).renderAsync(), '-1,0,1|01');
    },
  );

  test('invalid range endpoints raise RangeError in both modes', () async {
    const source = '{% for n in (0..high) limit:0 %}{{ n }}{% endfor %}';
    for (final value in [
      '2',
      true,
      double.nan,
      double.infinity,
      -double.infinity,
    ]) {
      final subject = template(source, data: {'high': value});
      expect(subject.render, throwsRangeError, reason: 'endpoint $value');
      await expectLater(
        subject.renderAsync(),
        throwsRangeError,
        reason: 'endpoint $value',
      );
    }
  });
}
