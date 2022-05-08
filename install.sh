#!/bin/bash
set -eux

mkdir -p ~/.vim/undo || true
mv ~/.vimrc ~/.vimrc.old || true
mv ~/.gvimrc ~/.gvimrc.old || true
ln -s ~/dotfiles/.vimrc ~/.vimrc
ln -s ~/dotfiles/.gvimrc ~/.gvimrc

