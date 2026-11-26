#!/usr/bin/env bash
# Tests for the release-kit scripts: bash tests/run.sh
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
parse="$root/scripts/parse-tag.sh"
changelog="$root/scripts/changelog.sh"
devversion="$root/scripts/dev-version.sh"
fixture="$root/tests/fixtures/CHANGELOG.md"

failures=0
nl=$'\n'

check() { # check <name> <expected> <actual>
  if [ "$2" = "$3" ]; then
    echo "ok   $1"
  else
    echo "FAIL $1"
    echo "  expected: $(printf '%q' "$2")"
    echo "  actual:   $(printf '%q' "$3")"
    failures=$((failures + 1))
  fi
}

check_fails() { # check_fails <name> <command...>
  local name="$1"; shift
  if "$@" > /dev/null 2>&1; then
    echo "FAIL $name (should have failed)"
    failures=$((failures + 1))
  else
    echo "ok   $name"
  fi
}

# --- parse-tag.sh -----------------------------------------------------------

check "tag alpha" \
  "tag=v1.2.0_alpha${nl}version=1.2.0${nl}channel=alpha${nl}prerelease=true${nl}debversion=1.2.0~alpha" \
  "$(bash "$parse" v1.2.0_alpha)"

check "tag beta" \
  "tag=v1.2.0_beta${nl}version=1.2.0${nl}channel=beta${nl}prerelease=true${nl}debversion=1.2.0~beta" \
  "$(bash "$parse" v1.2.0_beta)"

check "tag rc" \
  "tag=v10.0.3_rc${nl}version=10.0.3${nl}channel=rc${nl}prerelease=true${nl}debversion=10.0.3~rc" \
  "$(bash "$parse" v10.0.3_rc)"

check "explicit release tag" \
  "tag=v1.3.0_release${nl}version=1.3.0${nl}channel=release${nl}prerelease=false${nl}debversion=1.3.0" \
  "$(bash "$parse" v1.3.0_release)"

check "tag without channel = release" \
  "tag=v1.3.0${nl}version=1.3.0${nl}channel=release${nl}prerelease=false${nl}debversion=1.3.0" \
  "$(bash "$parse" v1.3.0)"

for bad in 1.2.0 v1.2 v1.2.0_dev v1.2.0-alpha v1.2.0-beta v1.2.0_beta2 beta_1.1 "v1.2.0_beta "; do
  check_fails "invalid tag '$bad'" bash "$parse" "$bad"
done
check_fails "missing tag" bash "$parse"

# debversion order for dpkg: alpha < beta < rc < release
if command -v dpkg >/dev/null; then
  if dpkg --compare-versions 1.2.0~alpha lt 1.2.0~beta \
     && dpkg --compare-versions 1.2.0~beta lt 1.2.0~rc \
     && dpkg --compare-versions 1.2.0~rc lt 1.2.0; then
    echo "ok   dpkg order alpha < beta < rc < release"
  else
    echo "FAIL dpkg order alpha < beta < rc < release"
    failures=$((failures + 1))
  fi
fi

# --- changelog.sh -----------------------------------------------------------

check "exact section" \
  "### New${nl}- Exact match for the beta tag." \
  "$(bash "$changelog" v1.2.0_beta "$fixture")"

check "bracketed section with a date" \
  "- Bracketed section with a date." \
  "$(bash "$changelog" v2.0.0_rc "$fixture")"

check "fallback to ## vX.Y.Z" \
  "- Section shared by all 1.1.0 channels." \
  "$(bash "$changelog" v1.1.0_rc "$fixture")"

check "fallback to ## X.Y.Z" \
  "- Heading without \"v\"." \
  "$(bash "$changelog" v1.0.0_release "$fixture")"

check "empty section" "" "$(bash "$changelog" v0.9.0 "$fixture")"

check_fails "missing section" bash "$changelog" v3.0.0 "$fixture"
check_fails "missing file" bash "$changelog" v1.2.0_beta "$root/tests/fixtures/absent.md"

# --- dev-version.sh ---------------------------------------------------------

repo="$(mktemp -d)"
trap 'rm -rf "$repo"' EXIT
git_() { git -C "$repo" -c user.name=test -c user.email=test@example.org -c commit.gpgsign=false -c tag.gpgsign=false "$@"; }
git_ init -q
git_ commit -q --allow-empty -m first
dev() { (cd "$repo" && bash "$devversion" "$@"); }

check "dry run without tags" \
  "tag=v0.0.0_dev.7${nl}version=0.0.0${nl}channel=dev${nl}prerelease=true${nl}debversion=0.0.0+dev.7.g0123456" \
  "$(dev 7 0123456789abcdef0123456789abcdef01234567)"

git_ tag v1            # moving tag: ignored
git_ tag v1.2.0_beta
git_ tag v1.9.0
git_ tag v1.10.0_rc
git_ commit -q --allow-empty -m second
git_ tag v9.0.0 HEAD   # not reachable after the checkout below
git_ checkout -q HEAD~1
check "latest reachable tag, sorted by version" \
  "tag=v1.10.0_dev.12${nl}version=1.10.0${nl}channel=dev${nl}prerelease=true${nl}debversion=1.10.0+dev.12.gabcdef0" \
  "$(dev 12 abcdef0)"

check_fails "invalid run" dev x12 abcdef0
check_fails "invalid sha" dev 12 xyz
check_fails "missing arguments" dev

if command -v dpkg >/dev/null; then
  if dpkg --compare-versions 1.2.0 lt 1.2.0+dev.3.gabc1234 \
     && dpkg --compare-versions 1.2.0+dev.3.gabc1234 lt 1.2.0+dev.12.gabc1234; then
    echo "ok   dpkg order release < dev.3 < dev.12"
  else
    echo "FAIL dpkg order release < dev.3 < dev.12"
    failures=$((failures + 1))
  fi
fi

echo
if [ "$failures" -gt 0 ]; then
  echo "$failures test(s) failed"
  exit 1
fi
echo "All tests pass"
