#!/usr/bin/env bash
# Version of a dry run (a run that is not a tag push), in the format of parse-tag.sh.
# Run it inside the project's repo (with history and tags fetched: fetch-depth 0).
#
#   dev-version.sh <run number> <commit sha>
#
# The base version is the one of the latest release tag (vX.Y.Z[_channel]) reachable
# from HEAD, 0.0.0 if there is none:
#
#   tag=v1.2.0_dev.42
#   version=1.2.0
#   channel=dev
#   prerelease=true
#   debversion=1.2.0+dev.42.gabc1234   ("+": after 1.2.0; neither "-" nor "_", rejected by rpm)
set -euo pipefail

run="${1:?usage: dev-version.sh <run number> <sha>}"
sha="${2:?usage: dev-version.sh <run number> <sha>}"

if [[ ! "$run" =~ ^[0-9]+$ ]]; then
  echo "Invalid run number: '$run'" >&2
  exit 1
fi
if [[ ! "$sha" =~ ^[0-9a-f]{7,40}$ ]]; then
  echo "Invalid sha: '$sha'" >&2
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
