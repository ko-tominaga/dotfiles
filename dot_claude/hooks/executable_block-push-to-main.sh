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
#    ただし、これは「明示的なref/ブランチ指定がない裸のpush」(push.defaultに委ねる場合)
#    にのみ適用する。`git push origin foo:foo` のように明示的に非main/masterへ
#    push先を指定している場合は誤検知になるため対象外にする
#    （main/masterを明示指定した場合は check 2 で既に弾かれている）。
#    例:
#      `git push`                -> 明示refなし(危険なら検査対象)
#      `git push origin`         -> 同上
#      `git push -u origin foo`  -> foo が明示refなので対象外
#      `git push origin foo:foo` -> 同上
has_explicit_ref=$(echo "$command" | python3 -c "
import re, shlex, sys

command = sys.stdin.read()
match = re.search(r'git\s+push(.*)', command)
rest = match.group(1) if match else ''
try:
    tokens = shlex.split(rest)
except ValueError:
    tokens = rest.split()

remote_seen = False
for token in tokens:
    if token.startswith('-'):
        continue
    if not remote_seen:
        # 最初の非フラグトークンはリモート名とみなす
        remote_seen = True
        continue
    # リモート名の次に非フラグトークンがあれば明示的なref/refspec指定とみなす
    print('yes')
    break
" 2>/dev/null || echo "")

if [ -z "$has_explicit_ref" ]; then
  upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo "")
  if [ "$upstream" = "origin/main" ] || [ "$upstream" = "origin/master" ]; then
    deny
  fi
fi
