# Architecture de Le 10000 (TenK)

![Diagramme de classes](architecture/class-diagram.png)

> Source éditable : [`architecture/class-diagram.drawio`](architecture/class-diagram.drawio).
> Le PNG embarque le diagramme : il se rouvre et se ré-édite directement dans
> draw.io, sans le `.drawio`.

## Trois couches, et pourquoi elles sont étanches

Le découpage n'est pas décoratif : il vient de la nature du jeu. Le règlement du
10000 est régional et truffé de cas limites (main pleine, règle d'extension,
tiret, barrage, victoire à 10000 pile) qu'on ne peut pas vérifier à l'œil dans
une interface. D'où la séparation :

- **`lib/game` — le moteur.** Dart pur, *zéro import Flutter*. C'est ce qui
  permet de le tester exhaustivement en isolation : la quasi-totalité des
  subtilités de règles se prouve par des tests unitaires sans widget.
- **`lib/state` — la couche d'état.** Notifiers Riverpod. Seul pont autorisé
  entre le moteur et l'interface, et seul endroit qui connaît à la fois les deux.
- **`lib/ui` — Flutter.** N'importe jamais d'interne moteur dont il n'a pas
  besoin pour afficher.

Sur le diagramme, aucune flèche ne relie directement l'UI au moteur : elles
passent toutes par les providers. C'est l'invariant à préserver.

Le losange (◆) se lit du côté du **tout** : `GameEngine ◆── Player` veut dire que
le moteur possède ses joueurs.

## Le moteur (bleu)

**Tout y est immuable.** Chaque transition renvoie une nouvelle instance plutôt
que de muter l'existante. Ce n'est pas un réflexe de style : c'est ce qui rend
une partie rejouable à l'identique.

- **`GameEngine`** orchestre la partie : rotation des joueurs, héritage des dés
  entre tours, condition de victoire. Ses transitions (`startTurn`, `roll`,
  `applyKeep`, `bank`, `endBustedTurn`) sont les seules portes d'entrée.
  **`roll` prononce le craque dès le lancer** quand rien ne peut plus le
  sauver — dépassement de 10000, ou main pleine tombant pile sur 10000 — les
  dés restant affichables le temps de les révéler ; `applyKeep` garde les mêmes
  contrôles en filet, pour les journaux enregistrés avant ce changement.
  `inheritedHandCannotBank` (`>=`, pas `>`) écarte une main héritée qui
  atteint déjà 10000 : la reprendre serait un craque certain.
  `bank()` et l'exception de la quinte d'as dans `applyKeep()` (ci-dessous)
  partagent la même conséquence — appliquer le score, barrer les collisions,
  passer la main — factorisée dans `_applySuccessfulBank`, pour qu'un
  banquage réussi se comporte toujours pareil, quel que soit le chemin qui y
  mène.
- **`Player` porte une grille complète (`List<ScoreEntry>`), pas un score
  scalaire.** C'est délibéré : un tiret ou un barré s'attache à *la ligne* qui
  l'a reçue et y reste, même après des tours réussis. `Player.hasTiret` est
  exactement `currentEntry.hasTiret` — un seul fait, pas deux à synchroniser
  (les avoir dédoublés a déjà produit un bug d'affichage). Chaque `ScoreEntry`
  barrée retient aussi `barredBy`, le nom de l'auteur du barrage — soi-même
  pour un second craque consécutif, l'adversaire dont le tour vient de
  provoquer une collision de score sinon — pour que la grille affiche le bon
  blason (`applyBust`/`applyScoreCollisionBarAt` le renseignent ; côté moteur,
  c'est toujours le joueur courant au moment de l'action, self ou non).
- **`TurnState`** modélise un tour sur plusieurs lancers : dés à lancer, score
  en cours, valeurs étendues, dés gardés, main pleine, craque et sa raison.
  Une main pleine qui tombe pile sur 10000 craque toujours (`BustReason.
  fullHandAtTarget`), dès le lancer — sauf la quinte d'as (5 as en un seul
  lancer), seule combinaison capable de totaliser exactement 10000 en un lancer
  de 5 dés, qui gagne la partie sur-le-champ par exception traditionnelle.
- **`RollAnalysis` / `ScoringGroup`** décrivent ce qu'un lancer vaut, en
  distinguant les groupes obligatoires des 5 isolés que le joueur peut décliner.

