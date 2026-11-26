#!/usr/bin/env bash
# Version d'un build à blanc (run qui n'est pas un push de tag), au format de parse-tag.sh.
# À lancer dans le repo du projet (historique et tags récupérés : fetch-depth 0).
#
#   dev-version.sh <numéro du run> <sha du commit>
#
# La version de base est celle du dernier tag de release (vX.Y.Z[_canal]) atteignable
# depuis HEAD, 0.0.0 s'il n'y en a pas :
#
#   tag=v1.2.0_dev.42
#   version=1.2.0
#   channel=dev
#   prerelease=true
#   debversion=1.2.0+dev.42.gabc1234   ("+" : après 1.2.0 ; ni "-" ni "_", refusés par rpm)
set -euo pipefail

run="${1:?usage: dev-version.sh <numéro du run> <sha>}"
sha="${2:?usage: dev-version.sh <numéro du run> <sha>}"

if [[ ! "$run" =~ ^[0-9]+$ ]]; then
  echo "Numéro de run invalide : '$run'" >&2
  exit 1
fi
if [[ ! "$sha" =~ ^[0-9a-f]{7,40}$ ]]; then
  echo "Sha invalide : '$sha'" >&2
  exit 1
fi

version=0.0.0
while IFS= read -r tag; do
  if [[ "$tag" =~ ^v([0-9]+\.[0-9]+\.[0-9]+)(_(alpha|beta|rc|release))?$ ]]; then
    version="${BASH_REMATCH[1]}"
    break
  fi
done < <(git tag --merged HEAD --list 'v*' --sort=-version:refname)

echo "tag=v${version}_dev.$run"
echo "version=$version"
echo "channel=dev"
echo "prerelease=true"
echo "debversion=${version}+dev.$run.g${sha:0:7}"
