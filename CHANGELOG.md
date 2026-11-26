# Changelog

## v1.2.1

- Everything in English: workflow descriptions, step names, error messages and job summaries,
  script messages, examples and tests.
- Documentation moved to the [wiki](https://github.com/Spatulox/release-kit/wiki).

## v1.2.0

- `tag.yml`: `require-changelog` and `changelog` inputs, to fail before the build when the
  CHANGELOG has no section for the tag.
- Dry run: a run that is not a tag push (e.g. `workflow_dispatch`) gets a dev version
  (`scripts/dev-version.sh`, `debversion` `X.Y.Z+dev.<run>.g<sha>`) and the `dry-run` output
  = `"true"`; the example `release.yml` then skips publishing.

## v1.1.0

- `vX.Y.Z_alpha` tags: pre-release, `debversion` `X.Y.Z~alpha` (sorted before `~beta`).

## v1.0.0

- Reusable workflow `tag.yml`: decodes `vX.Y.Z[_beta|_rc|_release]` tags.
- Reusable workflow `publish.yml`: GitHub release with the `release-*` artifacts and the
  CHANGELOG.md section, re-runnable.
- `parse-tag.sh` and `changelog.sh` scripts, usable locally.
- Extracted from the MyGesClient release workflow.
