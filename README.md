# dotfiles

This repository contains my dotfiles. I use [chezmoi](https://www.chezmoi.io/) to manage them.

## Installation

```sh
brew install chezmoi
```

## Usage

```sh
chezmoi init https://github.com/ko-tominaga/dotfiles.git
chezmoi apply
```

## Development

このリポジトリ自身の変更をコミットする際は、[gitleaks](https://github.com/gitleaks/gitleaks) による秘匿情報チェックが pre-commit フックとして実行されます。

`chezmoi apply` を実行すると `.chezmoiscripts/run_once_after_configure-git-hooks.sh.tmpl` が `core.hooksPath` を `.githooks` に設定し、自動的に有効化されます。手動で設定する場合は以下を実行してください。

```sh
git config core.hooksPath .githooks
```
