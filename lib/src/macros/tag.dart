import 'dart:async';

import 'package:macros/macros.dart';

extension Capitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1, length);
  }
}


macro class TagMacro
    implements ClassDeclarationsMacro {
  final String name;
  final bool hasEndTag;

  const TagMacro({required this.name, this.hasEndTag = false});


  // Declare the necessary methods and members
  @override
  Future<void> buildDeclarationsForClass(ClassDeclaration clazz,
      MemberDeclarationBuilder builder) async {

    builder.declareInLibrary(DeclarationCode.fromString('import \'package:liquify/src/tag.dart\';'));


    builder.declareInType(DeclarationCode.fromParts([
      'void greet() {',
      "  print('Hello, $name!');",
      '}'
    ]));

    if(!hasEndTag){
      builder.declareInType(DeclarationCode.fromParts([
        '@override',
      'Parser parser() => someTag("$name");'
    ]));
      return;
    }


    builder.declareInType(DeclarationCode.fromString('''
    @override
    Parser parser() {
      return (ref0(${name}Tag).trim() & any().plusLazy(end${name
        .capitalize()}Tag()) &end${name.capitalize()}Tag())
        .map((values) {
           final tag = values[0] as Tag;
            tag.body = parseInput((values[1] as List).join(''));
            return tag;
            });
    }
      '''
    ));

    builder.declareInType(DeclarationCode.fromString('''
Parser ${name}Tag() => someTag("$name");

Parser end${name.capitalize()}Tag() =>
    (tagStart() & string('end$name').trim() & tagEnd()).map((values) {
      return Tag('endcapture', []);
    });
      '''
    ));
  }

}
