---
name: pr-review-comment
description: >
  GitHub の Pull Request をレビューし、その結果を gh api で
  インラインコメントとして PR に自動投稿するスキル。
  「この PR をレビューしてコメントして」「PR をレビューしてインラインで指摘して」
  「レビューしてコメントまで付けて」「<PR URL> をレビューしてコメント」などの依頼に使用する。
  プラグインの /review はチャットに結果を出すだけでコメントを付けないため、
  レビュー〜GitHub へのインラインコメント投稿まで一気通貫でやりたいときにこのスキルを使う。
---

# PR レビュー＋インラインコメント投稿スキル

GitHub PR をレビューし、検出した指摘を **PR のインラインコメント** として `gh api` で投稿する。
プラグインの `/review` がチャット提示までしかしない部分を、GitHub への書き込みまで自動化する。

引数として PR の URL か番号（例: `https://github.com/wantedly/mendy/pull/331` または `331`）を受け取る。
番号だけのときはカレントリポジトリ（`gh repo view`）を対象にする。

---

## Step 1: PR のメタ情報と diff を取得する

`git diff` ではなく必ず `gh` で取得する（レビュー対象は PR の diff のみ）。

```bash
gh pr view <PR> --json title,body,baseRefName,headRefName,headRefOid,changedFiles,additions,deletions
gh pr diff <PR>
```

`headRefOid`（HEAD コミット SHA）はインラインコメント投稿に必須なので控えておく。
diff が大きいときは保存して読み込む。

## Step 2: レビューして指摘を洗い出す

`/review` と同じ精度方針でレビューする。**メンテナが実際に直す価値のある指摘だけ**を残す。

- diff の各 hunk を行単位で読む。変更行の前後（同じ関数の未変更行）も対象にする
- 観点: 反転/誤った条件・off-by-one・null/undefined・`await` 漏れ・falsy ゼロ判定・取り違えコピペ・握り潰した例外、削除された不変条件、呼び出し側/呼ばれ側への波及、既存ヘルパの再実装、不要な複雑さ・重複、無駄な計算/IO、CLAUDE.md / AGENTS.md 規約違反
- 必要に応じて周辺コードを Read して、トリガーとなる入力・状態・タイミングを具体化する
- 各指摘について、その指摘を**裏付ける/反証する**ように一度自己検証する。クラッシュや誤出力の条件を言えないものは落とす
- バグ系を cleanup 系より優先し、**最大 8 件** に絞る（深刻度順）

各指摘は `path` / `line`（複数行なら `start_line`〜`line`）/ 要約 / 具体的な失敗シナリオ を持つ。

## Step 3: 指摘をインラインコメント用のレビュー JSON にまとめる

`reviews` API は 1 リクエストで複数のインラインコメントを束ねた 1 レビューを作れる。
scratchpad に payload を書く。

- `commit_id`: Step 1 の `headRefOid`
- `event`: 原則 `COMMENT`（承認/変更要求はユーザー指示があるときだけ `APPROVE` / `REQUEST_CHANGES`）
- `body`: レビュー全体のサマリ（2〜3 文。何の PR か＋総評）
- `comments[]`: 各指摘。`path` は PR ルートからの相対パス、`line` は **diff に含まれる行**であること（追加行か変更行）。複数行に渡る指摘は `start_line` + `line`

```json
{
  "commit_id": "<headRefOid>",
  "event": "COMMENT",
  "body": "<レビュー総評>",
  "comments": [
    { "path": "path/to/file.ts", "start_line": 50, "line": 54, "body": "<指摘と失敗シナリオ>" },
    { "path": "path/to/other.ts", "line": 23, "body": "<指摘と失敗シナリオ>" }
  ]
}
```

コメント本文は日本語で、**何が問題か → どういう入力/状態で何が壊れるか → どう直すと良いか** を簡潔に書く。

## Step 4: gh api で投稿する

```bash
gh api repos/<owner>/<repo>/pulls/<number>/reviews \
  --method POST --input <payload.json> \
  -q '.html_url, .state'
```

owner/repo は `gh pr view <PR> --json url` か `gh repo view --json owner,name` から得る。
投稿後、返ってきた `html_url`（`#pullrequestreview-...`）をユーザーに伝える。

## Step 5: 結果を報告する

投稿したレビュー URL と、付けたコメントの一覧（`file:line — 要約`）を簡潔に提示する。
指摘が 0 件なら投稿せず、その旨を伝える。

---

## 注意

- **書き込みは PR への公開操作**。指摘が出揃ったら投稿前に件数と概要を一言添えて実行する（明示的に止められていない限り進めてよい）
- `line` が diff に含まれない行を指すと `422` で失敗する。失敗したら対象行が diff 内かを確認し、近い追加/変更行に寄せる
- 投稿の単位は「1 レビュー（複数インラインコメント）」にまとめる。コメントを個別 POST で散らさない
- レビューの精度方針・観点の詳細はプラグインの `/review` に準拠する。本スキルの新規価値は **gh api での自動投稿** にある

## エラー対応

| エラー | 対処法 |
|--------|--------|
| `422 Unprocessable Entity`（line 指定） | その行が diff に含まれているか確認し、追加/変更行に合わせる |
| `commit_id` mismatch | `gh pr view <PR> --json headRefOid` で最新 SHA を取り直す |
| 認証エラー | `gh auth status` で確認 |
