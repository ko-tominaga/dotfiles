---
name: commit-push
description: >
  ステージングされた変更をコミットしてリモートにプッシュする。
  Conventional Commits形式（feat/fix/docs/refactor等）で英語のコミットメッセージを作成する。
  「コミットして」「pushして」「コミットしてプッシュ」「変更をコミット」などの依頼に使用する。
  main/masterブランチへの直接コミットを防ぎ、必要に応じてフィーチャーブランチを作成する。
---

# Commit & Push スキル

ステージングされた変更をConventional Commits形式でコミットし、リモートにプッシュする。

## 手順

1. **git addは実行しない** — ステージング済みの変更のみを対象とする

2. **ブランチを確認する**
   ```bash
   git branch --show-current
   ```
   現在のブランチが `main` または `master` の場合は、作業ブランチを作成する:
   ```bash
   git checkout -b ko-tominaga/<作業内容を表す英語のkebab-case>
   ```
   ブランチ名は必ず `ko-tominaga/` で始める。

3. **コミットメッセージを作成する** — ステージングされた変更の差分を確認し、Conventional Commits形式で英語のメッセージを作成する:
   ```
   <type>(<scope>): <summary>
   ```
   利用可能なタイプ: `feat` / `fix` / `docs` / `style` / `refactor` / `perf` / `test` / `build` / `ci` / `chore`

4. **コミットする**
   ```bash
   git commit -m "<message>"
   ```

5. **プッシュする**
   ```bash
   git push -u origin <branch>
   ```

## コミットメッセージ例

```
feat(auth): add user login functionality
fix(api): resolve timeout issue in user service
docs(readme): update installation instructions
refactor(db): simplify query builder logic
```

## 任意のフッター

- `Refs: #123` — 関連Issue参照
- `Fixes: #123` — Issue修正
