#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${ROOT_DIR}/app"
REPORT_DIR="${ROOT_DIR}/reports"

REGISTRY="${REGISTRY:-192.168.56.10:5000}"
IMAGE_NAME="${IMAGE_NAME:-my-app}"
DOCKERFILE="${1:-Dockerfile}"
TAG="${2:-latest}"
SEVERITY="${SEVERITY:-CRITICAL,HIGH}"
IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"

if [[ -z "${PYTHON:-}" ]]; then
  if [[ -x "${HOME}/.venvs/devsecops-lab/bin/python" ]]; then
    PYTHON="${HOME}/.venvs/devsecops-lab/bin/python"
  elif command -v python >/dev/null 2>&1; then
    PYTHON="python"
  else
    PYTHON="python3"
  fi
fi

mkdir -p "${REPORT_DIR}"
step() { printf '\n==> %s\n' "$*"; }
fail() { printf '\nPIPELINE FAILED: %s\n' "$*" >&2; exit 1; }

step "1/5 Unit tests"
(cd "${APP_DIR}" && "${PYTHON}" -m pytest -q) \
  || fail "unit tests failed"

step "2/5 Dockerfile security check"
trivy config --exit-code 1 --severity "${SEVERITY}" \
  "${APP_DIR}/${DOCKERFILE}" || fail "unsafe Dockerfile"

step "3/5 Build ${IMAGE}"
docker build --pull -t "${IMAGE}" -f "${APP_DIR}/${DOCKERFILE}" \
  "${APP_DIR}" || fail "image build failed"

step "4/5 Image vulnerability scan"
trivy image --timeout 10m --image-src docker --scanners vuln \
  --format json -o "${REPORT_DIR}/${IMAGE_NAME}-${TAG}.json" \
  "${IMAGE}" || fail "could not save vulnerability report"

trivy image --timeout 10m --image-src docker --scanners vuln \
  --exit-code 1 --ignore-unfixed --severity "${SEVERITY}" \
  "${IMAGE}" || fail "fixable vulnerabilities found"

step "5/5 Push ${IMAGE}"
docker push "${IMAGE}" || fail "image push failed"

printf '\nPIPELINE OK: %s published\n' "${IMAGE}"

