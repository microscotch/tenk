#!/bin/sh
# Ajoute en tête de Changelog.MD l'entrée du build <version> (ex. 1.0.0+90),
# à partir des commits faits depuis le dernier tag (une release) : la liste est
# cumulative, chaque build reprend tout ce qui a changé depuis ce tag, jusqu'à ce
# qu'un nouveau tag soit posé. Sans aucun tag, depuis le précédent incrément du
# build number :
#
#   ## 1.0.0+90 changelog
#
#   * [✨](https://github.com/microscotch/tenk/tree/457e25f…): show the active player's 5s choice live…
#   * [🐛](https://github.com/microscotch/tenk/tree/803537f…): stop stacking "server unreachable" messages…
#
# Le type du commit (convention `type: sujet`) devient une icône, lien vers
# l'arbre du dépôt tel qu'il était à ce commit (adresse tirée du remote
# `origin`, ou de CHANGELOG_REPO_URL si elle est posée) ; les `chore:`
# (dont les incréments eux-mêmes) et les `ci:` n'y figurent pas, ni les merges.
# Rien à mettre (que du chore/ci) : le fichier n'est pas touché. La CI doit
# donc récupérer les tags avec l'historique (`fetch-depth: 0` le fait).
#
# Appelé juste avant l'incrément, par .githooks/pre-push et par le job
# `bump-build-number` de .github/workflows/build_apk.yaml : l'entrée part dans le
# même commit que le nouveau build number. Rend 0 dans tous les cas.
set -e

version="$1"
file="${2:-Changelog.MD}"
if [ -z "$version" ]; then
  echo "usage: $0 <version+build> [fichier]" >&2
  exit 2
fi

# Le dernier tag accessible depuis HEAD ; à défaut, le précédent incrément (le
# dernier commit dont le sujet l'annonce).
since=$(git describe --tags --abbrev=0 HEAD 2>/dev/null || true)
[ -n "$since" ] || since=$(git log -1 --format=%H --grep='^chore: bump build number' HEAD || true)
range="HEAD"
[ -n "$since" ] && range="$since..HEAD"

# https://github.com/<propriétaire>/<dépôt>, depuis une adresse https ou ssh.
repo_url="${CHANGELOG_REPO_URL:-$(git remote get-url origin 2>/dev/null || true)}"
repo_url=$(printf '%s' "$repo_url" | sed -e 's#^git@github\.com:#https://github.com/#' -e 's#^ssh://git@github\.com/#https://github.com/#' -e 's#\.git$##' -e 's#/$##')

icon_for() {
  case "$1" in
    feat) printf '✨' ;;
    fix) printf '🐛' ;;
    docs) printf '📝' ;;
    refactor) printf '♻️' ;;
    perf) printf '⚡️' ;;
    test) printf '✅' ;;
    build) printf '📦' ;;
    style) printf '🎨' ;;
    revert) printf '⏪' ;;
    *) printf '🔹' ;;
  esac
}

entries=$(mktemp)
trap 'rm -f "$entries" "$entries.new"' EXIT

git log --reverse --no-merges --format='%H %s' "$range" | while IFS=' ' read -r sha subject; do
  # `type(portée)!: sujet` → type et sujet ; sans type reconnaissable, le sujet entier.
  type=$(printf '%s' "$subject" | sed -n 's/^\([a-z]*\)\(([^)]*)\)\{0,1\}!\{0,1\}: .*/\1/p')
  case "$type" in
    chore|ci) continue ;;
  esac
  if [ -n "$type" ]; then
    text=$(printf '%s' "$subject" | sed 's/^[a-z]*\(([^)]*)\)\{0,1\}!\{0,1\}: //')
  else
    text="$subject"
  fi
  icon=$(icon_for "$type")
  if [ -n "$repo_url" ]; then
    printf '* [%s](%s/tree/%s): %s\n' "$icon" "$repo_url" "$sha" "$text" >> "$entries"
  else
    printf '* %s: %s\n' "$icon" "$text" >> "$entries"
  fi
done

if [ ! -s "$entries" ]; then
  echo "changelog: rien à ajouter pour $version (que des commits chore/ci)." >&2
  exit 0
fi

{
  printf '# Changelog\n\n'
  printf '## %s changelog\n\n' "$version"
  cat "$entries"
  if [ -f "$file" ]; then
    # Les entrées précédentes, sans le titre du fichier.
    printf '\n'
    sed '1{/^# Changelog$/d}' "$file" | sed '/./,$!d'
  fi
} > "$entries.new"
mv "$entries.new" "$file"
echo "changelog: entrée $version ajoutée à $file." >&2
