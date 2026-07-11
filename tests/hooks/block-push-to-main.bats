#!/usr/bin/env bats
# dot_claude/hooks/executable_block-push-to-main.sh のテスト。
#
# フックはstdinでPreToolUseのJSONを受け取り、危険なpushを検知した場合のみ
# permissionDecision: deny を含むJSONをstdoutに出力する(exit codeは常に0)。
# そのため各テストは「出力にdenyが含まれるか」でBLOCKED/ALLOWEDを判定する。

setup() {
  HOOK_SCRIPT="$BATS_TEST_DIRNAME/../../dot_claude/hooks/executable_block-push-to-main.sh"
  REPO_DIR="$BATS_TEST_TMPDIR/repo"
  BARE_DIR="$BATS_TEST_TMPDIR/origin.git"

  git init -q --bare "$BARE_DIR"

  mkdir -p "$REPO_DIR"
  cd "$REPO_DIR"
  git init -q -b work
  git config user.email "test@example.com"
  git config user.name "Test"
  git commit -q --allow-empty -m "init"
  git remote add origin "$BARE_DIR"
}

# 現在のブランチをorigin/mainにpushし、ローカルのリモート追跡ブランチを
# origin/<name>に設定した上で、作業ブランチのupstreamをそこに向ける。
# (`git worktree add -b <branch> origin/main` 後の状態を再現する)
track_upstream_to() {
  local remote_branch="$1"
  git push -q origin "work:$remote_branch"
  git fetch -q origin
  git branch -q --set-upstream-to="origin/$remote_branch" work
}

run_hook() {
  local cmd="$1"
  printf '{"tool_input":{"command":"%s"}}' "$cmd" | "$HOOK_SCRIPT"
}

assert_blocked() {
  [[ "$output" == *'"permissionDecision": "deny"'* ]]
}

assert_allowed() {
  [ -z "$output" ]
}

@test "non git-push commands are allowed without inspection" {
  run run_hook "git status"
  assert_allowed
}

@test "ALLOW_PUSH_TO_MAIN=1 bypasses even a push on main" {
  git checkout -q -b main
  ALLOW_PUSH_TO_MAIN=1 run run_hook "git push"
  assert_allowed
}

@test "check1: current branch main blocks regardless of args" {
  git checkout -q -b main
  run run_hook "git push origin feature:feature"
  assert_blocked
}

@test "check1: current branch master blocks regardless of args" {
  git checkout -q -b master
  run run_hook "git push origin feature:feature"
  assert_blocked
}

@test "check2: git push origin main is blocked" {
  run run_hook "git push origin main"
  assert_blocked
}

@test "check2: git push origin master is blocked" {
  run run_hook "git push origin master"
  assert_blocked
}

@test "check3: bare git push with upstream=origin/main is blocked" {
  track_upstream_to main
  run run_hook "git push"
  assert_blocked
}

@test "check3: git push origin with upstream=origin/main is blocked" {
  track_upstream_to main
  run run_hook "git push origin"
  assert_blocked
}

@test "check3: bare git push with upstream=origin/master is blocked" {
  track_upstream_to master
  run run_hook "git push"
  assert_blocked
}

@test "check3: explicit non-main refspec with upstream=origin/main is allowed (regression fix)" {
  track_upstream_to main
  run run_hook "git push origin feature:feature"
  assert_allowed
}

@test "check3: -u with explicit non-main branch and upstream=origin/main is allowed" {
  track_upstream_to main
  run run_hook "git push -u origin feature"
  assert_allowed
}

@test "check3: branch name containing 'main' without word boundary is allowed" {
  track_upstream_to main
  run run_hook "git push origin feature-main:feature-main"
  assert_allowed
}

@test "no upstream tracking means check3 never fires" {
  run run_hook "git push"
  assert_allowed
}
