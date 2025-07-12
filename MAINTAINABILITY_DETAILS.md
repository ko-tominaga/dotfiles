# 保守性向上の詳細ガイド

## 概要

dotfilesリポジトリの保守性を向上させることで、長期的な運用と管理が容易になります。以下に具体的な実装方法を示します。

## 1. 設定ファイルのバージョン管理

### 現状の問題
- 設定ファイルの変更履歴が追跡しにくい
- 破損した設定を元に戻すのが困難
- 設定の変更理由が不明

### 実装方法

#### 1.1 設定ファイルのバージョン情報追加

```bash
# dot_zshrc.tmpl
# Dotfiles Version: {{ .dotfiles.version }}
# Last Updated: {{ .dotfiles.last_updated }}
# -------------------
# Zsh Configuration
# -------------------
```

#### 1.2 .chezmoidata/config.yaml の作成

```yaml
# .chezmoidata/config.yaml
dotfiles:
  version: "2.1.0"
  last_updated: "2024-01-15"
  maintainer: "{{ .chezmoi.username }}"
  
versioning:
  track_changes: true
  backup_before_apply: true
  changelog_auto_generate: true
```

#### 1.3 バージョン管理スクリプト

```bash
# scripts/version-bump.sh
#!/bin/bash

CURRENT_VERSION=$(grep -o 'version: "[^"]*' .chezmoidata/config.yaml | cut -d'"' -f2)
NEW_VERSION=$1

if [ -z "$NEW_VERSION" ]; then
    echo "Usage: $0 <new_version>"
    echo "Current version: $CURRENT_VERSION"
    exit 1
fi

# バージョン更新
sed -i "s/version: \"$CURRENT_VERSION\"/version: \"$NEW_VERSION\"/" .chezmoidata/config.yaml
sed -i "s/last_updated: \".*\"/last_updated: \"$(date +%Y-%m-%d)\"/" .chezmoidata/config.yaml

# Git タグの作成
git add .chezmoidata/config.yaml
git commit -m "Bump version to $NEW_VERSION"
git tag "v$NEW_VERSION"

echo "Version bumped from $CURRENT_VERSION to $NEW_VERSION"
```

## 2. 変更履歴の自動生成

### 2.1 CHANGELOGの自動生成

```bash
# scripts/generate-changelog.sh
#!/bin/bash

OUTPUT_FILE="CHANGELOG.md"
REPO_URL="https://github.com/ko-tominaga/dotfiles"

cat > "$OUTPUT_FILE" << 'EOF'
# Changelog

All notable changes to this dotfiles repository will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

EOF

# Git タグベースでの変更履歴生成
git tag -l --sort=-version:refname | while read tag; do
    if [ -n "$previous_tag" ]; then
        echo "## [$tag] - $(git log -1 --format=%ai $tag | cut -d' ' -f1)" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        
        # 変更されたファイルの一覧
        git diff --name-only "$tag" "$previous_tag" | while read file; do
            case "$file" in
                dot_*)
                    echo "### Changed" >> "$OUTPUT_FILE"
                    echo "- Updated $(basename "$file" | sed 's/dot_//')" >> "$OUTPUT_FILE"
                    ;;
                .chezmoidata/*)
                    echo "### Configuration" >> "$OUTPUT_FILE"
                    echo "- Updated package configuration" >> "$OUTPUT_FILE"
                    ;;
                .chezmoiscripts/*)
                    echo "### Scripts" >> "$OUTPUT_FILE"
                    echo "- Updated installation scripts" >> "$OUTPUT_FILE"
                    ;;
            esac
        done
        echo "" >> "$OUTPUT_FILE"
    fi
    previous_tag=$tag
done
```

### 2.2 GitHub Actions での自動化

```yaml
# .github/workflows/changelog.yml
name: Generate Changelog

on:
  push:
    tags:
      - 'v*'

jobs:
  changelog:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - name: Generate Changelog
        run: |
          chmod +x scripts/generate-changelog.sh
          ./scripts/generate-changelog.sh
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          body_path: CHANGELOG.md
          draft: false
          prerelease: false
```

## 3. 定期的なパッケージ更新の自動化

### 3.1 パッケージ更新チェック

