#!/usr/bin/env bash

set -eu

EMACS="emacs-26.3"
EMACS_XZ="${EMACS}.tar.xz"

# SCRATCH_DIR="scratch-$EMACS"

# Install the necessary Linux dependencies
sudo apt-get install --yes texinfo libx11-dev libxpm-dev libjpeg-dev \
  libpng-dev libgif-dev libtiff-dev libgtk2.0-dev \
  libxpm-dev automake autoconf gnutls-dev

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

./configure CFLAGS='-O3' --prefix=$HOME/.local
make -j24
make install

echo "================================================================================"
echo
echo "$EMACS installed successfully"
echo "Your emacs: $(which emacs)"
echo "Version info: $(emacs --version)"
echo
echo "To uninstall, go to $PWD and run 'make uninstall'."
echo "Bye!"
echo
echo "================================================================================"
