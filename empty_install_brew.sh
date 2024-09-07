#!/bin/bash

echo "installing homebrew..."
which brew >/dev/null 2>&1 || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

echo "run brew doctor..."
which brew >/dev/null 2>&1 && brew doctor

echo "run brew update..."
which brew >/dev/null 2>&1 && brew update

echo "ok. run brew upgrade..."
brew upgrade

formulas=(
  gh
  git
  mysql
  tmux
  tmuxinator
  tree
  warp
  yarn
  mas
)

echo "brew tap"
# brew tap thirdparty
brew tap homebrew/cask-fonts

echo "brew install formula"
for formula in "${formulas[@]}"; do
  brew install $formula || brew upgrade $formula
done

# install gui up
casks=(
  deepl
  docker
  dropbox
  iterm2
  notion
  obs
  shottr
  slack
  visual-studio-code
  corsor
)

echo "brew casks"
for cask in "${casks[@]}"; do
  brew install --cask $cask
done

# stores=(
# )

# echo "app stores"
# for store in "${stores[@]}"; do
#   mas install $store
# done

brew cleanup

echo "brew installed"
