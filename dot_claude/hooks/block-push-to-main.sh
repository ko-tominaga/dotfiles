#!/usr/bin/env bash
# PreToolUse フック: main/master への git push を弾く。
# 現在のブランチ名だけでなく、コマンド引数・追跡先も検査する。
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

deny() {
  cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "main / master ブランチへの直接pushは禁止です。バイパスするには環境変数 ALLOW_PUSH_TO_MAIN=1 を設定してClaudeを起動してください。"
  }
}
JSON
  exit 0
}

# 1. 現在のブランチが main/master
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
  deny
fi

# 2. コマンド引数に main/master が含まれる（例: git push origin main）
if echo "$command" | grep -qE '(^|\s|:)(main|master)(\s|$)'; then
  deny
fi

# 3. push.default=upstream などで追跡先が origin/main になっている
upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo "")
if [ "$upstream" = "origin/main" ] || [ "$upstream" = "origin/master" ]; then
  deny
fi
