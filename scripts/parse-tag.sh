#!/usr/bin/env bash
# Decodes a release tag and prints its fields as key=value
# (ready to append to $GITHUB_OUTPUT).
#
#   parse-tag.sh <tag>
#
# Accepted tags: vX.Y.Z_alpha, vX.Y.Z_beta, vX.Y.Z_rc, vX.Y.Z_release or vX.Y.Z (= release).
#
#   tag=v1.2.0_beta
#   version=1.2.0
#   channel=beta            (alpha | beta | rc | release)
#   prerelease=true         (false for release)
#   debversion=1.2.0~beta   ("~": dpkg sorts 1.2.0~alpha < 1.2.0~beta < 1.2.0~rc < 1.2.0)
#
# Exits with code 1 (message on stderr) if the tag is invalid.
set -euo pipefail

tag="${1:?usage: parse-tag.sh <tag>}"

if [[ ! "$tag" =~ ^v([0-9]+\.[0-9]+\.[0-9]+)(_(alpha|beta|rc|release))?$ ]]; then
  echo "Invalid tag '$tag' (expected: vX.Y.Z_alpha, vX.Y.Z_beta, vX.Y.Z_rc, vX.Y.Z_release or vX.Y.Z)" >&2
  exit 1
fi

version="${BASH_REMATCH[1]}"
channel="${BASH_REMATCH[3]:-release}"

if [ "$channel" = release ]; then
  prerelease=false
  debversion="$version"
else
  prerelease=true
  debversion="${version}~${channel}"
fi

echo "tag=$tag"
echo "version=$version"
echo "channel=$channel"
echo "prerelease=$prerelease"
echo "debversion=$debversion"