```bash
# scripts/check-updates.sh
#!/bin/bash

LOG_FILE="/tmp/dotfiles-updates.log"
NOTIFICATION_FILE="/tmp/dotfiles-needs-update"

echo "Checking for package updates..." > "$LOG_FILE"

# Homebrew パッケージのチェック
if command -v brew &> /dev/null; then
    echo "=== Homebrew Updates ===" >> "$LOG_FILE"
    brew update >> "$LOG_FILE" 2>&1
    
    OUTDATED=$(brew outdated --json | jq -r '.[].name' 2>/dev/null)
    if [ -n "$OUTDATED" ]; then
        echo "Outdated packages found:" >> "$LOG_FILE"
        echo "$OUTDATED" >> "$LOG_FILE"
        touch "$NOTIFICATION_FILE"
    else
        echo "All Homebrew packages are up to date." >> "$LOG_FILE"
    fi
fi

# Chezmoi 自体の更新チェック
if command -v chezmoi &> /dev/null; then
    echo "=== Chezmoi Updates ===" >> "$LOG_FILE"
    CURRENT_VERSION=$(chezmoi --version | cut -d' ' -f2)
    LATEST_VERSION=$(curl -s https://api.github.com/repos/twpayne/chezmoi/releases/latest | jq -r '.tag_name' | sed 's/v//')
    
    if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
        echo "Chezmoi update available: $CURRENT_VERSION -> $LATEST_VERSION" >> "$LOG_FILE"
        touch "$NOTIFICATION_FILE"
    else
        echo "Chezmoi is up to date." >> "$LOG_FILE"
    fi
fi

# 通知
if [ -f "$NOTIFICATION_FILE" ]; then
    echo "Updates available! Check $LOG_FILE for details."
    # macOS の場合は通知を表示
    if [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e 'display notification "Package updates available" with title "Dotfiles"'
    fi
fi
```

### 3.2 定期実行の設定

```bash
# scripts/setup-cron.sh
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRON_JOB="0 9 * * 1 $SCRIPT_DIR/check-updates.sh"

# 既存のcronジョブをチェック
if crontab -l 2>/dev/null | grep -q "check-updates.sh"; then
    echo "Cron job already exists"
else
    # 新しいcronジョブを追加
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "Cron job added: Weekly update check every Monday at 9 AM"
fi
```

## 4. 設定の検証スクリプト

### 4.1 設定ファイルの健全性チェック

```bash
# scripts/validate-config.sh
#!/bin/bash

EXIT_CODE=0
TEMP_DIR="/tmp/dotfiles-validation"

echo "Validating dotfiles configuration..."

# 一時ディレクトリの作成
mkdir -p "$TEMP_DIR"

# Zsh設定の検証
echo "Checking Zsh configuration..."
if ! zsh -n "$HOME/.zshrc" 2>/dev/null; then
    echo "❌ Zsh configuration has syntax errors"
    EXIT_CODE=1
else
    echo "✅ Zsh configuration is valid"
fi

# Git設定の検証
echo "Checking Git configuration..."
if ! git config --file="$HOME/.gitconfig" --list >/dev/null 2>&1; then
    echo "❌ Git configuration is invalid"
    EXIT_CODE=1
else
    echo "✅ Git configuration is valid"
fi

# Chezmoi設定の検証
echo "Checking Chezmoi configuration..."
if ! chezmoi data >/dev/null 2>&1; then
    echo "❌ Chezmoi configuration is invalid"
    EXIT_CODE=1
else
    echo "✅ Chezmoi configuration is valid"
fi

# パッケージリストの検証
echo "Checking package availability..."
while read -r package; do
    if [[ "$package" =~ ^[[:space:]]*$ ]] || [[ "$package" =~ ^# ]]; then
        continue
    fi
    
    if ! brew info "$package" >/dev/null 2>&1; then
        echo "⚠️  Package '$package' not found in Homebrew"
    fi
done < <(yq eval '.packages.darwin.brews[]' .chezmoidata/packages.yaml 2>/dev/null)

# クリーンアップ
rm -rf "$TEMP_DIR"

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ All validations passed"
else
    echo "❌ Some validations failed"
fi

exit $EXIT_CODE
```

### 4.2 設定のバックアップと復元

