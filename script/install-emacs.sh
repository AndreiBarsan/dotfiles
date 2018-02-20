#!/usr/bin/env bash

set -eu

EMACS="emacs-25.3"
EMACS_XZ="${EMACS}.tar.xz"

# SCRATCH_DIR="scratch-$EMACS"

mkdir -p ~/work
cd ~/work

if ! [[ -f "$EMACS_XZ" ]]; then
  wget "http://mirror.sergal.org/gnu/emacs/$EMACS_XZ"
fi

# TODO(andrei): What about auto uninstall?
if [[ -d "$EMACS" ]]; then
  rm -rvf "$EMACS"
fi

tar xf "$EMACS_XZ"
cd "$EMACS"

./configure --prefix=$HOME/.local
make -j24
make install

echo "$EMACS installed successfully"
echo "Your emacs: $(which emacs)"
echo "Version info: $(emacs --version)"
echo "Bye!"
