# Releasing Kubeflow Katib

## Prerequisites

- [Write](https://docs.github.com/en/organizations/managing-access-to-your-organizations-repositories/repository-permission-levels-for-an-organization#permission-levels-for-repositories-owned-by-an-organization)
  permission for the Katib repository.

- Docker available locally (required for changelog generation with
  [`git-cliff`](https://git-cliff.org/)).

- Create a [GitHub Token](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token)
  and set it as `GITHUB_TOKEN` environment variable.

- GitHub **`release` environment** with required reviewers (gates PyPI and GitHub Release jobs).

- [PyPI trusted publishing](https://docs.pypi.org/trusted-publishers/) for `kubeflow-katib` and
  `kubeflow_katib_api` (workflow: `release.yaml`, owner: `kubeflow`, repo: `katib`).

- Repository secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`.

## Versioning Policy

Katib follows [Semantic Versioning](https://semver.org/) and Python [PEP 440](https://peps.python.org/pep-0440/)
for SDK packages.

| Artifact | Format | Example |
| --- | --- | --- |
| `VERSION` file / git tag | `vX.Y.Z` or `vX.Y.Z-rc.N` | `v0.19.1`, `v0.19.0-rc.0` |
| Python SDK / API | `X.Y.Z` or `X.Y.ZrcN` | `0.19.1`, `0.19.0rc0` |
| Release branch | `release-X.Y` | `release-0.19` |

## Release Branches

Release branches use the format `release-X.Y` (for example `release-0.19`).

- **Latest minor series**: open a PR to `master`.
- **Older minor patch**: open a PR to the corresponding `release-X.Y` branch (backport fixes via PRs).

Manifest image tags stay at `latest` on `master`. CI pins them on the `release-X.Y` branch during the
automated release workflow.

## Changelog Structure

Changelogs live under `CHANGELOG/`:

```text
CHANGELOG/
├── CHANGELOG-0.19.md
└── ...
```

The release script (`hack/release.sh`) prepends new entries using `git-cliff`.

## Step-by-Step Release Process

### 1. Update version and changelog

```bash
make release VERSION=X.Y.Z GITHUB_TOKEN=<token>
# or for a release candidate:
make release VERSION=X.Y.Z-rc.N GITHUB_TOKEN=<token>
```

This will:

1. Update `VERSION` to `vX.Y.Z`.
2. Update `sdk/python/v1beta1/setup.py`, `hack/python-api/gen-api.sh`, and
   `api/python_api/kubeflow_katib_api/__init__.py`.
3. Generate `CHANGELOG/CHANGELOG-X.Y.md` using `git-cliff`.
4. Run `make generate`.
5. Create a signed-off commit: `Release vX.Y.Z`.

### 2. Submit a release PR

- **Latest minor release** (including patches on the latest minor series): PR to `master`.
- **Old minor series patch**: PR to `release-X.Y`.

Wait for the [Check Release](https://github.com/kubeflow/katib/actions/workflows/check-release.yaml) workflow.

### 3. Automated release after merge

When the `VERSION` change is merged, the
[release workflow](.github/workflows/release.yaml) runs automatically:

1. Validates version and Python package versions.
2. Runs Go unit tests.
3. Builds Katib SDK and API Python packages.
4. Creates or updates the `release-X.Y` branch and pins manifest image tags.
5. Publishes to PyPI (requires `release` environment approval).
6. Creates and pushes the git tag and GitHub Release (requires `release` environment approval).
7. Publishes multi-arch container images to GHCR and DockerHub.

> **Note**: Manifest image tags are only updated on the release branch, not on `master`.

### 4. Verify

- [GHCR](https://github.com/kubeflow/katib/pkgs/container/katib) and [DockerHub](https://hub.docker.com/u/kubeflowkatib)
- [PyPI kubeflow-katib](https://pypi.org/project/kubeflow-katib/) and [kubeflow-katib-api](https://pypi.org/project/kubeflow-katib-api/)
- [GitHub Releases](https://github.com/kubeflow/katib/releases)

## Announcement

For minor/major releases, announce on Kubeflow community channels
([Slack](https://www.kubeflow.org/docs/about/community/#kubeflow-slack-channels),
[mailing list](https://www.kubeflow.org/docs/about/community/#kubeflow-mailing-list)).
