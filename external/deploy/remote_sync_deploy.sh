#!/usr/bin/env bash
set -euo pipefail

BRANCH="${1:-main}"
DEPLOY_APP_DIR="${DEPLOY_APP_DIR:-$HOME/openclaw}"
DEPLOY_RUN_INSTALL="${DEPLOY_RUN_INSTALL:-auto}"
DEPLOY_RUN_BUILD="${DEPLOY_RUN_BUILD:-true}"
DEPLOY_RESTART_CMD="${DEPLOY_RESTART_CMD:-openclaw gateway restart}"

cd "$DEPLOY_APP_DIR"

git fetch origin --prune

if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  git checkout "$BRANCH"
else
  git checkout -b "$BRANCH" "origin/$BRANCH"
fi

PREV_HEAD="$(git rev-parse HEAD)"
git pull --ff-only origin "$BRANCH"
CURR_HEAD="$(git rev-parse HEAD)"

if [[ "$DEPLOY_RUN_INSTALL" == "true" ]]; then
  pnpm install --frozen-lockfile
elif [[ "$DEPLOY_RUN_INSTALL" == "auto" ]]; then
  if ! git diff --quiet "${PREV_HEAD}" "${CURR_HEAD}" -- pnpm-lock.yaml package.json; then
    pnpm install --frozen-lockfile
  fi
fi

if [[ "$DEPLOY_RUN_BUILD" == "true" ]]; then
  pnpm build
fi

eval "$DEPLOY_RESTART_CMD"
pnpm openclaw gateway status
