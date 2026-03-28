#!/bin/sh
input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# ユーザー名とホスト名
user=$(whoami)
host=$(hostname -s)

# ディレクトリ表示（ホームディレクトリを ~ に短縮）
home="$HOME"
display_dir="${cwd/#$home/~}"

# git ブランチ情報（オプショナル）
git_info=""
if git -C "$cwd" rev-parse --is-inside-work-tree --no-optional-locks 2>/dev/null | grep -q true; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    git_info=" ($branch)"
  fi
fi

# コンテキスト使用率
context_info=""
if [ -n "$used" ]; then
  context_info=" [ctx: ${used}%]"
fi

# モデル情報
model_info=""
if [ -n "$model" ]; then
  model_info=" | $model"
fi

printf "\033[32m%s\033[0m@\033[36m%s\033[0m:\033[34m%s\033[0m\033[33m%s\033[0m\033[35m%s\033[0m%s" \
  "$user" "$host" "$display_dir" "$git_info" "$context_info" "$model_info"
