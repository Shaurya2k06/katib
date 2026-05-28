#!/usr/bin/env bash

# Copyright 2022 The Kubeflow Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Prepare a release commit for version X.Y.Z.
# Updates VERSION, Python package versions, changelog, and runs make generate.
#
# Manifest image tags are NOT updated here. Those are pinned on the release
# branch by .github/workflows/release.yaml so master keeps newTag: latest.

set -o errexit
set -o nounset
set -o pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <version>"
  echo "You must follow this format: X.Y.Z or X.Y.Z-rc.N"
  exit 1
fi

NEW_VERSION=$(echo "$1" | tr -d '\n' | tr -d ' ')

if [[ ! "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-rc\.[0-9]+)?$ ]]; then
  echo "Version format is invalid. Use: X.Y.Z or X.Y.Z-rc.N"
  exit 1
fi

TAG="v${NEW_VERSION}"

MAJOR_VERSION="${NEW_VERSION%%.*}"
MINOR_VERSION="${NEW_VERSION#*.}"
MINOR_VERSION="${MINOR_VERSION%%.*}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION_FILE="${REPO_ROOT}/VERSION"
SETUP_PY="${REPO_ROOT}/sdk/python/v1beta1/setup.py"
GEN_API_SH="${REPO_ROOT}/hack/python-api/gen-api.sh"
MODELS_INIT="${REPO_ROOT}/api/python_api/kubeflow_katib_api/__init__.py"

git fetch --tags
if git tag --list | grep -q "^${TAG}$"; then
  echo "Tag: ${TAG} already exists. Release can't be published."
  exit 1
fi

if [[ "${NEW_VERSION}" == *"-rc."* ]]; then
  PYTHON_VERSION=$(echo "${NEW_VERSION}" | sed 's/-rc\.\([0-9]*\)/rc\1/')
else
  PYTHON_VERSION="${NEW_VERSION}"
fi

echo -e "\nPreparing release commit for ${TAG}\n"

printf '%s' "${TAG}" > "${VERSION_FILE}"
echo "Updated VERSION file to ${TAG}"

python3 - "${SETUP_PY}" "${GEN_API_SH}" "${MODELS_INIT}" "${PYTHON_VERSION}" <<'PYTHON'
import pathlib
import re
import sys

setup_path, gen_api_path, models_path, python_version = sys.argv[1:5]

setup = pathlib.Path(setup_path)
setup.write_text(
    re.sub(r'version="[^"]+"', f'version="{python_version}"', setup.read_text(), count=1)
)

gen_api = pathlib.Path(gen_api_path)
gen_api.write_text(
    re.sub(r'API_VERSION="[^"]+"', f'API_VERSION="{python_version}"', gen_api.read_text(), count=1)
)

models = pathlib.Path(models_path)
models.write_text(
    re.sub(r'__version__ = "[^"]+"', f'__version__ = "{python_version}"', models.read_text(), count=1)
)
PYTHON
echo "Updated Python package versions to ${PYTHON_VERSION}"

CHANGELOG_DIR="${REPO_ROOT}/CHANGELOG"
CHANGELOG_PATH="${CHANGELOG_DIR}/CHANGELOG-${MAJOR_VERSION}.${MINOR_VERSION}.md"
echo "Generating changelog for ${TAG}"
ABSOLUTE_REPO_ROOT="$(cd "${REPO_ROOT}" && pwd)"
if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "WARNING: GITHUB_TOKEN not set. Set it to avoid GitHub API rate limits."
  echo "Export GITHUB_TOKEN before running this script: export GITHUB_TOKEN=your_token"
fi

TEMP_FILE=$(mktemp)
docker run --rm -u "$(id -u):$(id -g)" -v "${ABSOLUTE_REPO_ROOT}:/app" \
  -e "GITHUB_TOKEN=${GITHUB_TOKEN:-}" -w /app \
  "ghcr.io/orhun/git-cliff/git-cliff:latest" --unreleased --tag "${TAG}" -o - > "${TEMP_FILE}"

if [ ! -s "${TEMP_FILE}" ]; then
  echo "git-cliff produced empty changelog" >&2
  rm -f "${TEMP_FILE}"
  exit 1
fi

mkdir -p "${CHANGELOG_DIR}"

if [ -f "${CHANGELOG_PATH}" ]; then
  TMP_COMBINED=$(mktemp)
  cat "${TEMP_FILE}" "${CHANGELOG_PATH}" > "${TMP_COMBINED}"
  mv "${TMP_COMBINED}" "${CHANGELOG_PATH}"
else
  { echo "# Changelog"; echo ""; cat "${TEMP_FILE}"; } > "${CHANGELOG_PATH}"
fi
rm -f "${TEMP_FILE}"
echo "Changelog generated at ${CHANGELOG_PATH}"

echo "Running make generate"
make -C "${REPO_ROOT}" generate
echo "Completed make generate"

git add "${VERSION_FILE}" "${SETUP_PY}" "${GEN_API_SH}" "${MODELS_INIT}" "${CHANGELOG_PATH}"
git add -u
git commit -s -m "Release ${TAG}"

echo -e "\nRelease commit for ${TAG} created successfully."
echo "Next steps:"
echo "  1. Push your branch and open a PR to 'master'"
echo "  2. Once merged, GitHub Actions will create the release branch, tag, and release"
