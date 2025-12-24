class UiDocument {
  UiDocument({List<UiNode>? nodes, int? version})
    : nodes = nodes ?? <UiNode>[],
      version = version ?? schemaVersion;

  static const int schemaVersion = 1;

  final int version;
  final List<UiNode> nodes;

  Map<String, dynamic> toJson() => {
    'version': version,
    'nodes': nodes.map((node) => node.toJson()).toList(),
  };

  static UiDocument fromJson(Map<String, dynamic> json) {
    final nodesJson = json['nodes'] as List<dynamic>? ?? const [];
    return UiDocument(
      version: json['version'] as int? ?? schemaVersion,
      nodes: nodesJson
          .whereType<Map<String, dynamic>>()
          .map(UiNode.fromJson)
          .toList(),
    );
  }
}

abstract class UiNode {
  const UiNode();

  Map<String, dynamic> toJson();

  static UiNode fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    if (type == 'text') {
      return UiText(json['text']?.toString() ?? '');
    }
    if (type is String) {
      final props = (json['props'] as Map?)?.cast<String, dynamic>() ?? {};
      final childrenJson = json['children'] as List<dynamic>? ?? const [];
      return UiElement(
        type: type,
        props: props,
        key: json['key']?.toString(),
        children: childrenJson
            .whereType<Map<String, dynamic>>()
            .map(UiNode.fromJson)
            .toList(),
      );
    }
    return UiText(json['text']?.toString() ?? '');
  }
}

class UiText extends UiNode {
  const UiText(this.text);

  final String text;

  @override
  Map<String, dynamic> toJson() => {'type': 'text', 'text': text};
}

class UiElement extends UiNode {
  const UiElement({
    required this.type,
    this.props = const {},
    this.children = const <UiNode>[],
    this.key,
  });

  final String type;
  final Map<String, dynamic> props;
  final List<UiNode> children;
  final String? key;

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'props': props,
    'children': children.map((node) => node.toJson()).toList(),
    if (key != null) 'key': key,
  };
}
