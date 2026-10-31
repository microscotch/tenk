import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/backup_archive.dart';
import 'package:le10000/state/backup_service.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/ui/backup_files.dart';
import 'package:le10000/ui/widgets/backup_section.dart';

/// Un [BackupService] qui ne touche pas au disque (`testWidgets` ne résout pas de
/// vraies E/S) : il note ce qu'on lui demande. Le vrai est testé, sur de vrais
/// dossiers, par `test/state/backup_test.dart`.
class _FakeBackupService implements BackupService {
  String? exportedPassword;
  String goodPassword = 'bon mot de passe';
  Object? checkError;
  BackupImportMode? restoredMode;

  @override
  Future<Uint8List> export(String password, {int iterations = BackupEnvelope.defaultIterations}) async {
    exportedPassword = password;
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  void check(Uint8List bytes) {
    if (checkError != null) throw checkError!;
  }

  @override
  Future<BackupArchive> open(Uint8List bytes, String password) async {
    if (password != goodPassword) throw const BackupException(BackupFailure.wrongPassword);
    return BackupArchive(createdAt: DateTime.utc(2026));
  }

  @override
  Future<BackupRestoreResult> restore(BackupArchive archive, BackupImportMode mode) async {
    restoredMode = mode;
    return const BackupRestoreResult(games: 2, profiles: 1, skipped: 0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late _FakeBackupService service;
  late ProviderContainer container;
  late List<(Uint8List, String)> shared;
  late int restoredCalls;
  Uint8List? picked;

  Future<void> pumpSection(WidgetTester tester) async {
    service = _FakeBackupService();
    shared = [];
    restoredCalls = 0;
    picked = Uint8List.fromList([9, 9, 9]);
    container = ProviderContainer(overrides: [
      backupServiceProvider.overrideWithValue(service),
      shareBackupFileProvider.overrideWithValue((bytes, name, {origin}) async => shared.add((bytes, name))),
      pickBackupFileProvider.overrideWithValue(() async => picked),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(child: BackupSection(onRestored: () => restoredCalls++)),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Finder field(int index) => find.byType(TextFormField).at(index);

  testWidgets('export : le mot de passe est obligatoire, long de 8 caractères au moins, et confirmé', (tester) async {
    await pumpSection(tester);
    await tester.tap(find.text('Exporter mes données'));
    await tester.pumpAndSettle();

    // Rien de saisi, puis trop court, puis deux saisies différentes.
    await tester.tap(find.text('Exporter').last);
    await tester.pumpAndSettle();
    expect(find.text('Au moins 8 caractères.'), findsOneWidget);
    expect(service.exportedPassword, isNull);

    await tester.enterText(field(1), 'court');
    await tester.enterText(field(2), 'court');
    await tester.tap(find.text('Exporter').last);
    await tester.pumpAndSettle();
    expect(find.text('Au moins 8 caractères.'), findsOneWidget);

    await tester.enterText(field(1), 'assez long 1');
    await tester.enterText(field(2), 'assez long 2');
    await tester.tap(find.text('Exporter').last);
    await tester.pumpAndSettle();
    expect(find.text('Les deux mots de passe sont différents.'), findsOneWidget);
    expect(service.exportedPassword, isNull);
  });

  testWidgets('export : un mot de passe valable chiffre le fichier et ouvre la feuille de partage', (tester) async {
    await pumpSection(tester);
    await tester.tap(find.text('Exporter mes données'));
    await tester.pumpAndSettle();
    await tester.enterText(field(1), 'assez long');
    await tester.enterText(field(2), 'assez long');
    await tester.tap(find.text('Exporter').last);
    await tester.pumpAndSettle();

    expect(service.exportedPassword, 'assez long');
    expect(shared, hasLength(1));
    expect(shared.single.$1, [1, 2, 3]);
    expect(shared.single.$2, matches(RegExp(r'^tenk-\d{4}-\d{2}-\d{2}\.tenkbak$')));
    expect(find.text('Sauvegarde exportée.'), findsOneWidget);
  });

  testWidgets('export : annuler n\'exporte rien', (tester) async {
    await pumpSection(tester);
    await tester.tap(find.text('Exporter mes données'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(service.exportedPassword, isNull);
    expect(shared, isEmpty);
  });

  testWidgets('import : un mauvais mot de passe se corrige sur place, puis la restauration choisie s\'applique', (tester) async {
    await pumpSection(tester);
    await tester.tap(find.text('Importer une sauvegarde'));
    await tester.pumpAndSettle();
    expect(find.text('Restaurer une sauvegarde'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'mauvais');
    await tester.tap(find.text('Restaurer').last);
    await tester.pumpAndSettle();
    expect(find.text('Mot de passe incorrect, ou fichier modifié.'), findsOneWidget);
    expect(service.restoredMode, isNull);

    await tester.enterText(find.byType(TextField).last, service.goodPassword);
    await tester.tap(find.text('Tout remplacer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restaurer').last);
    await tester.pumpAndSettle();

    expect(service.restoredMode, BackupImportMode.replace);
    expect(find.text('Données restaurées : 2 parties, 1 joueurs.'), findsOneWidget);
    expect(restoredCalls, 0, reason: 'pas avant que le bilan soit fermé');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(restoredCalls, 1);
  });

  testWidgets('import : fusionner est le choix par défaut', (tester) async {
    await pumpSection(tester);
    await tester.tap(find.text('Importer une sauvegarde'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, service.goodPassword);
    await tester.tap(find.text('Restaurer').last);
    await tester.pumpAndSettle();
    expect(service.restoredMode, BackupImportMode.merge);
  });

  testWidgets('import : un fichier qui n\'est pas une sauvegarde est refusé avant le mot de passe', (tester) async {
    await pumpSection(tester);
    service.checkError = const BackupException(BackupFailure.notABackup);
    await tester.tap(find.text('Importer une sauvegarde'));
    await tester.pumpAndSettle();
    expect(find.text('Ce fichier n\'est pas une sauvegarde de TenK.'), findsOneWidget);
    expect(find.text('Restaurer une sauvegarde'), findsNothing);
  });

  testWidgets('import : renoncer au choix du fichier ne fait rien', (tester) async {
    await pumpSection(tester);
    picked = null;
    await tester.tap(find.text('Importer une sauvegarde'));
    await tester.pumpAndSettle();
    expect(find.text('Restaurer une sauvegarde'), findsNothing);
  });

  testWidgets('import : refusé tant qu\'une partie est en cours', (tester) async {
    await pumpSection(tester);
    container.read(gameProvider.notifier).debugLoadState(
          GameEngine.newGame(['A', 'B']).startTurn(),
          const GameSetup(playerNames: ['A', 'B']),
        );
    await tester.tap(find.text('Importer une sauvegarde'));
    await tester.pumpAndSettle();
    expect(find.text('Terminez ou quittez la partie en cours avant de restaurer une sauvegarde.'), findsOneWidget);
    expect(find.text('Restaurer une sauvegarde'), findsNothing);
  });
}
