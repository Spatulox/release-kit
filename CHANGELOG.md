# Changelog

## v1.0.0

- Workflow réutilisable `tag.yml` : décode les tags `vX.Y.Z[_beta|_rc|_release]`.
- Workflow réutilisable `publish.yml` : release GitHub avec les artifacts `release-*` et la
  section du CHANGELOG.md, rejouable.
- Scripts `parse-tag.sh` et `changelog.sh`, utilisables en local.
- Extrait du workflow de release de MyGesClient.
