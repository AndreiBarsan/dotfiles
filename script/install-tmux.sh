#!/usr/bin/env bash
# Builds tmux and installs for the local user, on Debian-based Linux.

set -eu

# Set this to a valid tag name or 'master'.
# TMUX_VERSION="2.7"
TMUX_VERSION="3.5a"

sudo apt install --yes --no-install-recommends libevent-dev

if [[ -z "$PROJECTS" ]]; then
  echo >&2 "Please run this script after the basic bootstrap setup, so that " \
    "I know where I should download and build tmux."
  exit 10
fi

if ! [[ -d "$PROJECTS" ]]; then
  echo >&2 "The projects directory [$PROJECTS] does not exist. Not creating " \
    "by default, since it's a sign that this script is being called at an " \
    "inappropriate time."
  exit 20
fi

if [[ -d "$PROJECTS/tmux" && -f "$PROJECTS/tmux/Makefile" ]]; then
  # TODO alternatively, cd, make uninstall, make clean, git pull
  (cd "$PROJECTS/tmux" && make uninstall && make clean)
  mv -v "$PROJECTS/tmux" "$PROJECTS/tmux-old" || exit 25
fi

if [[ ! -d "$PROJECTS/tmux" ]]; then
  cd "$PROJECTS"
  git clone https://github.com/tmux/tmux.git || exit 30
fi

cd $PROJECTS/tmux
git fetch && git checkout "$TMUX_VERSION"
sh autogen.sh || exit 40
./configure --prefix "$HOME/.local" || exit 50
make -j$(nproc) || exit 60
make install || exit 70

echo
echo "tmux version [$TMUX_VERSION] installed successfully"

