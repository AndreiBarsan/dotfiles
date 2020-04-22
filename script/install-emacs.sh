#!/usr/bin/env bash
# Installs a recent version of emacs in a user dir (~/.local by default).

set -eu

EMACS="emacs-26.3"
EMACS_XZ="${EMACS}.tar.xz"

# Install the necessary Linux dependencies
# sudo apt-get install --yes texinfo libx11-dev libxpm-dev libjpeg-dev \
  # libpng-dev libgif-dev libtiff-dev libgtk2.0-dev \
  # libxpm-dev automake autoconf gnutls-dev

# Ensure we have access to homebrew stuff on macOS.
# It's also super-important to have pkg-config installed on macOS.
# brew install gnutls libxml2 pkg-config
export PKG_CONFIG_PATH="/usr/local/opt/gnutls/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export PKG_CONFIG_PATH="/usr/local/opt/libxml2/lib/pkgconfig:${PKG_CONFIG_PATH}"

mkdir -p ~/work
cd ~/work

if ! [[ -f "$EMACS_XZ" ]]; then
  wget "http://mirror.sergal.org/gnu/emacs/$EMACS_XZ"
fi

# TODO(andrei): What about auto uninstall?
if [[ -d "$EMACS" ]]; then
  rm -rf "$EMACS"
fi

tar xf "$EMACS_XZ" 
cd "$EMACS"

./configure CFLAGS='-O3' --prefix=$HOME/.local
make -j$(nproc)
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
