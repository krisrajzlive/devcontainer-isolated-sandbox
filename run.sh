#!/usr/bin/env sh
# One command: build, start, seed, verify isolation, run the workload, tear down.
# Usage: ./run.sh [--keep | --shell | --down]
set -eu
cd "$(dirname "$0")"
c="docker compose -f .devcontainer/docker-compose.yml"

[ "${1:-}" = "--down" ] && { $c down -v; exit 0; }
docker info >/dev/null 2>&1 || { echo "Docker is not running." >&2; exit 1; }

keep=0; [ "${1:-}" = "--keep" ] || [ "${1:-}" = "--shell" ] && keep=1
cleanup() { [ "$keep" = 1 ] && echo "Sandbox left running. Remove with: ./run.sh --down" || $c down -v; }
trap cleanup EXIT

$c up -d --build
$c exec -T workspace sh -c "cp -rn /opt/seed/. /workspace/"
$c exec -T workspace python scripts/verify_isolation.py
$c exec -T workspace python app/file_ops.py
[ "${1:-}" = "--shell" ] && $c exec workspace bash
exit 0
