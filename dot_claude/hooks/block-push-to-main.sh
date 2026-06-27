#!/usr/bin/env bash
# PreToolUse フック: 現在のブランチが main のときの git push を弾く。
set -euo pipefail

input=$(cat)
command=$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")

# git push 系コマンドでなければスキップ
if ! echo "$command" | grep -qE 'git push'; then
  exit 0
fi

if [ "${ALLOW_PUSH_TO_MAIN:-}" = "1" ]; then
  exit 0
fi

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

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
