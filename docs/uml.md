# Diagrammes UML de TenK

Chaque diagramme existe en deux fichiers : le `.drawio`, source éditable, et le `.png`, rendu qui embarque
aussi cette source (il se rouvre dans draw.io). Les trois premiers vivent à côté de la documentation
d'architecture ; les autres sont dans `docs/uml/`.

## Structure

### Classes — [`architecture/class-diagram.png`](architecture/class-diagram.png)

Les classes de `lib/game` et `lib/state`, champ par champ, et les grandes familles de `lib/ui`. Commenté en
détail dans [`architecture.md`](architecture.md).

### Paquets et composants — [`uml/components.png`](uml/components.png)

Les trois couches et le sens autorisé des dépendances : l'interface dépend de l'état, l'état orchestre le
moteur, et le moteur (`lib/game`) n'importe ni Flutter ni aucun paquet, ce qui permet de le tester en
isolation. Chaque bibliothèque externe est rattachée à la couche qui l'utilise, ainsi que les deux
stockages de l'appareil (fichiers JSON et SharedPreferences).

### Déploiement — [`uml/deployment.png`](uml/deployment.png)

Du Raspberry Pi, qui développe mais ne peut construire ni Android ni iOS, aux téléphones : le hook
`pre-push` qui incrémente le numéro de build, les trois jobs de la CI, les artefacts, Google Play (piste
internal), TestFlight et l'installation USB de l'IPA de développement. Il rappelle qu'un run vert ne prouve
pas l'envoi aux stores.

## Comportement

### Cas d'utilisation — [`uml/use-cases.png`](uml/use-cases.png)

Ce que la personne qui tient le téléphone peut faire. Un seul acteur : plusieurs joueurs humains se passent
le même appareil, et les bots font partie du système (ils jouent avec la même règle et les mêmes bornes
qu'un humain).

### Navigation entre écrans — [`screen-flow.png`](screen-flow.png)

Les 18 écrans et ce qui fait passer de l'un à l'autre.

## Machines à états

### Un tour de jeu — [`turn-state.png`](turn-state.png)

Lancer, garde des 5, arrêt, main pleine, craque et ses causes (dépassement au lancer, main pleine pile sur
10000), à l'intérieur d'un seul tour.

### Cycle de vie d'une partie — [`uml/state-game.png`](uml/state-game.png)

Ce qui se passe entre les tours : choix de la main héritée, tour final déclenché par le premier 10000 pile
(quinte d'as comprise), couronne qui change de main quand un autre atteint 10000 à son tour, fin de partie,
archivage, et la pause, possible à tout moment puisque chaque coup est déjà sauvegardé.

### Départage — [`uml/state-dice-off.png`](uml/state-dice-off.png)

Les rounds de lancer simultané, la relance des seuls ex-aequo au plus bas, puis la règle d'ordre : le sens
de la liste, sauf quand le dernier round était un duel entre voisins gagné par le second, qui fait tourner
la partie à rebours. Rappelle que les anciens journaux gardent toujours le sens de la liste.

## Séquences

### Tour d'un joueur humain — [`uml/seq-human-turn.png`](uml/seq-human-turn.png)

De l'écran à la sauvegarde, pour un lancer, une garde et un arrêt. Montre la règle qui compte le plus dans
la couche d'état : `_commit` ajoute l'action au journal **avant** de publier le nouvel état, puis la
sauvegarde part en arrière-plan, sérialisée par `_persistChain`.

### Tour d'un bot — [`uml/seq-ai-turn.png`](uml/seq-ai-turn.png)

Une action par appel de `playAiTurnStep`, relancée par l'écran après le délai IA. Les `preview*` servent
aussi à l'interface pour annoncer la décision : même calcul, donc pas de divergence possible.

### Nouvelle partie, départage, début de partie — [`uml/seq-new-game.png`](uml/seq-new-game.png)

Le départage crée l'identité de la partie (seed, alias) et commence le journal ; `handoff()` transmet à
`GameNotifier` le même générateur aléatoire, déjà consommé, pour que le rejeu retombe sur les mêmes dés.

### Reprise et rejeu — [`uml/seq-resume-replay.png`](uml/seq-resume-replay.png)

Une sauvegarde ne contient pas l'état du jeu mais le journal et la seed : la reprise d'une partie en pause
comme le rejeu d'une partie terminée reconstruisent tout avec `replayGame`. Le rejeu ne persiste jamais
rien. Une partie mise en pause avant son premier lancer reprend elle aussi : sur son départage s'il n'était
pas tranché (`DiceOffNotifier.resumeFromSave`), sinon avec son premier tour lancé d'office.

### Fin de partie, archivage, statistiques — [`uml/seq-game-over.png`](uml/seq-game-over.png)

Le fichier passe de `in-progress/` à `over/`, puis les statistiques des fiches sont recalculées en rejouant
toutes les parties archivées. Ce recalcul est gardé pour la session, mais l'archivage l'invalide : le
prochain écran de statistiques ou de joueurs compte la partie qui vient de finir.

## Diagrammes UML volontairement absents

- **Objets** : l'état du jeu est immuable et se reconstruit depuis le journal ; un instantané d'objets
  n'apprendrait rien que le diagramme de classes et les séquences ne montrent déjà.
- **Communication** : il dirait la même chose que les séquences, en moins lisible.
- **Timing** : les seules contraintes de temps (délais IA, auto-validation, animation des dés) sont des
  réglages ou des minuteries, déjà nommés dans les séquences.
- **Vue d'ensemble des interactions** : la navigation entre écrans joue déjà ce rôle.
- **Structure composite** : aucune classe n'a de structure interne assez riche pour le justifier.

## Régénérer

Les diagrammes sont édités dans draw.io (ou directement en XML), puis exportés en PNG avec
`.claude/skills/architecture-diagram/export.sh <fichier.drawio>`, qui vérifie que le PNG embarque bien sa
source. Il faut toujours regarder le PNG obtenu : un XML valide ne dit rien des libellés qui se chevauchent.
