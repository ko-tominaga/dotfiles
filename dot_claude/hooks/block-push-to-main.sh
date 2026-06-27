#!/usr/bin/env bash
# PreToolUse フック: 現在のブランチが main のときの git push を弾く。
# `git push` 系コマンドのときだけ呼ばれる想定（settings.json の "if" でフィルタ）。
set -euo pipefail

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

if [ "${ALLOW_PUSH_TO_MAIN:-}" = "1" ]; then
  exit 0
fi

if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
  cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "main / master ブランチへの直接pushは禁止です。バイパスするには環境変数 ALLOW_PUSH_TO_MAIN=1 を設定してClaudeを起動してください。"
  }
}
JSON
fi
