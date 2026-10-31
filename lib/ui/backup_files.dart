import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Remet le fichier de sauvegarde à l'utilisateur, par la feuille de partage du
/// système (Fichiers, un cloud, un message à soi-même...). [origin] ancre la
/// fenêtre flottante sur iPad.
///
/// Des fonctions derrière des fournisseurs plutôt que les plugins en direct, comme
/// `shareTextProvider` : les tests de widgets les remplacent, les plugins
/// n'existent pas dans leur environnement.
typedef ShareBackupFile = Future<void> Function(Uint8List bytes, String fileName, {Rect? origin});

final shareBackupFileProvider = Provider<ShareBackupFile>(
  (ref) => (bytes, fileName, {origin}) async {
    // La feuille de partage prend un fichier : on l'écrit dans le dossier
    // temporaire, que le système purge.
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], sharePositionOrigin: origin));
  },
);

/// Fait choisir un fichier de sauvegarde à l'utilisateur et rend son contenu, ou
/// `null` s'il renonce.
typedef PickBackupFile = Future<Uint8List?> Function();

final pickBackupFileProvider = Provider<PickBackupFile>(
  (ref) => () async {
    // Tout type de fichier : l'extension propre à l'app n'est connue d'aucun
    // système, qui la grisait dans le sélecteur.
    final picked = await FilePicker.pickFiles();
    if (picked.isEmpty) return null;
    return picked.first.readAsBytes();
  },
);
