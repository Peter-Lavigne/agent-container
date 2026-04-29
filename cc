#!/usr/bin/env bash
set -euo pipefail

NAME="${1:?Usage: cc <session-name>}"
CONTAINER="agent-container"

if [ -n "${AGENT_CONTAINER:-}" ]; then
    exec claude --dangerously-skip-permissions --worktree "$NAME" --name "$NAME"
fi

if ! docker container inspect "$CONTAINER" >/dev/null 2>&1; then
    echo "Container not found. Run ./run first to create it." >&2
    exit 1
elif [ "$(docker container inspect -f '{{.State.Running}}' "$CONTAINER")" != "true" ]; then
    docker start "$CONTAINER" >/dev/null
fi

exec docker exec -it -w "$(pwd)" "$CONTAINER" \
    bash -lc 'claude --dangerously-skip-permissions --worktree "$1" --name "$1"' _ "$NAME"
