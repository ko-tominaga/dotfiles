---
name: update-dotfiles
description: >
  chezmoiで管理されているdotfilesを更新するワークフロー。
  dotfilesの変更、chezmoi diff確認、chezmoi apply、GitコミットからPR作成・ブラウザ表示まで一括実行する。
  ユーザーが「dotfilesを更新」「dotfilesを修正」「.zshrcを変更」「.gitconfigを編集」「chezmoi」
  などdotfilesや設定ファイルの変更に関するキーワードを使った場合は必ずこのスキルを使うこと。
  シェル設定、Git設定、エディタ設定、環境変数など ~/.xxx 形式のファイルへの変更依頼にも使用する。
---

# dotfiles更新スキル

chezmoiで管理されているdotfilesを安全に更新し、PRを作成するワークフロー。

## 環境情報

- **chezmoiソースディレクトリ**: `$(chezmoi source-path)` で取得（通常 `~/.local/share/chezmoi`）
- **GitHubリポジトリ**: `git -C "$(chezmoi source-path)" remote get-url origin` で取得
- **ファイル命名規則**: chezmoiはドットファイルを `dot_` プレフィックスで管理する
  - 例: `.zshrc` → `dot_zshrc`, `.gitconfig` → `dot_gitconfig`
  - テンプレートファイルは `.tmpl` サフィックスが付く（例: `dot_zshrc.tmpl`）

> **注意**: `chezmoi cd` はサブシェルを起動するためBashツールからは使えない。
> ディレクトリ取得には `chezmoi source-path` を使うこと。

## ワークフロー

### Step 1: ソースディレクトリを確認する

```bash
chezmoi source-path
```

ソースディレクトリ内のファイル構造を把握してから作業を始める。

### Step 2: dotfilesを修正する

ユーザーが依頼した変更をchezmoiのソースディレクトリ内のファイルに適用する。

- 対象ファイルのパス: `$(chezmoi source-path)/dot_<ファイル名>` または `$(chezmoi source-path)/dot_<ファイル名>.tmpl`
- 既にユーザーが直接修正している場合はこのステップをスキップ
- 変更前に必ずファイルを読み込んで現在の内容を確認する

### Step 3: chezmoi diffで変更を確認する

```bash
chezmoi diff
```

差分を表示してユーザーに確認する。以下の点をチェック:
- 変更内容が依頼通りか
- 意図しないファイルが変更されていないか
- テンプレート変数が正しく展開されるか

**差分が意図した内容でない場合は、Step 2に戻って修正する。**

### Step 4: chezmoi applyを実行する

差分が確認できたら適用する:

```bash
chezmoi apply --force
```

> **注意**: `chezmoi apply` はTTYを要求してインタラクティブプロンプトを出すことがある。
> Bashツールからの実行では `--force` を付けて確認をスキップする。

エラーが出た場合は原因を調査して対処する。

### Step 5: ブランチを作成してコミットする

chezmoiのソースディレクトリはGitリポジトリなので、そこでコミット作業を行う:

```bash
CHEZMOI_DIR=$(chezmoi source-path)

# フィーチャーブランチを作成（ブランチ名は変更内容を反映した英語のkebab-case）
git -C "$CHEZMOI_DIR" checkout -b <branch-name>

# 変更をステージング（具体的なファイル名を指定する）
git -C "$CHEZMOI_DIR" add <changed-files>

# コミット（変更内容を日本語で説明）
git -C "$CHEZMOI_DIR" commit -m "変更内容の説明"
```

コミットメッセージは変更の「何を」「なぜ」変更したかを明確に記述する。

### Step 6: GitHubにプッシュしてPRを作成する

```bash
CHEZMOI_DIR=$(chezmoi source-path)

# プッシュ
git -C "$CHEZMOI_DIR" push -u origin <branch-name>

# PR作成
gh pr create \
  --title "PRタイトル" \
  --body "変更内容の説明"
```

PR本文には以下を含める:
- 変更したファイルと変更内容
- 変更の理由・目的
- 動作確認方法（あれば）

### Step 7: ブラウザでPRを開く

```bash
gh pr view --web
```

## エラー対応

| エラー | 対処法 |
|--------|--------|
| `chezmoi apply` でコンフリクト | `chezmoi diff` で詳細確認、手動解決後に再適用 |
| テンプレートエラー | `.tmpl` ファイルのGoテンプレート構文を確認 |
| push失敗（権限） | `gh auth status` で認証確認 |
| PRの重複 | 既存PRを `gh pr list` で確認 |

## chezmoi ファイル名変換の参考

| 実際のファイル | chezmoiソース内 |
|--------------|----------------|
| `~/.zshrc` | `dot_zshrc` |
| `~/.gitconfig` | `dot_gitconfig` |
| `~/.zshenv` | `dot_zshenv.tmpl`（テンプレートの場合） |
| `~/.config/foo/bar` | `dot_config/foo/bar` |
