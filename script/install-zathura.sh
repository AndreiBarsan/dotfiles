#!/usr/bin/env bash
# Build and install the zathura PDF viewer for the local user.
set -euo pipefail
IFS=$'\n\t'

# meson requires python 3.5, unavailable by default on 14.04 LTS. FFS.
sudo /usr/bin/pip3 install meson

if ! [[ -d "$PROJECTS/zathura" ]]; then
  mkdir "$PROJECTS/zathura" && cd $_
  git clone https://github.com/pwmt/zathura .
fi

cd "$PROJECTS/zathura"
git pull && git fetch

git checkout 0.4.0
meson build --prefix "$HOME/.local"
cd build && ninja && ninja install




