import 'package:intl/intl.dart';
import 'package:liquify/liquify.dart';
import 'package:test/test.dart';

/// Helper to render a template with optional assigns and engine options.
String renderTemplate(
  String source, {
  Map<String, dynamic> assigns = const {},
  LiquidOptions? options,
}) {
  final template = Template.parse(source, data: assigns, options: options);
  return template.render();
}

void main() {
  group('filters/date', () {
    group('constructor', () {
      test('creates a new date when given "now"', () {
        final year = DateTime.now().year.toString();
        final result = renderTemplate(r'{{ "now" | date: "%Y"}}');
        expect(result, equals(year));
      });

      test('creates a new date when given "today"', () {
        final year = DateTime.now().year.toString();
        final result = renderTemplate(r'{{ "today" | date: "%Y"}}');
        expect(result, equals(year));
      });

      test('creates from number', () {
        final time =
            DateTime.parse('2017-03-07T12:00:00').millisecondsSinceEpoch ~/
                1000;
        final result = renderTemplate(
          r'{{ time | date: "%Y-%m-%dT%H:%M:%S" }}',
          assigns: {'time': time},
        );
        expect(result, equals('2017-03-07T12:00:00'));
      });

      test('creates from number-like string', () {
        final time =
            (DateTime.parse('2017-03-07T12:00:00').millisecondsSinceEpoch ~/
                    1000)
                .toString();
        final result = renderTemplate(
          r'{{ time | date: "%Y-%m-%dT%H:%M:%S" }}',
          assigns: {'time': time},
        );
        expect(result, equals('2017-03-07T12:00:00'));
      });

      test('treats nil as 0', () {
        final result = renderTemplate(
            r'{{ nil | date: "%Y-%m-%dT%H:%M:%S", "Asia/Shanghai" }}');
        expect(result, equals('1970-01-01T08:00:00'));
      });

      test('treats undefined as invalid', () {
        final result = renderTemplate(
            r'{{ num | date: "%Y-%m-%dT%H:%M:%S", "Asia/Shanghai" }}');
        expect(result, equals(''));
      });
    });

    test('supports date: %a %b %d %Y', () {
      final date = DateTime.now();
      final expected =
          DateFormat('EEE MMM dd yyyy', 'en_US').format(date.toLocal());
      final result = renderTemplate(r'{{ date | date:"%a %b %d %Y"}}',
          assigns: {'date': date});
      expect(result, equals(expected));
    });

    group('%a', () {
      test('supports short week day', () {
        final tpl =
            r'{{ "2024-07-21T20:24:00.000Z" | date: "%a", "Asia/Shanghai" }}';
        expect(renderTemplate(tpl), equals('Mon'));
      });

      test('supports short week day with timezone', () {
        final tpl =
            r'{{ "2024-07-21T20:24:00.000Z" | date: "%a", "America/New_York" }}';
        expect(renderTemplate(tpl), equals('Sun'));
      });

      test('supports short week day with locale', () {
        final tpl =
            r'{{ "2024-07-21T20:24:00.000Z" | date: "%a", "America/New_York" }}';
        final result =
            renderTemplate(tpl, options: const LiquidOptions(locale: 'zh-CN'));
        expect(result, equals('周日'));
      });
    });

    group('%b', () {
      test('supports short month', () {
        final tpl =
            r'{{ "2024-07-31T20:24:00.000Z" | date: "%b", "Asia/Shanghai" }}';
        expect(renderTemplate(tpl), equals('Aug'));
      });

      test('supports short month with locale', () {
        final tpl =
            r'{{ "2024-07-31T20:24:00.000Z" | date: "%b", "Asia/Shanghai" }}';
        final result =
            renderTemplate(tpl, options: const LiquidOptions(locale: 'zh-CN'));
        expect(result, equals('8月'));
      });
    });

    group('Intl compatibility', () {
      test('uses English if Intl not supported', () {
        final tpl =
            r'{{ "2024-07-31T20:24:00.000Z" | date: "%b", "Asia/Shanghai" }}';
        final result = renderTemplate(tpl,
            options: const LiquidOptions(disableIntl: true));
        expect(result, equals('Aug'));
      });

      test('uses English if Intl missing for other locales', () {
        final tpl =
            r'{{ "2024-07-31T20:24:00.000Z" | date: "%b", "Asia/Shanghai" }}';
        final result = renderTemplate(
          tpl,
          options: const LiquidOptions(disableIntl: true, locale: 'zh-CN'),
        );
        expect(result, equals('Aug'));
      });
    });

    test('supports "now"', () {
      final result = renderTemplate(r'{{ "now" | date }}');
      expect(result,
          matches(RegExp(r'\w+, \w+ \d+, \d{4} at \d+:\d{2} [ap]m [-+]\d{4}')));
    });

    test('parses timezoneless string', () {
      final result = renderTemplate(
          r'{{ "1991-02-22T00:00:00" | date: "%Y-%m-%dT%H:%M:%S"}}');
      expect(result, equals('1991-02-22T00:00:00'));
    });

    group('preserveTimezones enabled', () {
      final options =
          const LiquidOptions(preserveTimezones: true, locale: 'en-US');

      test('does not change timezone between input and output', () {
        final result = renderTemplate(
          r'{{ "1990-12-31T23:00:00Z" | date: "%Y-%m-%dT%H:%M:%S"}}',
          options: options,
        );
        expect(result, equals('1990-12-31T23:00:00'));
      });

      test('applies numeric timezone offset (0)', () {
        final result = renderTemplate(
          r'{{ "1990-12-31T23:00:00+00:00" | date: "%Y-%m-%dT%H:%M:%S %z"}}',
          options: options,
        );
        expect(result, equals('1990-12-31T23:00:00 +0000'));
      });

      test('applies numeric timezone offset (-1)', () {
        final result = renderTemplate(
          r'{{ "1990-12-31T23:00:00-01:00" | date: "%Y-%m-%dT%H:%M:%S %z"}}',
          options: options,
        );
        expect(result, equals('1990-12-31T23:00:00 -0100'));
      });

      test('applies numeric timezone offset (+2.30)', () {
        final result = renderTemplate(
          r'{{ "1990-12-31T23:00:00+02:30" | date: "%Y-%m-%dT%H:%M:%S %z"}}',
          options: options,
        );
        expect(result, equals('1990-12-31T23:00:00 +0230'));
      });

      test('supports timezone in casual date', () {
        final tpl =
            r'{{ "2025-01-02 03:04:05 -0100" | date: "%Y-%m-%dT%H:%M:%S %z" }}';
        expect(renderTemplate(tpl, options: options),
            equals('2025-01-02T03:04:05 -0100'));
        expect(
            renderTemplate(r'{{ "2025-01-02 03:04:05 -0100" | date }}',
                options: options),
            equals('Thursday, January 2, 2025 at 3:04 am -0100'));
      });

      test('works when timezone not specified', () {
        final result = renderTemplate(
          r'{{ "1990-12-31T23:00:00" | date: "%Y-%m-%dT%H:%M:%S"}}',
          options: options,
        );
        expect(result, equals('1990-12-31T23:00:00'));
      });
    });

    test('renders string as string if not valid', () {
      final result = renderTemplate(r'{{ "foo" | date: "%Y"}}');
      expect(result, equals('foo'));
    });

    test('renders object as string', () {
      final result = renderTemplate(r'{{ obj | date: "%Y"}}', assigns: {
        'obj': {},
      });
      expect(result, equals('[object Object]'));
    });

    test('supports manipulation', () {
      final result = renderTemplate(
        r'{{ date | date: "%s" | minus : 604800  | date: "%Y-%m-%dT%H:%M:%S"}}',
        assigns: {
          'date': DateTime.parse('2017-03-07T12:00:00'),
        },
      );
      expect(result, equals('2017-02-28T12:00:00'));
    });

    group('timezoneOffset option', () {
      final options = const LiquidOptions(timezoneOffset: 360);

      test('offsets UTC date literal', () {
        final result = renderTemplate(
          r'{{ "1990-12-31T23:00:00Z" | date: "%Y-%m-%dT%H:%M:%S"}}',
          options: options,
        );
        expect(result, equals('1990-12-31T17:00:00'));
      });

      test('supports timezone offset argument', () {
        final result = renderTemplate(
            r'{{ "1990-12-31T23:00:00Z" | date: "%Y-%m-%dT%H:%M:%S", 360}}');
        expect(result, equals('1990-12-31T17:00:00'));
      });

      test('supports timezone without format', () {
        final result = renderTemplate(
            r'{{ "2022-12-08T03:22:18.000Z" | date: nil, "America/Cayman" }}');
        expect(result, equals('Wednesday, December 7, 2022 at 10:22 pm -0500'));
      });

      test('supports timezone name argument', () {
        final result = renderTemplate(
            r'{{ "1990-12-31T23:00:00Z" | date: "%Y-%m-%dT%H:%M:%S", "Asia/Colombo" }}');
        expect(result, equals('1991-01-01T04:30:00'));
      });

      test('supports timezone name argument when DST inactive', () {
        final result = renderTemplate(
            r'{{ "2021-01-01T23:00:00Z" | date: "%Y-%m-%dT%H:%M:%S", "America/New_York" }}');
        expect(result, equals('2021-01-01T18:00:00'));
      });

      test('supports timezone name argument when DST active', () {
        final result = renderTemplate(
            r'{{ "2021-06-01T23:00:00Z" | date: "%Y-%m-%dT%H:%M:%S", "America/New_York" }}');
        expect(result, equals('2021-06-01T19:00:00'));
      });

      test('offsets date literal with timezone +00:00 specified', () {
        final result = renderTemplate(
          r'{{ "1990-12-31T23:00:00+00:00" | date: "%Y-%m-%dT%H:%M:%S"}}',
          options: options,
        );
        expect(result, equals('1990-12-31T17:00:00'));
      });

      test('offsets date literal with timezone -01:00 specified', () {
        final result = renderTemplate(
          r'{{ "1990-12-31T23:00:00-01:00" | date: "%Y-%m-%dT%H:%M:%S"}}',
          options: options,
        );
        expect(result, equals('1990-12-31T18:00:00'));
      });

      test('offsets date from scope (timezone offset)', () {
        final result = renderTemplate(
          r'{{ date | date: "%Y-%m-%dT%H:%M:%S"}}',
          assigns: {'date': DateTime.parse('1990-12-31T23:00:00Z')},
          options: options,
        );
        expect(result, equals('1990-12-31T17:00:00'));
      });

      test('offsets date from scope (timezone name)', () {
        final result = renderTemplate(
          r'{{ date | date: "%Y-%m-%dT%H:%M:%S"}}',
          assigns: {'date': DateTime.parse('1990-12-31T23:00:00Z')},
          options: const LiquidOptions(timezoneOffset: 'America/Merida'),
        );
        expect(result, equals('1990-12-31T17:00:00'));
      });

      test('reflects timezoneOffset in %z', () {
        final result = renderTemplate(
          r'{{ date | date: "%z"}}',
          assigns: {'date': DateTime.parse('1990-12-31T23:00:00Z')},
          options: options,
        );
        expect(result, equals('-0600'));
      });

      test('options.timezoneOffset works with preserveTimezones', () {
        final result = renderTemplate(
          r'{{ "1990-12-31T23:00:00+02:30" | date: "%Y-%m-%dT%H:%M:%S"}}',
          options:
              const LiquidOptions(timezoneOffset: 600, preserveTimezones: true),
        );
        expect(result, equals('1990-12-31T23:00:00'));
      });

      test('timezoneOffset works with preserveTimezones', () {
        final html = renderTemplate(
          r'{{ "1990-12-31T23:00:00Z" | date: "%Y-%m-%dT%H:%M:%S", "Asia/Colombo" }}',
          options: const LiquidOptions(preserveTimezones: true),
        );
        expect(html, equals('1991-01-01T04:30:00'));
      });

      test('uses runtime default timezone when not specified', () {
        final html =
            renderTemplate(r'{{ "1990-12-31T23:00:00Z" | date: "%Z" }}');
        expect(html, equals(DateTime.now().timeZoneName));
      });

      test('uses in-place timezoneOffset as timezone name', () {
        final html = renderTemplate(
          r'{{ "1990-12-31T23:00:00Z" | date: "%Y-%m-%dT%H:%M:%S %Z", "Asia/Colombo" }}',
          options: const LiquidOptions(preserveTimezones: true),
        );
        expect(html, equals('1991-01-01T04:30:00 Asia/Colombo'));
      });

      test('uses options.timezoneOffset as default timezone name', () {
        final html = renderTemplate(
          r'{{ "1990-12-31T23:00:00.000Z" | date: "%Y-%m-%dT%H:%M:%S %Z"}}',
          options: const LiquidOptions(timezoneOffset: 'Australia/Brisbane'),
        );
        expect(html, equals('1991-01-01T10:00:00 Australia/Brisbane'));
      });

      test('uses given timezone offset number as timezone name', () {
        final html = renderTemplate(
          r'{{ "1990-12-31T23:00:00+02:30" | date: "%Y-%m-%dT%H:%M:%S %:Z"}}',
          options: const LiquidOptions(preserveTimezones: true),
        );
        expect(html, equals('1990-12-31T23:00:00 +02:30'));
      });
    });

    group('dateFormat option', () {
      final optsWithoutFormat = const LiquidOptions(timezoneOffset: 360);

      test('uses default format when none provided', () {
        final html = renderTemplate(
          r'{{ "2022-12-08T03:22:18.000Z" | date }}',
          options: optsWithoutFormat,
        );
        expect(html, equals('Wednesday, December 7, 2022 at 9:22 pm -0600'));
      });

      test('uses given filter format instead of default', () {
        final html = renderTemplate(
          r'{{ "1990-12-31T23:00:00Z" | date: "%Y-%m-%dT%H:%M:%S" }}',
          options: optsWithoutFormat,
        );
        expect(html, equals('1990-12-31T17:00:00'));
      });

      final optsWithFormat = const LiquidOptions(
        timezoneOffset: -330,
        dateFormat: '%d%q of %b %Y at %I:%M %P',
      );

      test('uses configured options.dateFormat when no format argument', () {
        final html = renderTemplate(
          r'{{ "2022-12-08T13:30:18.000Z" | date }}',
          options: optsWithFormat,
        );
        expect(html, equals('08th of Dec 2022 at 07:00 pm'));
      });

      test('prefers filter format argument over options.dateFormat', () {
        final html = renderTemplate(
          r'{{ "1990-12-31T23:00:00Z" | date: "%Y-%m-%dT%H:%M:%S" }}',
          options: optsWithFormat,
        );
        expect(html, equals('1991-01-01T04:30:00'));
      });
    });
  });

  group('filters/date_to_xmlschema', () {
    test('supports literal date', () {
      final output =
          renderTemplate(r'{{ "1990-10-15T23:00:00" | date_to_xmlschema }}');
      expect(output, matches(RegExp(r'^1990-10-15T23:00:00[+-]\d\d:\d\d$')));
    });

    test('respects timezone when preserveTimezones', () {
      final output = renderTemplate(
        r'{{ "2008-11-07T13:07:54-08:00" | date_to_xmlschema }}',
        options: const LiquidOptions(preserveTimezones: true),
      );
      expect(output, equals('2008-11-07T13:07:54-08:00'));
    });
  });

  group('filters/date_to_rfc822', () {
    test('supports literal date', () {
      final output =
          renderTemplate(r'{{ "1990-10-15T23:00:00" | date_to_rfc822 }}');
      expect(output, matches(RegExp(r'^Mon, 15 Oct 1990 23:00:00 [+-]\d{4}$')));
    });

    test('respects timezone when preserveTimezones', () {
      final output = renderTemplate(
        r'{{ "2008-11-07T13:07:54-08:00" | date_to_rfc822 }}',
        options: const LiquidOptions(preserveTimezones: true),
      );
      expect(output, equals('Fri, 07 Nov 2008 13:07:54 -0800'));
    });
  });

  group('filters/date_to_string', () {
    test('defaults to non-ordinal, UK', () {
      final output = renderTemplate(
        r'{{ "2008-11-07T13:07:54-08:00" | date_to_string }}',
        options: const LiquidOptions(preserveTimezones: true),
      );
      expect(output, equals('07 Nov 2008'));
    });

    test('supports ordinal, US', () {
      final output = renderTemplate(
        r'{{ "2008-11-07T13:07:54-08:00" | date_to_string: "ordinal", "US" }}',
        options: const LiquidOptions(preserveTimezones: true),
      );
      expect(output, equals('Nov 7th, 2008'));
    });

    test('renders none if not valid', () {
      final output = renderTemplate(
        r'{{ "hello" | date_to_string: "ordinal", "US" }}',
        options: const LiquidOptions(preserveTimezones: true),
      );
      expect(output, equals('hello'));
    });
  });

  group('filters/date_to_long_string', () {
    test('defaults to non-ordinal, UK', () {
      final output = renderTemplate(
        r'{{ "2008-11-07T13:07:54-08:00" | date_to_long_string }}',
        options: const LiquidOptions(preserveTimezones: true),
      );
      expect(output, equals('07 November 2008'));
    });

    test('supports ordinal, US', () {
      final output = renderTemplate(
        r'{{ "2008-11-07T13:07:54-08:00" | date_to_long_string: "ordinal", "US" }}',
        options: const LiquidOptions(preserveTimezones: true),
      );
      expect(output, equals('November 7th, 2008'));
    });

    test('supports ordinal, UK', () {
      final output = renderTemplate(
        r'{{ "2008-11-07T13:07:54-08:00" | date_to_long_string: "ordinal" }}',
        options: const LiquidOptions(preserveTimezones: true),
      );
      expect(output, equals('7th November 2008'));
    });
  });
}
