# release-kit

Reusable tag-based release system for all my GitHub projects.

Pushing a tag like `v1.2.0_beta` (or `_alpha`, `_rc`, `_release`, or `v1.2.0`):

```
push tag v* ─► tag      release-kit   decodes the tag (version, channel, pre-release...)
             └► build    the project  its own CI: builds the deliverables
             └► publish  release-kit   GitHub release + notes from CHANGELOG.md
```

release-kit knows nothing about how a project is built: it detects the tag, triggers the project's CI, then publishes what it produced.

## Installation in a project

1. Copy [`examples/release.yml`](examples/release.yml) to `.github/workflows/release.yml`.
2. Copy [`examples/build.yml`](examples/build.yml) to `.github/workflows/build.yml` and add the project's build there.
3. Add a `CHANGELOG.md` with a section per version (see below).

That's it: `git tag v1.0.0_beta && git push origin v1.0.0_beta`.

## Tags

| Tag              | `version` | `channel` | `prerelease` | `debversion`  |
|------------------|-----------|-----------|--------------|---------------|
| `v1.2.0_alpha`   | `1.2.0`   | `alpha`   | `true`       | `1.2.0~alpha` |
| `v1.2.0_beta`    | `1.2.0`   | `beta`    | `true`       | `1.2.0~beta`  |
| `v1.2.0_rc`      | `1.2.0`   | `rc`      | `true`       | `1.2.0~rc`    |
| `v1.2.0_release` | `1.2.0`   | `release` | `false`      | `1.2.0`       |
| `v1.2.0`         | `1.2.0`   | `release` | `false`      | `1.2.0`       |

Any other `v*` tag will fail the run before the build. `debversion` uses `~` so that dpkg sorts `1.2.0~alpha < 1.2.0~beta < 1.2.0~rc < 1.2.0`.

A pre-release is never marked as "latest"; a release is.

## Contract with the project's CI (`build.yml`)

- `on: workflow_call`, with the inputs it uses from `tag`, `version`, `channel`, `debversion` (type `string`). An input passed by `release.yml` must be declared, otherwise GitHub rejects the workflow.
- Each file to be published is uploaded (`actions/upload-artifact`) in an artifact whose name starts with `release-`: `release-linux`, `release-windows`, etc. All are merged and attached to the release. The prefix can be changed with the `artifact-pattern` input in `publish`.
- The project's `release.yml` must grant `permissions: contents: write`.

## Release notes

`publish` publishes the section of the CHANGELOG corresponding to the tag, searched in this order:

1. `## v1.2.0_beta` (or `## [v1.2.0_beta] - 2026-11-12`)
2. `## v1.2.0`
3. `## 1.2.0`

Missing or empty section: warning and default notes, or failure with `require-changelog: true`.
Pass `require-changelog: true` to `tag` as well to fail at once, before anything is built.

To preview locally:

```sh
bash ../release-kit/scripts/changelog.sh v1.2.0_beta CHANGELOG.md
```

## Reference

### `tag.yml`

| Input               | Default        | |
|---------------------|----------------|-|
| `tag`               | the run's tag  | Tag to decode |
| `require-changelog` | `false`        | Fail before the build if `CHANGELOG.md` has no section for the tag |
| `changelog`         | `CHANGELOG.md` | CHANGELOG path (with `require-changelog`) |
| `kit-ref`           | `v1`           | release-kit version for scripts |

Outputs: `tag`, `version`, `channel`, `prerelease` (`"true"`/`"false"`), `debversion`.

### `publish.yml`

| Input               | Default                  | |
|---------------------|-------------------------|-|
| `tag`               | required                | Release tag |
| `prerelease`        | required (boolean)      | `${{ needs.tag.outputs.prerelease == 'true' }}` |
| `title`             | `<repo name> <tag>`     | Release title |
| `artifact-pattern`  | `release-*`             | Artifacts to attach |
| `changelog`         | `CHANGELOG.md`          | CHANGELOG path |
| `require-changelog` | `false`                 | Fail without release notes |
| `kit-ref`           | `v1`                    | release-kit version for scripts |

Re-running the workflow updates an existing release (notes, status, overwritten files).

## Versions

Projects reference `@v1`, a tag that follows the latest `v1.x.y` version.
After a compatible release:

```sh
git tag v1.1.0 && git tag -f v1 && git push origin v1.1.0 && git push -f origin v1
```

A breaking change becomes `v2` (and `kit-ref: v2` by default).

The repo must be **public** so that workflows from other repos can call it.

## Development

```sh
bash tests/run.sh
shellcheck scripts/*.sh tests/run.sh
```
