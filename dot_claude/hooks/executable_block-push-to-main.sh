#!/usr/bin/env bash
# PreToolUse フック: main/master への git push を弾く。
# 現在のブランチ名だけでなく、コマンド引数・追跡先も検査する。
#
# git push かどうかの判定は、コマンド文字列全体に対する単純な部分文字列マッチではなく、
# サブコマンド単位で先頭トークン(argv0)を見て行う。これにより
#   - alias g="git" 経由の `g push` のような呼び出しも正しく検知する
#   - "git push" という文字列がたまたまコマンド中に含まれるだけ（grepパターン等）の
#     誤検知を避ける
# ことができる。
set -euo pipefail

input=$(cat)
command=$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")

[ -z "$command" ] && exit 0

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

# --- git / git push 相当のシェルエイリアスを動的に解決する ---------------------
# git_aliases: それ自体が "git" と等価なエイリアス（例: alias g="git"）
# push_aliases: "git push ..." に直結するエイリアス（例: alias gp="git push"）
git_aliases=("git")
push_aliases=()

for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.zprofile" "$HOME/.bash_profile"; do
  [ -f "$rc" ] || continue
  while IFS= read -r line; do
    name=$(printf '%s' "$line" | sed -nE "s/^alias[[:space:]]+([A-Za-z0-9_.-]+)=.*/\1/p")
    [ -z "$name" ] && continue
    value=$(printf '%s' "$line" | sed -nE "s/^alias[[:space:]]+[A-Za-z0-9_.-]+=['\"]?([^'\"]*)['\"]?[[:space:]]*\$/\1/p")
    [ -z "$value" ] && continue

    if [ "$value" = "git" ]; then
      git_aliases+=("$name")
    elif printf '%s' "$value" | grep -qE '^git[[:space:]]+push(\s|$)'; then
      push_aliases+=("$name")
    fi
  done < <(grep -E '^[[:space:]]*alias[[:space:]]' "$rc" 2>/dev/null; echo)
done

is_known_git_alias() {
  local token="$1" a
  for a in "${git_aliases[@]}"; do
    [ "$token" = "$a" ] && return 0
  done
  return 1
}

is_known_push_alias() {
  local token="$1" a
  [ "${#push_aliases[@]}" -eq 0 ] && return 1
  for a in "${push_aliases[@]}"; do
    [ "$token" = "$a" ] && return 0
  done
  return 1
}

# --- コマンドをサブコマンドに分割し、実際に git push を呼んでいるものを集める -------
# ; && || | 改行 を区切りとして雑にサブコマンドへ分割する（完全なシェル構文解析ではない）
push_subcommands=()
while IFS= read -r sub; do
  # 先頭の空白を削る
  sub_trimmed="${sub#"${sub%%[![:space:]]*}"}"
  [ -z "$sub_trimmed" ] && continue

  # 先頭の環境変数代入 (VAR=val ...) を読み飛ばす
  while printf '%s' "$sub_trimmed" | grep -qE '^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]'; do
    sub_trimmed=$(printf '%s' "$sub_trimmed" | sed -E 's/^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+//')
  done

  argv0=$(printf '%s' "$sub_trimmed" | awk '{print $1}')
  [ -z "$argv0" ] && continue

  if is_known_push_alias "$argv0"; then
    push_subcommands+=("$sub_trimmed")
    continue
  fi

  if is_known_git_alias "$argv0"; then
    second=$(printf '%s' "$sub_trimmed" | awk '{print $2}')
    if [ "$second" = "push" ]; then
      push_subcommands+=("$sub_trimmed")
    fi
  fi
done < <(printf '%s\n' "$command" | sed -E 's/(&&|\|\||;|\|)/\n/g')

# git push に該当するサブコマンドが一つもなければ何もしない
[ "${#push_subcommands[@]}" -eq 0 ] && exit 0

# --- 該当するサブコマンドごとに main/master への push かどうかを検査する -----------

# 1. 現在のブランチが main/master
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
  deny
fi

# 2. push 対象サブコマンドの引数に main/master が含まれる（例: git push origin main）
for sub in "${push_subcommands[@]}"; do
  if printf '%s' "$sub" | grep -qE '(^|\s|:)(main|master)(\s|$)'; then
    deny
  fi
done

# 3. push.default=upstream などで追跡先が origin/main になっている
upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo "")
if [ "$upstream" = "origin/main" ] || [ "$upstream" = "origin/master" ]; then
  deny
fi
