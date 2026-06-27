---
name: commit-and-create-pr
description: >
  ステージングされた変更をコミット・プッシュしてプルリクエストを作成し、ブラウザで開くまでを一括実行する。
  「コミットしてPRを作って」「変更をPRにして」「commit and PR」「まとめてPR出して」などの依頼に使用する。
  コミット・プッシュ・PR作成・ブラウザ表示の全工程を順番に実行する。
---

# Commit & Create PR スキル

ステージングされた変更から、PR作成・ブラウザ表示まで一括で実行する。

## 実行順序

以下を上から順番に独立して実行する:

### Step 1: コミット & プッシュ

`commit-push` スキルの手順に従って実行:
- main/masterブランチなら `ko-tominaga/` で始まるブランチを作成
- Conventional Commits形式の英語コミットメッセージでコミット
- リモートにプッシュ

### Step 2: PR作成

`create-pr` スキルの手順に従って実行:
- Why/What形式の日本語PR本文を作成
- `gh pr create` でPRを作成

### Step 3: ブラウザで開く

```bash
gh pr view --web
```
