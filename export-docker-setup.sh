#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
DEFAULT_OUT="$ROOT_DIR/szybkafucha-docker-setup-$TIMESTAMP.tar.gz"
OUT_FILE="$DEFAULT_OUT"
INCLUDE_ENV=false
INCLUDE_IMAGES=false

usage() {
  cat <<'USAGE'
Usage:
  ./export-docker-setup.sh [output.tar.gz] [--with-env] [--with-images]

Options:
  --with-env     Include backend/.env and admin/.env (may contain secrets)
  --with-images  Include a docker image bundle for offline import
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --with-env)
      INCLUDE_ENV=true
      ;;
    --with-images)
      INCLUDE_IMAGES=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *.tar.gz)
      OUT_FILE="$arg"
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ "$OUT_FILE" != /* ]]; then
  OUT_FILE="$ROOT_DIR/$OUT_FILE"
fi

STAGING_DIR="$(mktemp -d)"
PAYLOAD_DIR="$STAGING_DIR/szybkafucha-docker-setup"
mkdir -p "$PAYLOAD_DIR"

cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

cp "$ROOT_DIR/docker-compose.yml" "$PAYLOAD_DIR/"
cp "$ROOT_DIR/backend/.env.example" "$PAYLOAD_DIR/backend.env.example"
cp "$ROOT_DIR/admin/.env.example" "$PAYLOAD_DIR/admin.env.example"

if [[ "$INCLUDE_ENV" == true ]]; then
  [[ -f "$ROOT_DIR/backend/.env" ]] && cp "$ROOT_DIR/backend/.env" "$PAYLOAD_DIR/backend.env"
  [[ -f "$ROOT_DIR/admin/.env" ]] && cp "$ROOT_DIR/admin/.env" "$PAYLOAD_DIR/admin.env"
fi

IMAGE_NOTE="No image bundle included. On target machine run: docker compose pull"
if [[ "$INCLUDE_IMAGES" == true ]]; then
  if ! command -v docker >/dev/null 2>&1; then
    echo "docker is required for --with-images" >&2
    exit 1
  fi

  IMAGE_TAR="$PAYLOAD_DIR/docker-images.tar"
  docker pull postgres:15-alpine >/dev/null
  docker pull redis:7-alpine >/dev/null
  docker pull dpage/pgadmin4:latest >/dev/null
  docker save -o "$IMAGE_TAR" postgres:15-alpine redis:7-alpine dpage/pgadmin4:latest
  IMAGE_NOTE="Image bundle included as docker-images.tar. On target machine run: docker load -i docker-images.tar"
fi

cat > "$PAYLOAD_DIR/IMPORT.md" <<IMPORT
# Docker Setup Import

1. Extract this archive on the target machine.
2. Copy \
   - docker-compose.yml to project root
   - backend.env.example to backend/.env.example
   - admin.env.example to admin/.env.example
3. Create env files from examples (or use backend.env/admin.env if included):
   - cp backend.env.example backend/.env
   - cp admin.env.example admin/.env
4. $IMAGE_NOTE
5. Start services:
   - docker compose up -d postgres redis pgadmin
IMPORT

mkdir -p "$(dirname "$OUT_FILE")"
tar -czf "$OUT_FILE" -C "$STAGING_DIR" szybkafucha-docker-setup

echo "Export file created: $OUT_FILE"
