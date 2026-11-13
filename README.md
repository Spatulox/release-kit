# release-kit

Système de release par tag, réutilisable dans tous mes projets GitHub.

Pousser un tag `v1.2.0_beta` (ou `_rc`, `_release`, ou `v1.2.0`) :

```
push tag v* ─► tag      release-kit   décode le tag (version, canal, pré-release…)
            └► build    le projet     sa propre CI : construit les livrables
            └► publish  release-kit   release GitHub + notes du CHANGELOG.md
```

release-kit ne sait rien de la façon dont un projet se construit : il détecte le tag,
lance la CI du projet, puis publie ce qu'elle a produit.

## Installation dans un projet

1. Copier [`examples/release.yml`](examples/release.yml) dans `.github/workflows/release.yml`.
2. Copier [`examples/build.yml`](examples/build.yml) dans `.github/workflows/build.yml` et y
   mettre le build du projet.
3. Ajouter un `CHANGELOG.md` avec une section par version (voir plus bas).

C'est tout : `git tag v1.0.0_beta && git push origin v1.0.0_beta`.

## Les tags

| Tag              | `version` | `channel` | `prerelease` | `debversion`  |
|------------------|-----------|-----------|--------------|---------------|
| `v1.2.0_beta`    | `1.2.0`   | `beta`    | `true`       | `1.2.0~beta`  |
| `v1.2.0_rc`      | `1.2.0`   | `rc`      | `true`       | `1.2.0~rc`    |
| `v1.2.0_release` | `1.2.0`   | `release` | `false`      | `1.2.0`       |
| `v1.2.0`         | `1.2.0`   | `release` | `false`      | `1.2.0`       |

Tout autre tag `v*` fait échouer le run avant le build. `debversion` utilise `~` pour que
dpkg classe `1.2.0~beta < 1.2.0~rc < 1.2.0`.

Une pré-release n'est jamais marquée « latest » ; une release l'est.

## Contrat avec la CI du projet (`build.yml`)

- `on: workflow_call`, avec les inputs qu'elle utilise parmi `tag`, `version`, `channel`,
  `debversion` (type `string`). Un input passé par `release.yml` doit être déclaré, sinon
  GitHub refuse le workflow.
- Chaque fichier à publier est uploadé (`actions/upload-artifact`) dans un artifact dont le
  nom commence par `release-` : `release-linux`, `release-windows`… Tous sont fusionnés et
  joints à la release. Le préfixe se change avec l'input `artifact-pattern` de `publish`.
- Le `release.yml` du projet doit accorder `permissions: contents: write`.

## Notes de version

`publish` publie la section du CHANGELOG correspondant au tag, cherchée dans cet ordre :

1. `## v1.2.0_beta` (ou `## [v1.2.0_beta] - 2026-11-12`)
2. `## v1.2.0`
3. `## 1.2.0`

Section absente ou vide : warning et notes par défaut, ou échec avec `require-changelog: true`.

Pour prévisualiser en local :

```sh
bash ../release-kit/scripts/changelog.sh v1.2.0_beta CHANGELOG.md
```

## Référence

### `tag.yml`

| Input     | Défaut                 | |
|-----------|------------------------|-|
| `tag`     | le tag du run          | Tag à décoder |
| `kit-ref` | `v1`                   | Version de release-kit pour les scripts |

Outputs : `tag`, `version`, `channel`, `prerelease` (`"true"`/`"false"`), `debversion`.

### `publish.yml`

| Input               | Défaut                  | |
|---------------------|-------------------------|-|
| `tag`               | requis                  | Tag de la release |
| `prerelease`        | requis (booléen)        | `${{ needs.tag.outputs.prerelease == 'true' }}` |
| `title`             | `<nom du repo> <tag>`   | Titre de la release |
| `artifact-pattern`  | `release-*`             | Artifacts à joindre |
| `changelog`         | `CHANGELOG.md`          | Chemin du CHANGELOG |
| `require-changelog` | `false`                 | Échouer sans notes de version |
| `kit-ref`           | `v1`                    | Version de release-kit pour les scripts |

Relancer le run met à jour une release existante (notes, statut, fichiers écrasés).

## Versions

Les projets référencent `@v1`, un tag qui suit la dernière version `v1.x.y`.
Après une release compatible :

```sh
git tag v1.1.0 && git tag -f v1 && git push origin v1.1.0 && git push -f origin v1
```

Un changement incompatible devient `v2` (et `kit-ref: v2` par défaut).

Le repo doit être **public** pour que les workflows d'autres repos puissent l'appeler.

## Développement

```sh
bash tests/run.sh
shellcheck scripts/*.sh tests/run.sh
```
