import 'dart:convert';

const _prefix = 'workspace=v1.';
const _urlLimit = 16000;

typedef SharedWorkspace = ({
  Map<String, String> files,
  String entry,
  String active,
  String context,
  String example,
});

bool hasSharedWorkspace(Uri url) => url.fragment.startsWith('workspace=');

bool isTemplatePath(String path) =>
    !path.contains('\\') &&
    path.endsWith('.liquid') &&
    path
        .split('/')
        .every((part) => part.isNotEmpty && part != '.' && part != '..');

SharedWorkspace decodeSharedWorkspace(Uri url) {
  if (!url.fragment.startsWith(_prefix) || url.toString().length > _urlLimit) {
    throw const FormatException('Invalid workspace link.');
  }
  final data = jsonDecode(
    utf8.decode(base64Url.decode(url.fragment.substring(_prefix.length))),
  );
  if (data
      case {
        'files': final Map<String, dynamic> files,
        'entry': final String entry,
        'active': final String active,
        'context': final String context,
        'example': final String example,
      }
      when files.containsKey(entry) &&
          files.containsKey(active) &&
          files.entries.every(
            (file) => file.value is String && isTemplatePath(file.key),
          )) {
    return (
      files: Map<String, String>.from(files),
      entry: entry,
      active: active,
      context: context,
      example: example,
    );
  }
  throw const FormatException('Invalid workspace data.');
}

String? encodeSharedWorkspace(Uri base, SharedWorkspace workspace) {
  final payload = base64UrlEncode(
    utf8.encode(
      jsonEncode({
        'files': workspace.files,
        'entry': workspace.entry,
        'active': workspace.active,
        'context': workspace.context,
        'example': workspace.example,
      }),
    ),
  );
  final url = base.replace(fragment: '$_prefix$payload').toString();
  return url.length <= _urlLimit ? url : null;
}
