#!/bin/sh
# Annonce aux applications installées qu'un build vient d'arriver sur un store :
# met à jour `latest.json` sur la branche `store-builds`, que l'application lit
# au lancement (via raw.githubusercontent.com, voir lib/state/update_check.dart)
# pour proposer la mise à jour :
#
#   {
#     "android": {"version": "1.0.0", "build": 95, "availableFrom": "2026-10-05T01:20:00Z"},
#     "ios":     {"version": "1.0.0", "build": 95, "availableFrom": "2026-10-05T01:35:00Z"}
#   }
#
# Appelé par .github/workflows/build_apk.yaml, seulement APRÈS un envoi réussi
# vers Google Play ou TestFlight : un run vert ne le prouve pas (les étapes
# d'envoi sont `continue-on-error`), et un build annoncé mais absent du store
# enverrait le joueur sur une fiche sans mise à jour. `availableFrom` laisse au
# store le temps de traiter le build (TestFlight met plusieurs minutes) :
# l'application n'en parle pas avant.
#
# Une branche à part, jamais fusionnée, plutôt qu'un commit sur main : pas de
# build déclenché, rien dans l'historique ni dans le changelog. Les jobs Android
# et iOS l'écrivent en parallèle, d'où la reprise sur un push refusé.
#
# Usage : publish_store_build.sh <android|ios> <délai de traitement en minutes>
# (version et build lus dans pubspec.yaml).
set -eu

platform="$1"
delay_minutes="$2"
case "$platform" in
  android|ios) ;;
  *) echo "plateforme inconnue : $platform" >&2; exit 2 ;;
esac

version=$(sed -n 's/^version: \([0-9]*\.[0-9]*\.[0-9]*\)+[0-9]*$/\1/p' pubspec.yaml)
build=$(sed -n 's/^version: [0-9]*\.[0-9]*\.[0-9]*+\([0-9]*\)$/\1/p' pubspec.yaml)
if [ -z "$version" ] || [ -z "$build" ]; then
  echo "Ligne 'version:' illisible dans pubspec.yaml" >&2
  exit 1
fi
now=$(date -u +%s)
# `date -d` (GNU, runner Ubuntu) ou `date -r` (BSD, runner macOS).
at=$((now + delay_minutes * 60))
available_from=$(date -u -d "@$at" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -r "$at" +%Y-%m-%dT%H:%M:%SZ)

branch=store-builds
work=$(mktemp -d)
cleanup() {
  git worktree remove --force "$work/repo" 2>/dev/null || true
  git branch -q -D "$branch-local" 2>/dev/null || true
  rm -rf "$work"
}
trap cleanup EXIT

# Un worktree du checkout courant plutôt qu'un clone : il en garde le jeton
# d'accès, qu'actions/checkout n'a posé que là.
attempt=1
while :; do
  cleanup
  mkdir -p "$work"
  if git fetch -q origin "+refs/heads/$branch:refs/remotes/origin/$branch" 2>/dev/null; then
    git worktree add -q --detach "$work/repo" "origin/$branch"
  else
    # Toute première annonce : la branche naît sans historique commun avec main.
    git worktree add -q --detach "$work/repo"
    git -C "$work/repo" switch -q --orphan "$branch-local"
  fi

  file="$work/repo/latest.json"
  [ -f "$file" ] || echo '{}' > "$file"
  # Un build plus ancien (run relancé à la main) n'écrase pas un plus récent.
  current=$(jq -r --arg p "$platform" '.[$p].build // 0' "$file")
  if [ "$current" -ge "$build" ]; then
    echo "latest.json annonce déjà $platform build $current (>= $build) : rien à faire."
    exit 0
  fi
  jq --arg p "$platform" --arg v "$version" --argjson b "$build" --arg at "$available_from" \
    '.[$p] = {version: $v, build: $b, availableFrom: $at}' "$file" > "$file.tmp"
  mv "$file.tmp" "$file"

  git -C "$work/repo" add latest.json
  git -C "$work/repo" -c user.name="github-actions[bot]" -c user.email="github-actions[bot]@users.noreply.github.com" \
    commit -q -m "$platform $version+$build disponible à partir de $available_from"
  if git -C "$work/repo" push -q origin "HEAD:$branch"; then
    echo "Annoncé : $platform $version+$build, à partir de $available_from."
    exit 0
  fi
  if [ "$attempt" -ge 5 ]; then
    echo "Push refusé $attempt fois, abandon." >&2
    exit 1
  fi
  attempt=$((attempt + 1))
  sleep $((attempt * 2))
done
