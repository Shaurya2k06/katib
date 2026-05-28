#!/usr/bin/env bash

# Copyright 2022 The Kubeflow Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Local dry-run validator for the Katib release workflow.
# Mirrors .github/workflows/release.yaml prepare + build jobs (dry_run: true).
#
# Usage (from repository root):
#   ./scripts/v1beta1/test-release.sh
#   ./scripts/v1beta1/test-release.sh --skip-remote
#   make test-release
#
# Typical flow:
#   make release VERSION=0.19.1
#   make test-release

set -o errexit
set -o pipefail
set -o nounset

SCRIPT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "${SCRIPT_ROOT}"

REMOTE="${RELEASE_REMOTE:-origin}"
SKIP_REMOTE=false
SKIP_BUILD=false
PYTHON="${PYTHON:-python3}"

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Run local pre-flight checks for the Katib release workflow (CI dry-run equivalent).

Options:
  --skip-remote   Skip remote tag/branch checks (offline or fork testing)
  --skip-build    Skip Python package build and twine check
  -h, --help      Show this help message

Environment:
  RELEASE_REMOTE  Git remote to inspect (default: origin)
  PYTHON          Python interpreter (default: python3)

Examples:
  make release VERSION=0.19.1 && make test-release
  ./scripts/v1beta1/test-release.sh --skip-remote
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-remote)
      SKIP_REMOTE=true
      shift
      ;;
    --skip-build)
      SKIP_BUILD=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

pass() {
  echo "PASS: $*"
}

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

section() {
  echo
  echo "== $* =="
}

read_version_from_setup() {
  grep -E 'version="[^"]+"' sdk/python/v1beta1/setup.py | head -1 | sed -E 's/.*version="([^"]+)".*/\1/'
}

version_to_tag() {
  local version="$1"
  if [[ "$version" =~ rc[0-9]+$ ]]; then
    echo "v${version/rc/-rc.}"
  else
    echo "v${version}"
  fi
}

section "Parse release metadata"
VERSION=$(read_version_from_setup)
[[ -n "$VERSION" ]] || fail "Could not read version from sdk/python/v1beta1/setup.py"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(rc[0-9]+)?$ ]]; then
  fail "Invalid version format in setup.py: ${VERSION}"
fi

TAG=$(version_to_tag "$VERSION")
MAJOR_MINOR=$(echo "$VERSION" | sed -E 's/(rc[0-9]+)$//' | cut -d. -f1,2)
BRANCH="release-${MAJOR_MINOR}"
IS_PRERELEASE=false
if [[ "$VERSION" =~ rc[0-9]+$ ]]; then
  IS_PRERELEASE=true
fi

echo "Version:       ${VERSION}"
echo "Tag:           ${TAG}"
echo "Release branch: ${BRANCH}"
echo "Pre-release:   ${IS_PRERELEASE}"
echo "Git ref:       $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)@$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
pass "Parsed release metadata"

section "Verify version consistency"
SDK_VERSION=$(read_version_from_setup)
API_VERSION=$(grep 'API_VERSION=' hack/python-api/gen-api.sh | head -1 | sed -E 's/.*API_VERSION="([^"]+)".*/\1/')
MODELS_VERSION=$(grep '__version__' api/python_api/kubeflow_katib_api/__init__.py | sed -E 's/.*"([^"]+)".*/\1/')

echo "SDK:    ${SDK_VERSION}"
echo "API:    ${API_VERSION}"
echo "Models: ${MODELS_VERSION}"

if [[ "${SDK_VERSION}" != "${VERSION}" || "${API_VERSION}" != "${VERSION}" || "${MODELS_VERSION}" != "${VERSION}" ]]; then
  fail "Version mismatch across SDK, gen-api.sh, and kubeflow_katib_api/__init__.py"
fi
pass "Python package versions are consistent"

section "Manifest image tags"
echo "Manifests on master use newTag: latest; CI pins tags on the release branch during Prepare."
echo "Skipping local manifest tag check (aligned with automated release workflow)."
pass "Manifest pinning deferred to CI"

section "Verify changelog"
if [[ "${IS_PRERELEASE}" == "true" ]]; then
  echo "Skipping changelog check for pre-release ${VERSION}"
else
  [[ -f CHANGELOG.md ]] || fail "CHANGELOG.md not found"
  if ! grep -q "^# \\[${TAG}\\]" CHANGELOG.md; then
    fail "Missing CHANGELOG.md section header: # [${TAG}]"
  fi
  pass "Changelog section found for ${TAG}"
fi

if [[ "${SKIP_REMOTE}" == "false" ]]; then
  section "Verify remote tag and branch"
  if ! git remote get-url "${REMOTE}" >/dev/null 2>&1; then
    fail "Git remote '${REMOTE}' not found (use --skip-remote to skip)"
  fi

  if git ls-remote --tags "${REMOTE}" "$TAG" | grep -q "refs/tags/${TAG}$"; then
    fail "Tag ${TAG} already exists on ${REMOTE}"
  fi
  pass "Tag ${TAG} is available on ${REMOTE}"

  if git ls-remote --heads "${REMOTE}" "$BRANCH" | grep -q "$BRANCH"; then
    echo "Release branch ${BRANCH} exists on ${REMOTE}"
    echo "CI would cherry-pick $(git rev-parse HEAD) onto ${BRANCH} when triggered from master"
  else
    echo "Release branch ${BRANCH} does not exist on ${REMOTE}"
    echo "CI would create ${BRANCH} from $(git rev-parse HEAD) when triggered from master"
  fi
  pass "Remote branch inspection complete"
else
  echo "Skipping remote checks (--skip-remote)"
fi

if [[ "${SKIP_BUILD}" == "false" ]]; then
  section "Build and validate Python packages"
  if ! command -v "${PYTHON}" >/dev/null 2>&1; then
    fail "Python interpreter not found: ${PYTHON}"
  fi

  "${PYTHON}" -m pip install --quiet build twine

  rm -rf sdk/python/v1beta1/dist sdk/python/v1beta1/build
  rm -rf api/python_api/dist api/python_api/build

  (cd sdk/python/v1beta1 && "${PYTHON}" -m build)
  (cd api/python_api && "${PYTHON}" -m build)

  twine check sdk/python/v1beta1/dist/*
  twine check api/python_api/dist/*
  pass "Built packages and passed twine check"

  echo
  echo "Built artifacts:"
  ls -la sdk/python/v1beta1/dist/
  ls -la api/python_api/dist/
else
  echo "Skipping package build (--skip-build)"
fi

section "Dry run summary"
cat <<EOF

Katib release local dry run PASSED

  Version:        ${VERSION}
  Tag:            ${TAG}
  Release branch: ${BRANCH}
  Pre-release:    ${IS_PRERELEASE}

No branches, tags, images, or PyPI packages were published.

Next steps:
  1. Open a PR with these changes (if not already done)
  2. Confirm Check Release passes on the PR
  3. Run CI dry run: Actions -> Release -> Run workflow (dry_run: true)
  4. Merge PR or re-run workflow with dry_run: false for a real release

See RELEASE.md and docs/release/RELEASE_TESTING.md for fork and CI testing details.
EOF
