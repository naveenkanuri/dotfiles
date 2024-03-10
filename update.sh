#!/bin/zsh

echo "updating brew...."
brew update && brew upgrade --greedy

IFS=$'\n' casks=($(brew list --cask))
for cask in "${casks[@]}"; do
    brew upgrade --cask "$cask"
done
echo "cleaning brew..."
brew cleanup

echo "updating powerlevel10k...."
git -C ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k pull

echo "updating alacritty themes...."
git -C $HOME/.config/alacritty/themes pull

echo "udpating rust...."
rustup update

echo "done...."
