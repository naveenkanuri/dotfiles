#!/bin/zsh

echo "updating brew...."
brew update && brew upgrade --greedy

IFS=$'\n' casks=($(brew list --cask))
for cask in "${casks[@]}"; do
    brew upgrade --cask "$cask"
done
echo "cleaning brew..."
brew cleanup

echo "updating alacritty themes...."
git -C $HOME/.config/alacritty/themes pull

echo "updating neovim config"
git -C $HOME/.config/nvim pull

echo "udpating rust...."
rustup update

cp ./update.sh $HOME/Documents/update.sh
chmod +x $HOME/Documents/update.sh

cp ./.tmux.conf $HOME/.config/tmux/tmux.conf

cp ./ideavimrc $HOME/.ideavimrc
cp ./alacritty.toml $HOME/.config/alacritty/alacritty.toml
cp ./aerospace.toml $HOME/.config/aerospace/aerospace.toml
cp ./ghostty-config $HOME/.config/ghostty/config

echo "done...."
