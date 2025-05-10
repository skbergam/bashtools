#!/usr/bin/env bash

echo "UPDATING '~/.bash_profile'..."
sed -i '/BASHTOOLS/d' ~/.bash_profile # remove matching lines if this is a reinstall
echo 'source ~/.bashtools/activate_tools.sh # BASHTOOLS' >> ~/.bash_profile
echo 'PATH=$PATH:$HOME/.bashtools # BASHTOOLS' >> ~/.bash_profile
