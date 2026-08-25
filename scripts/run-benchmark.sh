#!/usr/bin/env bash
# Runs one benchmark cell: build/start the server container, run the k6
# client container against it, collect results, tear both down.
#
# This is a deliberate stepping stone (see docs/design.md, "Orchestration
# (decided)"): the target deployment is Kubernetes or AWS ECS. Keeping the
# steps below explicit and in one place means porting later is a
# re-implementation of these same steps as a k8s Job / ECS RunTask, not a
# redesign.
#
# Usage:
#   scripts/run-benchmark.sh <language> <protocol> <format>
#
# Example (once the Java http2-json image and its k6 script exist):
#   scripts/run-benchmark.sh java http2 json
#
# Status: skeleton. No benchmarks/<lang>/<protocol>-<format>/Dockerfile or
# client/<protocol>/*.js k6 script exists yet, so this will fail at the
# "build server image" step until those land. The flow below is the
# intended contract for when they do.

set -euo pipefail

usage() {
  echo "Usage: $0 <language> <protocol> <format>" >&2
  echo "  language: java | go | rust | python" >&2
  echo "  protocol: http2 | http3 | ws" >&2
  echo "  format:   json | xml | protobuf" >&2
  exit 1
}

[ $# -eq 3 ] || usage
LANGUAGE=$1
PROTOCOL=$2
FORMAT=$3

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMBO_DIR="${REPO_ROOT}/benchmarks/${LANGUAGE}/${PROTOCOL}-${FORMAT}"
CLIENT_SCRIPT="${REPO_ROOT}/benchmarks/${PROTOCOL}/client.js"
RUN_ID="${LANGUAGE}-${PROTOCOL}-${FORMAT}-$(date -u +%Y%m%d-%H%M)"
RUN_DIR="${REPO_ROOT}/results/${RUN_ID}"

SERVER_IMAGE="jenkins-ssm/${LANGUAGE}-${PROTOCOL}-${FORMAT}:local"
SERVER_CONTAINER="jenkins-ssm-server-${RUN_ID}"
NETWORK="jenkins-ssm-${RUN_ID}"

# TODO(design): these limits should come from a shared config once more
# than one combination is running, so every language/protocol/format cell
# is given the same resource envelope (see docs/design.md, Deployment).
SERVER_CPUS="2"
SERVER_MEMORY="1g"

cleanup() {
  docker rm -f "${SERVER_CONTAINER}" >/dev/null 2>&1 || true
  docker network rm "${NETWORK}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

if [ ! -d "${COMBO_DIR}" ]; then
  echo "error: no benchmark implementation at ${COMBO_DIR}" >&2
  exit 1
fi
if [ ! -f "${COMBO_DIR}/Dockerfile" ]; then
  echo "error: ${COMBO_DIR}/Dockerfile not found (not implemented yet)" >&2
  exit 1
fi
if [ ! -f "${CLIENT_SCRIPT}" ]; then
  echo "error: ${CLIENT_SCRIPT} not found (k6 client script not implemented yet)" >&2
  exit 1
fi

mkdir -p "${RUN_DIR}/raw"

echo "==> building server image ${SERVER_IMAGE}"
docker build -t "${SERVER_IMAGE}" "${COMBO_DIR}"

echo "==> creating isolated network ${NETWORK}"
docker network create "${NETWORK}" >/dev/null

echo "==> starting server container ${SERVER_CONTAINER}"
docker run -d \
  --name "${SERVER_CONTAINER}" \
  --network "${NETWORK}" \
  --cpus "${SERVER_CPUS}" \
  --memory "${SERVER_MEMORY}" \
  "${SERVER_IMAGE}"

# TODO(design): replace with a real readiness probe once the server apps
# expose one; sleeping is a placeholder.
sleep 2

echo "==> recording environment"
cat > "${RUN_DIR}/env.json" <<EOF
{
  "language": "${LANGUAGE}",
  "protocol": "${PROTOCOL}",
  "format": "${FORMAT}",
  "server_image": "${SERVER_IMAGE}",
  "server_cpus": "${SERVER_CPUS}",
  "server_memory": "${SERVER_MEMORY}",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo "==> running k6 client against server"
docker run --rm \
  --network "${NETWORK}" \
  -e SERVER_HOST="${SERVER_CONTAINER}" \
  -v "${REPO_ROOT}/benchmarks/${PROTOCOL}:/scripts:ro" \
  -v "${RUN_DIR}/raw:/out" \
  grafana/k6 run --summary-export=/out/summary.json /scripts/client.js

cp "${RUN_DIR}/raw/summary.json" "${RUN_DIR}/summary.json"

echo "==> results written to ${RUN_DIR}"
