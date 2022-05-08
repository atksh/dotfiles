#!/bin/bash
set -eux
SCRIPT_DIR=$(cd $(dirname $0); pwd)

mv ~/.vim/undo /tmp/undo.old
rm -rf ~/.vim || true
rm -rf $HOME/.dotfiles || true
mv ~/.vimrc ~/.vimrc.old || true
mv ~/.gvimrc ~/.gvimrc.old || true
mv /tmp/undo.old ~/.vim/undo

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

mkdir -p $HOME/.dotfiles
ln -s $HOME/.dotfiles/.vimrc ~/.vimrc
ln -s $HOME/.dotfiles/.gvimrc ~/.gvimrc
cp .vimrc .gvimrc $HOME/.dotfiles

# install pluings
vim -es -u ~/.vimrc +PlugInstall +qa
vim -c :Black -c BlackUpdate -c :q! /tmp/abcdef

# kite
mkdir -p ~/.vim/pack/kite/start/kite
git clone --depth=1 --recursive \
  https://github.com/kiteco/vim-plugin.git ~/.vim/pack/kite/start/kite/

