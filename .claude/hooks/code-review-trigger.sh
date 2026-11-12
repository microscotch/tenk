#!/usr/bin/env bash
# PostToolUse (Bash, `git commit *`) : après un commit de développement, demande à Claude de lancer
# l'agent code-review-watcher. Silencieux pour les commits `code-review:`, `chore:` et `ci:`
# (dont le bump de build du hook pre-push), et pour un commit déjà signalé.
cat >/dev/null  # la charge JSON du hook n'est pas utilisée : l'état se lit dans git
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
sha=$(git rev-parse --short HEAD 2>/dev/null) || exit 0
subject=$(git log -1 --format=%s 2>/dev/null) || exit 0
case "$subject" in
  code-review:*|chore:*|ci:*) exit 0 ;;
esac
marker="$(git rev-parse --git-dir)/code-review-watcher-last"
[ "$(cat "$marker" 2>/dev/null)" = "$sha" ] && exit 0
printf '%s' "$sha" > "$marker"
jq -n --arg sha "$sha" --arg subject "$subject" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: ("Commit de développement " + $sha + " (« " + $subject + " »). Lance maintenant l'"'"'agent code-review-watcher (Agent, subagent_type: \"code-review-watcher\") pour relire ce commit, appliquer les améliorations et les commiter sous le préfixe code-review:. Ne le relance pas pour un commit code-review:, chore: ou ci:.")
  }
}'
