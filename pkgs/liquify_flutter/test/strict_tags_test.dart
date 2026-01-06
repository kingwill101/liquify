import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('strict tag parsing rejects unknown args', (tester) async {
    expect(
      () => pumpTemplate(
        tester,
        '{% text data: "Hello" unknownArg: 1 %}',
        strictTags: true,
      ),
      throwsException,
    );
  });

  testWidgets('strict tag parsing rejects unknown args on generated tags',
      (tester) async {
    expect(
      () => pumpTemplate(
        tester,
        '{% animated_align bogus: 1 %}{% endanimated_align %}',
        strictTags: true,
      ),
      throwsException,
    );
  });
}
