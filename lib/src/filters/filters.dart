import '../filter_registry.dart';
import 'array.dart' as array;
import 'date.dart' as date;
import 'html.dart' as html;
import 'math.dart' as math;
import 'misc.dart' as misc;
import 'string.dart' as string;
import 'url.dart' as url;

final Map<String, FilterFunction> builtInFilters = {
  ...array.filters,
  ...date.filters,
  ...html.filters,
  ...math.filters,
  ...misc.filters,
  ...string.filters,
  ...url.filters,
};
