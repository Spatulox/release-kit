#!/usr/bin/env bash
# Tests des scripts de release-kit : bash tests/run.sh
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
parse="$root/scripts/parse-tag.sh"
changelog="$root/scripts/changelog.sh"
fixture="$root/tests/fixtures/CHANGELOG.md"

failures=0
nl=$'\n'

check() { # check <nom> <attendu> <obtenu>
  if [ "$2" = "$3" ]; then
    echo "ok   $1"
  else
    echo "FAIL $1"
    echo "  attendu : $(printf '%q' "$2")"
    echo "  obtenu  : $(printf '%q' "$3")"
    failures=$((failures + 1))
  fi
}

check_fails() { # check_fails <nom> <commande...>
  local name="$1"; shift
  if "$@" > /dev/null 2>&1; then
    echo "FAIL $name (devait échouer)"
    failures=$((failures + 1))
  else
    echo "ok   $name"
  fi
}

# --- parse-tag.sh -----------------------------------------------------------

check "tag beta" \
  "tag=v1.2.0_beta${nl}version=1.2.0${nl}channel=beta${nl}prerelease=true${nl}debversion=1.2.0~beta" \
  "$(bash "$parse" v1.2.0_beta)"

check "tag rc" \
  "tag=v10.0.3_rc${nl}version=10.0.3${nl}channel=rc${nl}prerelease=true${nl}debversion=10.0.3~rc" \
  "$(bash "$parse" v10.0.3_rc)"

check "tag release explicite" \
  "tag=v1.3.0_release${nl}version=1.3.0${nl}channel=release${nl}prerelease=false${nl}debversion=1.3.0" \
  "$(bash "$parse" v1.3.0_release)"

check "tag sans canal = release" \
  "tag=v1.3.0${nl}version=1.3.0${nl}channel=release${nl}prerelease=false${nl}debversion=1.3.0" \
  "$(bash "$parse" v1.3.0)"

for bad in 1.2.0 v1.2 v1.2.0_alpha v1.2.0-beta v1.2.0_beta2 beta_1.1 "v1.2.0_beta "; do
  check_fails "tag invalide '$bad'" bash "$parse" "$bad"
done
check_fails "tag absent" bash "$parse"

# --- changelog.sh -----------------------------------------------------------

check "section exacte" \
  "### Nouveautés${nl}- Exacte pour le tag beta." \
  "$(bash "$changelog" v1.2.0_beta "$fixture")"

check "section entre crochets avec date" \
  "- Section entre crochets avec une date." \
  "$(bash "$changelog" v2.0.0_rc "$fixture")"

check "repli sur ## vX.Y.Z" \
  "- Section commune à tous les canaux de 1.1.0." \
  "$(bash "$changelog" v1.1.0_rc "$fixture")"

check "repli sur ## X.Y.Z" \
  "- Titre sans \"v\"." \
  "$(bash "$changelog" v1.0.0_release "$fixture")"

check "section vide" "" "$(bash "$changelog" v0.9.0 "$fixture")"

check_fails "section absente" bash "$changelog" v3.0.0 "$fixture"
check_fails "fichier absent" bash "$changelog" v1.2.0_beta "$root/tests/fixtures/absent.md"

echo
if [ "$failures" -gt 0 ]; then
  echo "$failures test(s) en échec"
  exit 1
fi
echo "Tous les tests passent"
