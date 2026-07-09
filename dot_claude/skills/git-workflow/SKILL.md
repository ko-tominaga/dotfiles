---
name: git-workflow
description: >
  コミット・プッシュ・PR作成のgit操作を担うスキル。
  「コミットして」「pushして」「PRを作って」「プルリクエストを作成して」
  「コミットしてPRも作って」「変更をPRにして」などの依頼に使用する。
  Conventional Commits形式のコミット、main/masterブランチ保護、Why/What形式のPR本文作成を行う。
---

# Git Workflow スキル

依頼内容に応じて、コミット・プッシュ・PR作成を組み合わせて実行する。

## ケース別の実行内容

| 依頼 | 実行すること |
|------|------------|
| コミットして / pushして | [コミット & プッシュ] のみ |
| PRを作って | [PR作成] のみ |
| コミットしてPRも作って / 全部やって | [コミット & プッシュ] → [PR作成] → [ブラウザで開く] |

---

## コミット & プッシュ

1. **git addは実行しない** — ステージング済みの変更のみ対象

2. **ブランチを確認する**
   現在のブランチが `main` または `master` の場合はフィーチャーブランチを作成:
   ```bash
   git checkout -b ko-tominaga/<変更内容を表す英語のkebab-case>
   ```

3. **コミットメッセージを作成する** — ステージングされた差分を確認し、Conventional Commits形式で英語のメッセージを作成:
   ```
   <type>(<scope>): <summary>
   ```
   タイプ: `feat` / `fix` / `docs` / `style` / `refactor` / `perf` / `test` / `build` / `ci` / `chore`

4. **コミット & プッシュ**
   ```bash
   git commit -m "<message>"
   git push -u origin <branch>
   ```

**コミットメッセージ例:**
```
feat(auth): add user login functionality
fix(api): resolve timeout issue in user service
refactor(db): simplify query builder logic
```

---

## PR作成

1. **PR本文をWhy/What形式で日本語で作成する**
   ```markdown
   ## Why
   （変更の背景・理由・解決する問題）

   ## What
   （具体的な変更内容）
   ```

   - **Whatは抽象度を上げて書く** — 「何を・なぜ変更したか」を書けば十分。
     変更したメソッド名の列挙、削除した行数、`describe`ブロック名などの
     差分を見れば自明な情報は書かない。レビュアーの認知負荷を増やすだけなので避ける。

2. **PRを作成する**
   ```bash
   gh pr create --title "<タイトル>" --body "$(cat <<'EOF'
   ## Why
   ...

   ## What
   ...
   EOF
   )"
   ```

---

## ブラウザで開く（コミット & PR作成をした場合）

```bash
gh pr view --web
```
