# Local Release Workflow Testing

This guide explains how to validate the Katib release pipeline locally and on a fork before running a real release on `kubeflow/katib`.

See [RELEASE.md](../../RELEASE.md) for the maintainer release process.

## Overview

The release workflow (`.github/workflows/release.yaml`) can be tested at three levels:

| Level | Tool | What it validates |
| --- | --- | --- |
| **Local script** | `make test-release` | Version consistency, changelog, package build |
| **CI dry run** | GitHub Actions `dry_run: true` | Same as local script, plus workflow wiring on GitHub runners |
| **PR gate** | Check Release workflow | Version consistency on pull requests |

The local script mirrors the **Prepare** and **Build** jobs when `dry_run: true`.

Manifest image tags are **not** updated locally — they stay at `latest` on `master`. CI pins them on the
`release-X.Y` branch during the Prepare job.

## Quick Start (Local)

From the repository root:

```sh
# 1. Prepare release files locally (does not push or publish)
make release VERSION=0.19.1

# 2. Run the local dry-run validator
make test-release
```

If all checks pass, you will see `Katib release local dry run PASSED`.

### Script options

```sh
./scripts/v1beta1/test-release.sh --help

# Offline validation (no git remote required)
./scripts/v1beta1/test-release.sh --skip-remote

# Skip package build (faster, metadata-only checks)
./scripts/v1beta1/test-release.sh --skip-build

# Custom remote
RELEASE_REMOTE=upstream ./scripts/v1beta1/test-release.sh
```

## What the Local Script Checks

The script runs the same validations as the CI dry run:

1. **Parse metadata** — reads `setup.py`, derives tag (`vX.Y.Z`), branch (`release-X.Y`), pre-release flag
2. **Version consistency** — `setup.py`, `gen-api.sh`, `kubeflow_katib_api/__init__.py` must match
3. **Changelog** — stable releases require `# [vX.Y.Z]` in `CHANGELOG.md` (skipped for RC)
4. **Remote tag** — tag must not already exist on `origin` (unless `--skip-remote`)
5. **Package build** — builds `kubeflow-katib` and `kubeflow_katib_api`, runs `twine check`

Nothing is pushed, tagged, or published.

## Test on a GitHub Fork

Use a fork to exercise the full GitHub Actions workflow without affecting `kubeflow/katib`.

### 1. Fork and clone

```sh
git clone git@github.com:<your-user>/katib.git
cd katib
git remote add upstream git@github.com:kubeflow/katib.git
```

### 2. Prepare a test release commit

```sh
make release VERSION=0.0.0-test
# Or use a realistic version for your fork experiment, e.g. 0.19.1-rc.test
git checkout -b test/release-dry-run
git add -A
git commit -m "test: release dry run"
git push origin test/release-dry-run
```

> Use a version that does not conflict with an existing PyPI release or upstream tag when testing a real release on a fork.

### 3. Run CI dry run on the fork

1. Open your fork on GitHub → **Actions** → **Release**
2. Click **Run workflow**
3. Branch: `test/release-dry-run`
4. **`dry_run`: enabled** (default)
5. Run workflow

Expected result:

- **Prepare release branch** — passes, prints plan, does not push
- **Build packages** — passes
- **Dry run summary** — green summary in the workflow run
- **Create tag / Publish images / PyPI / GitHub Release** — skipped

### 4. Fork secrets (optional, for full non-dry-run testing)

Only needed if you test `dry_run: false` on a fork:

| Secret | Purpose |
| --- | --- |
| `DOCKERHUB_USERNAME` | Push release images |
| `DOCKERHUB_TOKEN` | Push release images |

Configure PyPI trusted publishing for your fork if testing PyPI upload.

Create a GitHub **release** environment with yourself as reviewer to exercise approval gates.

> **Do not** run `dry_run: false` on a fork with a version that already exists on PyPI or Docker Hub under the official `kubeflowkatib` org unless you intend a real publish.

## End-to-End Checklist

Use this sequence before a production release:

```sh
# Local
make release VERSION=X.Y.Z
make test-release
git diff --stat

# PR
# - Open PR to master or release-X.Y
# - Wait for Check Release workflow

# CI dry run (on PR branch)
# - Actions -> Release -> Run workflow -> dry_run: true

# Production release
# - Merge PR (triggers real release), or
# - Run workflow with dry_run: false after sign-off
```

See [RELEASE.md](../../RELEASE.md) for the full release process.

## Troubleshooting

### `Tag vX.Y.Z already exists on origin`

The version was already released. Bump to a new patch/RC version in `setup.py` and re-run `make release`.

### `Missing CHANGELOG.md section`

For stable releases, add a section:

```markdown
# [vX.Y.Z] (YYYY-MM-DD)
```

Or run `make release VERSION=X.Y.Z` with `git-cliff` installed.

### `twine check` fails

Inspect build output under `sdk/python/v1beta1/dist/` and `api/python_api/dist/`. Fix packaging metadata before merging.

### CI dry run passes locally but fails in Actions

- Confirm the same commit is on the branch selected in **Run workflow**
- Compare Python version (CI uses 3.11)
- Check workflow logs for the failing step name and match it to a section in `test-release.sh`

## Related Files

| File | Purpose |
| --- | --- |
| `RELEASE.md` | Maintainer release guide |
| `scripts/v1beta1/test-release.sh` | Local dry-run validator |
| `scripts/v1beta1/prepare-release.sh` | Version bump helper (manifests pinned in CI) |
| `.github/workflows/release.yaml` | Release workflow |
| `.github/workflows/check-release.yaml` | PR validation |
