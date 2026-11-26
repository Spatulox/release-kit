# Changelog

## v1.2.0

- `tag.yml` : inputs `require-changelog` et `changelog`, pour échouer avant le build quand le
  CHANGELOG n'a pas de section pour le tag.
- Build à blanc : un run qui n'est pas un push de tag (ex. `workflow_dispatch`) reçoit une
  version de dev (`scripts/dev-version.sh`, `debversion` `X.Y.Z+dev.<run>.g<sha>`) et l'output
  `dry-run` = `"true"` ; l'exemple `release.yml` saute alors la publication.

## v1.1.0

- Tags `vX.Y.Z_alpha` : pré-release, `debversion` `X.Y.Z~alpha` (classée avant `~beta`).

## v1.0.0

- Workflow réutilisable `tag.yml` : décode les tags `vX.Y.Z[_beta|_rc|_release]`.
- Workflow réutilisable `publish.yml` : release GitHub avec les artifacts `release-*` et la
  section du CHANGELOG.md, rejouable.
- Scripts `parse-tag.sh` et `changelog.sh`, utilisables en local.
- Extrait du workflow de release de MyGesClient.