```bash
# scripts/backup-config.sh
#!/bin/bash

BACKUP_DIR="$HOME/.dotfiles-backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/backup_$TIMESTAMP"

echo "Creating backup at $BACKUP_PATH..."

mkdir -p "$BACKUP_PATH"

# 重要な設定ファイルのバックアップ
IMPORTANT_FILES=(
    ".zshrc"
    ".gitconfig"
    ".ssh/config"
    ".vimrc"
    ".tmux.conf"
)

for file in "${IMPORTANT_FILES[@]}"; do
    if [ -f "$HOME/$file" ]; then
        cp "$HOME/$file" "$BACKUP_PATH/"
        echo "Backed up: $file"
    fi
done

# メタデータの保存
cat > "$BACKUP_PATH/metadata.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "hostname": "$(hostname)",
  "user": "$(whoami)",
  "os": "$(uname -s)",
  "chezmoi_version": "$(chezmoi --version 2>/dev/null || echo 'N/A')"
}
EOF

echo "Backup completed: $BACKUP_PATH"

# 古いバックアップの削除（30日以上）
find "$BACKUP_DIR" -type d -name "backup_*" -mtime +30 -exec rm -rf {} + 2>/dev/null

echo "Cleanup completed"
```

## 5. 健全性監視とアラート

### 5.1 設定ファイルの監視

```bash
# scripts/monitor-configs.sh
#!/bin/bash

WATCH_FILES=(
    "$HOME/.zshrc"
    "$HOME/.gitconfig"
)

CHECKSUM_FILE="$HOME/.dotfiles-checksums"

# 初回実行時のチェックサム作成
if [ ! -f "$CHECKSUM_FILE" ]; then
    echo "Creating initial checksums..."
    for file in "${WATCH_FILES[@]}"; do
        if [ -f "$file" ]; then
            shasum "$file" >> "$CHECKSUM_FILE"
        fi
    done
    exit 0
fi

# 変更の検出
echo "Checking for unauthorized changes..."
CHANGED_FILES=()

for file in "${WATCH_FILES[@]}"; do
    if [ -f "$file" ]; then
        CURRENT_CHECKSUM=$(shasum "$file" | cut -d' ' -f1)
        STORED_CHECKSUM=$(grep "$file" "$CHECKSUM_FILE" | cut -d' ' -f1)
        
        if [ "$CURRENT_CHECKSUM" != "$STORED_CHECKSUM" ]; then
            CHANGED_FILES+=("$file")
        fi
    fi
done

# 変更があった場合の処理
if [ ${#CHANGED_FILES[@]} -gt 0 ]; then
    echo "⚠️  Configuration files have been modified outside of chezmoi:"
    for file in "${CHANGED_FILES[@]}"; do
        echo "  - $file"
    done
    
    # 通知
    if [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e 'display notification "Configuration files modified" with title "Dotfiles Alert"'
    fi
fi
```

### 5.2 GitHub Actions での継続監視

```yaml
# .github/workflows/health-check.yml
name: Health Check

on:
  schedule:
    - cron: '0 0 * * 0'  # 毎週日曜日
  workflow_dispatch:

jobs:
  health-check:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install chezmoi
        run: brew install chezmoi
      
      - name: Run validation
        run: |
          chmod +x scripts/validate-config.sh
          ./scripts/validate-config.sh
      
      - name: Check for updates
        run: |
          chmod +x scripts/check-updates.sh
          ./scripts/check-updates.sh
      
      - name: Create issue on failure
        if: failure()
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: 'Dotfiles Health Check Failed',
              body: 'Automated health check failed. Please review the workflow logs.',
              labels: ['maintenance', 'automated']
            })
```

## 6. 実装の優先順位

### 即座に実装すべき項目
1. **設定ファイルの検証スクリプト** - 破損した設定の早期発見
2. **バックアップスクリプト** - 設定変更前の安全確保
3. **バージョン管理の導入** - 変更履歴の追跡

### 中期的に実装すべき項目
1. **自動更新チェック** - パッケージの定期監視
2. **変更履歴の自動生成** - ドキュメント化の自動化
3. **設定監視** - 予期しない変更の検出

### 長期的に実装すべき項目
1. **継続的な健全性チェック** - GitHub Actions での自動化
2. **高度な監視とアラート** - 問題の早期発見
3. **設定の自動復旧** - 問題発生時の自動回復

## 7. 導入手順

```bash
# 1. スクリプトディレクトリの作成
mkdir -p scripts

# 2. 各スクリプトの作成と実行権限の付与
chmod +x scripts/*.sh

# 3. 初期設定の実行
./scripts/setup-cron.sh
./scripts/validate-config.sh
./scripts/backup-config.sh

# 4. GitHub Actions の設定
# .github/workflows/ に必要なワークフローファイルを配置

# 5. 初回バージョンの設定
./scripts/version-bump.sh 1.0.0
```

これらの実装により、dotfilesリポジトリの長期的な保守性が大幅に向上し、安全で信頼性の高い設定管理が可能になります。