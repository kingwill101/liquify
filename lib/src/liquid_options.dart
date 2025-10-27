class LiquidOptions {
  final String? locale;
  final bool preserveTimezones;
  /// Can be an [int] (minutes offset) or IANA timezone name (String).
  final Object? timezoneOffset;
  final String? dateFormat;
  final bool disableIntl;

  const LiquidOptions({
    this.locale,
    this.preserveTimezones = false,
    this.timezoneOffset,
    this.dateFormat,
    this.disableIntl = false,
  });

  LiquidOptions copyWith({
    String? locale,
    bool? preserveTimezones,
    Object? timezoneOffset,
    String? dateFormat,
    bool? disableIntl,
  }) {
    return LiquidOptions(
      locale: locale ?? this.locale,
      preserveTimezones: preserveTimezones ?? this.preserveTimezones,
      timezoneOffset: timezoneOffset ?? this.timezoneOffset,
      dateFormat: dateFormat ?? this.dateFormat,
      disableIntl: disableIntl ?? this.disableIntl,
    );
  }

  static LiquidOptions? maybeFrom(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is LiquidOptions) {
      return value;
    }
    if (value is Map) {
      return LiquidOptions(
        locale: value['locale']?.toString(),
        preserveTimezones: value['preserveTimezones'] == true,
        timezoneOffset: value['timezoneOffset'],
        dateFormat: value['dateFormat']?.toString(),
        disableIntl: value['disableIntl'] == true,
      );
    }
    return null;
  }
}
