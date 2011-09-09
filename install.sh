#!/bin/sh

if [ -e $HOME/.vim/plugin/vto.vim ]; then
  echo "Removing old version of vim-task-org ..."
  rm $HOME/.vim/plugin/vto.vim > /dev/null 2>&1
  rm $HOME/.vim/doc/vto.txt > /dev/null 2>&1
  echo "DONE"
fi

echo "Copying plugin/* to $HOME/.vim/plugin ... "
mkdir -p $HOME/.vim/plugin
cp -R plugin/* $HOME/.vim/plugin
echo "DONE"

echo "Copying doc/* to $HOME/.vim/doc ..."
mkdir -p $HOME/.vim/doc
cp -R doc/* $HOME/.vim/doc
echo "DONE"

echo -n "Updating vim help tags..."
    vim --noplugins -u NONE -U NONE \
        --cmd ":helptags $HOME/.vim/doc/" --cmd ":q" > /dev/null 2>&1
    echo "done."

#09.09.11 16:54:00
