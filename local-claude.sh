#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_BIN_DIR="$ROOT_DIR/.local/bin"
WRAPPER_PATH="$LOCAL_BIN_DIR/claude"
LOCAL_ENV_FILE="$ROOT_DIR/.env.claude.local"

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

bootstrap_deps() {
  if [ ! -d "$ROOT_DIR/node_modules" ]; then
    echo "Installing dependencies with npm..."
    if ! npm install --no-audit --no-fund; then
      echo "npm default registry failed, retrying with npmmirror..."
      npm install --registry=https://registry.npmmirror.com --no-audit --no-fund
    fi
  fi

  if [ ! -f "$ROOT_DIR/node_modules/@anthropic-ai/bedrock-sdk/package.json" ] \
    || [ ! -f "$ROOT_DIR/node_modules/@anthropic-ai/vertex-sdk/package.json" ] \
    || [ ! -f "$ROOT_DIR/node_modules/@anthropic-ai/foundry-sdk/package.json" ] \
    || [ ! -f "$ROOT_DIR/node_modules/@aws-sdk/client-bedrock/package.json" ]; then
    echo "Installing extra build-time provider dependencies (local only)..."
    if ! npm install --no-save --no-audit --no-fund \
      @anthropic-ai/bedrock-sdk \
      @anthropic-ai/vertex-sdk \
      @anthropic-ai/foundry-sdk \
      @aws-sdk/client-bedrock; then
      npm install --registry=https://registry.npmmirror.com --no-save --no-audit --no-fund \
        @anthropic-ai/bedrock-sdk \
        @anthropic-ai/vertex-sdk \
        @anthropic-ai/foundry-sdk \
        @aws-sdk/client-bedrock
    fi
  fi
}

build_cli() {
  if [ ! -f "$ROOT_DIR/cli.js" ]; then
    echo "cli.js not found, building..."
    (cd "$ROOT_DIR" && bun run build)
    return 0
  fi

  if find "$ROOT_DIR/src" -type f -newer "$ROOT_DIR/cli.js" | head -n 1 | grep -q .; then
    echo "Source changed, rebuilding cli.js..."
    (cd "$ROOT_DIR" && bun run build)
    return 0
  fi

  echo "cli.js is up to date."
}

ensure_local_env_file() {
  if [ ! -f "$LOCAL_ENV_FILE" ]; then
    cat >"$LOCAL_ENV_FILE" <<'EOF'
ANTHROPIC_API_KEY='ak_2Il66v1ql1HN7Bd32e7mg8J55tl33'
ANTHROPIC_BASE_URL='https://api.longcat.chat/anthropic'
ANTHROPIC_MODEL='LongCat-Flash-Thinking'
EOF
    echo "Created local env file: $LOCAL_ENV_FILE"
  fi
}

write_wrapper() {
  mkdir -p "$LOCAL_BIN_DIR"
  cat >"$WRAPPER_PATH" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
WRAPPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$WRAPPER_DIR/../.." && pwd)"
LOCAL_ENV_FILE="$ROOT_DIR/.env.claude.local"

if [ -f "$LOCAL_ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$LOCAL_ENV_FILE"
  set +a
fi

exec bun "$ROOT_DIR/cli.js" "$@"
EOF
  chmod +x "$WRAPPER_PATH"
}

activate_in_current_shell() {
  export PATH="$LOCAL_BIN_DIR:$PATH"
  hash -r 2>/dev/null || true
  echo "Local claude activated in current shell."
  echo "Try: claude --version"
}

main() {
  need_cmd npm
  need_cmd bun

  bootstrap_deps
  build_cli
  ensure_local_env_file
  write_wrapper

  if [ "${BASH_SOURCE[0]}" != "$0" ]; then
    activate_in_current_shell
    return 0
  fi

  echo
  echo "Bootstrap complete. Starting a subshell with local claude first in PATH."
  echo "This does not modify your global claude installation."
  echo "Exit this subshell to return to your original shell."
  env PATH="$LOCAL_BIN_DIR:$PATH" "${SHELL:-/bin/zsh}" -i
}

main "$@"