- **`GameSetup`** décrit une partie avant qu'elle commence : joueurs, IA, mode
  auto — et, pour chaque siège humain, l'**identifiant de sa fiche**
  (`playerIds`). C'est ce lien, jamais le nom, qui rattache une partie à un
  joueur : un renommage ne casse rien. `reordered(ordre)` la réordonne dans
  l'ordre de jeu, chaque joueur gardant son IA, son mode auto et sa fiche.
- **`DiceOffState`** est le tirage au sort qui fixe l'ordre de jeu : tout le
  monde lance son dé en même temps (`rollAll`), le plus faible commence, les
  ex-aequo au plus bas relancent seuls. `playOrder` donne les sièges dans
  l'ordre de jeu : le sens de la liste, sauf quand le dernier round était un
  duel entre voisins (table circulaire) gagné par le second — la partie tourne
  alors à rebours (`reversesOrder`). Les anciens journaux, joués un joueur à la
  fois (`rollFor`), gardent toujours la simple rotation : `simultaneous` les
  distingue, pour qu'une partie archivée ne change jamais de sièges au rejeu.
  Le départage sauvegarde dès son premier round : une partie peut donc être en
  pause avant d'avoir commencé. `DiceOffNotifier.resumeFromSave` reprend un
  départage inachevé là où il en était (même générateur, même journal) ;
  quittée sur son résultat, la partie reprend avec son premier tour lancé
  d'office par `GameNotifier.resumeFromSave`.

Les **fonctions pures** (encarts violets) — `rollDice`, `analyzeRoll`, `rollTurn`,
`applyKeepDecision`, `tryBank`, mais aussi celles qui lisent un journal
(`replayGame`, `replayTurnStarts`, `collectGameStatistics`, `scoreSeriesByPlayer`)
— sont des fonctions de haut niveau, pas des méthodes. Le RNG y est injectable,
ce qui rend les tests déterministes.

## Fiches, statistiques et journal (bas du diagramme)

Tout ce qu'on sait d'une partie terminée — sa courbe des scores, ses statistiques,
son rejeu — **se dérive du journal**, rien de plus n'est stocké :

- **`replayGame`** rejoue un journal (`GameAction` + seed) et rend l'état exact,
  ainsi que le générateur de dés là où le journal l'a laissé. C'est ce dernier
  point qui permet de **reprendre en cours de route** (reprise d'une partie mise
  en pause, saut à un tour du rejeu) sans jamais retomber sur d'autres dés.
- **`replayTurnStarts`** repère où commence chaque tour dans le journal : c'est
  ce qui borne le curseur du rejeu.
- **`GameStatisticsCollector`** observe le moteur avant et après chaque action
  (via le callback de `replayGame`) et n'implémente **aucune règle** : il compte.
  `GameStatistics` en rend un `PlayerStats` par siège, dans l'ordre de la config
  d'origine (l'ordre de jeu, lui, est réordonné par le tirage au sort — deux
  espaces d'index qu'il ne faut pas confondre ; `ReplayResult.playOrder` fait le
  pont).
- **`PlayerStats`** cumule les compteurs d'un joueur sur toutes ses parties
  (`operator +`). Il est immuable et tolérant à la lecture : un champ absent d'un
  fichier ancien vaut zéro.
- **`PlayerProfile`** est la fiche d'un joueur (nom, surnom, latéralité,
  anciens noms, statistiques). `displayName` est le surnom quand il y en a un, le
  nom sinon : c'est la règle d'affichage partout dans le jeu.

Conséquence de conception : les statistiques des fiches ne se **migrent** pas, elles
se **recalculent** en entier depuis les parties archivées
(`syncPlayerStatistics`). Corriger une statistique, c'est corriger le code qui la
compte, pas des données.

## L'IA (vert, dans le moteur)

`AiStrategy` est une interface à trois décisions ; trois profils l'implémentent
(`CautiousAi`, `BalancedAi`, `AggressiveAi`), sélectionnés par `AiDifficulty`.
La stratégie ne raisonne que sur le tour en cours : elle ignore le score déjà
acquis, donc le plafond de 10000. C'est `GameNotifier` qui borne ses réponses,
au seul endroit qui connaît les deux — et par le même calcul que celui affiché à
l'écran (`previewAiDeclineFives`), pour que l'affiché et le joué ne divergent
pas.

## La couche d'état (vert)

