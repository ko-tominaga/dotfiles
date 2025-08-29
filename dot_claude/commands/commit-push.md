---
description: ステージングされた変更をコミットしてプッシュする
---
# Commit & Push

ステージングされた変更をコミットしてプッシュします。Conventional Commits形式のコミットメッセージを英語で作成します。

## 使用方法

このコマンドは現在のワーキングディレクトリで以下の操作を実行します

1. **git addは実行しません**（事前にステージングされている変更のみ対象）
2. **branchがmaster or mainでは無い事を確認。master or mainの場合はbranchを作成してください。ブランチ名は必ず`ko-tominaga/`から始まるようにしてください。**
3. Conventional Commits形式でコミットメッセージを作成
4. 変更をコミット
5. リモートリポジトリにプッシュ

## コミットメッセージ形式

Conventional Commits形式で英語のコミットメッセージを作成します

### 利用可能なタイプ

- `feat(<scope>): <概要>`          # ユーザー向け新機能
- `fix(<scope>): <概要>`           # バグ修正
- `docs(<scope>): <概要>`          # ドキュメント
- `style(<scope>): <概要>`         # 体裁のみ
- `refactor(<scope>): <概要>`      # リファクタリング
- `perf(<scope>): <概要>`          # パフォーマンス改善
- `test(<scope>): <概要>`          # テスト追加・修正
- `build(<scope>): <概要>`         # ビルド/依存
- `ci(<scope>): <概要>`            # CI 設定・スクリプト
- `chore(<scope>): <概要>`         # その他保守作業

### 例

```
feat(auth): add user login functionality
fix(api): resolve timeout issue in user service
docs(readme): update installation instructions
```

### 任意のフッター

- `Refs: #123` - 関連Issue参照
- `Fixes: #123` - Issue修正
