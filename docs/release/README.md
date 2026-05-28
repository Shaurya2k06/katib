# Release the Katib Project

This guide follows the same release model as the [Kubeflow SDK](https://github.com/kubeflow/sdk/blob/main/RELEASE.md).

## Release timeline

| Step | Action | Outcome |
| --- | --- | --- |
| 0 | [One-time setup](#0-one-time-setup) | Infra ready for automated releases |
| 1 | [Prepare locally](#1-prepare-locally) | Version bumps and changelog on disk |
| 2 | [Validate locally](#2-validate-locally) | Dry-run checks pass |
| 3 | [Pre-flight checklist](#3-pre-flight-checklist) | Ready to open or merge PR |
| 4 | [Open a PR](#4-open-a-pr) | Review + Check Release CI |
| 5 | [CI dry run (optional)](#5-ci-dry-run-optional) | Workflow validated on GitHub |
| 6 | [Merge and automate](#6-merge-and-automate) | Branch, tag, images built |
| 7 | [Approve publishing](#7-approve-publishing) | PyPI + GitHub Release |
| 8 | [Verify release](#8-verify-release) | Artifacts live |
| 9 | [Post-release](#9-post-release) | Follow-up tasks done |

For fork testing and troubleshooting, see [RELEASE_TESTING.md](./RELEASE_TESTING.md).

---

## 0. One-time setup

Complete once before your first release as a maintainer.

- [Write](https://docs.github.com/en/organizations/managing-access-to-your-organizations-repositories/repository-permission-levels-for-an-organization#permission-levels-for-repositories-owned-by-an-organization)
  permission for the Katib repository.

- GitHub **`release` environment** with required reviewers (gates PyPI and GitHub Release jobs).

- [PyPI trusted publishing](https://docs.pypi.org/trusted-publishers/) for `kubeflow-katib` and `kubeflow_katib_api`
  (workflow: `release.yaml`, owner: `kubeflow`, repo: `katib`).

- Repository secrets:

  | Secret | Description |
  | --- | --- |
  | `DOCKERHUB_USERNAME` | DockerHub username for `kubeflowkatib` |
  | `DOCKERHUB_TOKEN` | DockerHub access token |

- Optional: [GitHub token](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token)
  and `git-cliff` for auto-generated changelogs via `make release`.

### Versioning and branches

Katib follows [Semantic Versioning](https://semver.org/) and Python [PEP 440](https://peps.python.org/pep-0440/) for SDK packages.

| Artifact | Format | Example |
| --- | --- | --- |
| Git tag | `vX.Y.Z` or `vX.Y.Z-rc.N` | `v0.19.1`, `v0.19.0-rc.0` |
| Python SDK / API | `X.Y.Z` or `X.Y.ZrcN` | `0.19.1`, `0.19.0rc0` |
| Release branch | `release-X.Y` | `release-0.19` |

- Latest minor release: prepare on `master`, merge PR → CI creates/updates `release-X.Y`.
- Patch on an older minor line: cherry-pick to `release-X.Y`, prepare there, open PR to that branch.

---

## 1. Prepare locally

From the repository root:

```sh
make release VERSION=<X.Y.Z>
# e.g. make release VERSION=0.19.1
```

This updates:

- `sdk/python/v1beta1/setup.py` → `version="X.Y.Z"`
- `hack/python-api/gen-api.sh` and `api/python_api/kubeflow_katib_api/__init__.py`
- Manifest image tags → `vX.Y.Z`
- `CHANGELOG.md` (stable releases only, when `git-cliff` is installed)

Review the diff:

```sh
git diff
git diff --stat
```

Nothing is pushed or published at this stage.

---

## 2. Validate locally

Run the local dry-run validator (mirrors the CI `dry_run: true` prepare + build jobs):

```sh
make test-release
```

Options:

```sh
./scripts/v1beta1/test-release.sh --skip-remote   # offline
./scripts/v1beta1/test-release.sh --skip-build    # metadata only
```

Fix any failures before continuing. See [RELEASE_TESTING.md](./RELEASE_TESTING.md) for details.

---

## 3. Pre-flight checklist

Complete before opening or merging the release PR.

**Version and artifacts**

- [ ] Version follows semver (`X.Y.Z` / `X.Y.ZrcN` Python; `vX.Y.Z` / `vX.Y.Z-rc.N` git tag)
- [ ] `setup.py`, `gen-api.sh`, and `kubeflow_katib_api/__init__.py` all match
- [ ] Manifest `newTag:` values match `vX.Y.Z` (not `latest`)
- [ ] Git tag does not already exist on [GitHub tags](https://github.com/kubeflow/katib/tags)

**Changelog and commits**

- [ ] Stable release: `# [vX.Y.Z] (YYYY-MM-DD)` in `CHANGELOG.md`
- [ ] RC release: changelog optional (GitHub Release uses auto-generated notes)
- [ ] Required fixes cherry-picked to target branch (`master` or `release-X.Y`)

**CI and approvals**

- [ ] Local dry run passed (`make test-release`)
- [ ] A maintainer is available to approve PyPI and GitHub Release steps

**Post-release planning**

- [ ] Announcement planned for minor/major releases (Slack / mailing list)
- [ ] Follow-up PR to `master` planned if releasing from a `release-X.Y` patch branch

---

## 4. Open a PR

Commit your changes and open a pull request:

- **Latest minor series** → PR to `master`
- **Older patch** (e.g. `0.18.1` while master is `0.19.x`) → PR to `release-0.18`

Wait for [Check Release](https://github.com/kubeflow/katib/actions/workflows/check-release.yaml) to pass.
It validates version consistency, tag uniqueness, and manifest tags on PRs that touch release files.

---

## 5. CI dry run (optional)

Recommended before merge, especially for first-time release automation changes.

1. Go to [Actions → Release](https://github.com/kubeflow/katib/actions/workflows/release.yaml)
2. **Run workflow** on your PR branch
3. Leave **`dry_run` enabled** (default)

| Job | Dry run behavior |
| --- | --- |
| Prepare | Validates version; prints branch/tag plan; **does not push** |
| Build | Verifies versions, changelog, builds packages, `twine check` |
| Dry run summary | Pass/fail on the workflow run page |
| Create tag / Images / PyPI / GitHub Release | **Skipped** |

---

## 6. Merge and automate

Merge the release PR. A push to `master` or `release-*` that changes `setup.py` triggers the
[Release workflow](https://github.com/kubeflow/katib/actions/workflows/release.yaml), which:

1. **Prepare** — creates or updates `release-X.Y` (cherry-picks from `master` if needed)
2. **Build** — validates versions, builds Python packages, uploads artifacts
3. **Tag** — creates and pushes `vX.Y.Z`
4. **Publish images** — multi-arch images to GHCR and DockerHub

Confirm the release branch and tag appear on GitHub.

**Alternative:** Re-run the Release workflow manually with **`dry_run: false`** on the release branch
(only after checklist + dry run pass).

> **Warning:** `dry_run: false` pushes branches, tags, and images immediately.

---

## 7. Approve publishing

Publishing steps wait in the GitHub **`release`** environment for maintainer approval.

1. [GitHub Actions](https://github.com/kubeflow/katib/actions) → **Release** workflow run → Approve **Publish to PyPI**
2. After PyPI succeeds → Approve **Create GitHub Release**

---

## 8. Verify release

- [ ] Images on [GHCR](https://github.com/kubeflow/katib/pkgs/container/katib) and [DockerHub](https://hub.docker.com/u/kubeflowkatib)
- [ ] Packages on [PyPI kubeflow-katib](https://pypi.org/project/kubeflow-katib/) and [kubeflow-katib-api](https://pypi.org/project/kubeflow-katib-api/)
- [ ] Release on [GitHub Releases](https://github.com/kubeflow/katib/releases)
- [ ] Smoke test: `pip install kubeflow-katib==X.Y.Z`

---

## 9. Post-release

- Submit a PR to bump the SDK version on `master` if the release was cut from a `release-X.Y` patch branch.
- Announce minor/major releases on community channels if applicable.

If you did not use `git-cliff`, update `CHANGELOG.md` manually:

```sh
python docs/release/changelog.py --token=<github-token> --range=<previous-release>..<current-release>
```

---

## Appendix

### Manual release (legacy)

Not recommended — builds images locally without multi-arch by default.

```sh
make release-manual BRANCH=release-X.Y TAG=vX.Y.Z
```

See [CONTRIBUTING.md](./../../CONTRIBUTING.md#requirements) for local tooling.

### Local and fork testing

See [RELEASE_TESTING.md](./RELEASE_TESTING.md) for the test script, fork workflow, and troubleshooting.