- **`GameNotifier`** enveloppe le `GameEngine` et expose les actions à l'UI. Ses
  méthodes `previewAi*` permettent d'afficher à l'avance ce que l'IA fera, sans
  rien modifier. Toute transition passe par `_commit`, qui **journalise l'action
  AVANT de publier le nouvel état**, puis persiste : les écrans écoutent le
  moteur et lisent le journal à l'instant où la partie est gagnée — un journal
  auquel manquerait le coup gagnant décrirait une partie « inachevée » (statistiques
  à zéro, rejeu qui n'atteint jamais la victoire). `gameRecord` est l'unique point
  d'entrée qui dit quelle partie est à l'écran, jouée ou rejouée.
- **`SavedGame` ne stocke pas l'état, mais le journal d'actions** (`GameAction`)
  et la seed. Une partie se reconstruit en rejouant ce journal
  (`replayGame` → `ReplayResult`).
- **Le rejeu spectateur** (`startReplay`) démarre directement sur la partie : le
  tirage au sort qui a fixé l'ordre de jeu n'est pas remis en scène, on n'en garde
  que le résultat. `seekReplay(tour)` reconstruit l'état exact au début d'un tour
  (avant comme après le tour actuel) ; `replayProgress` donne le tour à l'écran.
  Les providers du rejeu (vitesse, pause, progression) sont à part. Pendant un
  rejeu, l'écran de la partie jouée éventuellement resté empilé dessous se
  désintéresse du moteur (`isReplay`).
- **`PlayerStore`** persiste les fiches, un fichier par joueur, comme
  `GameSaveStore` le fait des parties.
- **`displayNamesFor`** résout les surnoms **à partir de la config de la partie
  affichée**, pas de la partie en cours : une partie archivée, ouverte quand aucune
  partie n'est en cours, se nomme correctement, et deux parties ayant un joueur du
  même nom ne se prêtent pas leurs surnoms.
- **`GameSaveStore`** lit/écrit les fichiers `.run` ; deux instances coexistent,
  une pour les parties en cours, une pour les archives.
- **`SettingsNotifier` / `AppSettings`** portent les préférences persistées ; la
  latéralité d'un joueur, elle, vient de sa fiche (`currentSeatRightHandedProvider`),
  le réglage d'appareil n'étant qu'un repli.

## L'interface (orange)

Représentée volontairement en couche grossière : les widgets Flutter sont
structurellement uniformes, et les détailler noierait le modèle. À retenir :
`GameScreen` est de loin l'écran le plus dense (il rend des vues différentes
selon l'état du tour, pilote l'avancement automatique et sert aussi de rejeu
spectateur, avec ses commandes fixées en bas), et deux services
vivent à part — `SoundEffects` (singleton observant le cycle de vie) et
`ShakeDetector` (accéléromètre → lancer de dés).

## Les autres schémas

Ces schémas complètent le diagramme de classes ; chacun se rouvre et se
ré-édite dans draw.io à partir de son PNG (ou de son `.drawio`). L'ensemble des
diagrammes UML (cas d'utilisation, composants, déploiement, machines à états,
séquences) est présenté dans [`uml.md`](uml.md).

- [`screen-flow.png`](screen-flow.png) — les écrans et les navigations entre eux
  (source : [`screen-flow.drawio`](screen-flow.drawio)). Le retour à l'accueil
  dépile jusqu'à `Setup` (`popToHome`) ; le rejeu spectateur est `Game` en
  `replayMode`, pas un écran à part.
- [`uml/state-game.png`](uml/state-game.png) — le cycle de vie d'une partie :
  choix de la main héritée, tour final et couronne qui change de main, pause,
  fin de partie et archivage (source : [`uml/state-game.drawio`](uml/state-game.drawio)).
- [`turn-state.png`](turn-state.png) — les états d'un tour, avec les deux
  impasses que `roll` détecte dès le lancer et l'exception de la quinte d'as
  (source : [`turn-state.drawio`](turn-state.drawio)).

## Régénérer le diagramme

Demandez simplement la mise à jour du diagramme d'architecture — par exemple
« mets à jour le diagramme de classes » — ou invoquez explicitement
`/architecture-diagram`.

La procédure est décrite dans
[`.claude/skills/architecture-diagram/SKILL.md`](../.claude/skills/architecture-diagram/SKILL.md) :
relever les classes dans le code, éditer le `.drawio`, exporter via
`.claude/skills/architecture-diagram/export.sh`, **relire le PNG produit**, puis
mettre ce document à jour.
