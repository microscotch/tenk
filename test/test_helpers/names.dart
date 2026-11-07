import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/ui/widgets/player_avatar.dart';

/// Le texte [name] qui n'est pas dans une pastille : celle-ci porte la première lettre
/// du nom, qu'un `find.text('A')` ramasse aussi pour un joueur appelé « A ».
Finder nameText(String name) => find.byElementPredicate(
      (e) => e.widget is Text && (e.widget as Text).data == name && e.findAncestorWidgetOfExactType<PlayerAvatarWidget>() == null,
      description: 'texte « $name » hors d\'une pastille',
    );
