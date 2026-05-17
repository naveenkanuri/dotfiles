#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"

pull_clean_repo() {
  local repo="$1"
  local name="$2"

  if [[ ! -d "$repo/.git" ]]; then
    print "skipping $name: not a git repo"
    return
  fi

  if [[ -n "$(git -C "$repo" status --porcelain)" ]]; then
    print "skipping $name pull: working tree is dirty"
    return
  fi

  git -C "$repo" pull --ff-only
}

print "updating brew..."
brew update
brew upgrade --greedy

IFS=$'\n' casks=($(brew list --cask))
for cask in "${casks[@]}"; do
  brew upgrade --cask "$cask"
done

print "cleaning brew..."
brew cleanup

print "updating alacritty themes..."
pull_clean_repo "$HOME/.config/alacritty/themes" "alacritty themes"

print "updating neovim config"
pull_clean_repo "$HOME/.config/nvim" "neovim config"

print "updating rust..."
rustup update

mkdir -p "$HOME/Documents"
cp "$SCRIPT_DIR/update.sh" "$HOME/Documents/update.sh"
chmod +x "$HOME/Documents/update.sh"

mkdir -p "$HOME/.config/tmux"
cp "$SCRIPT_DIR/.tmux.conf" "$HOME/.config/tmux/tmux.conf"

mkdir -p "$HOME/.config/alacritty" "$HOME/.config/aerospace" "$HOME/.config/ghostty"
cp "$SCRIPT_DIR/ideavimrc" "$HOME/.ideavimrc"
cp "$SCRIPT_DIR/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
cp "$SCRIPT_DIR/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
cp "$SCRIPT_DIR/ghostty-config" "$HOME/.config/ghostty/config"

print "done."
