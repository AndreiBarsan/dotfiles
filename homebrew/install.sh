#!/bin/sh
#
# Homebrew
#
# This installs some of the common dependencies needed (or at least desired)
# using Homebrew.

# Check for Homebrew.
if test ! $(which brew)
then
  echo "  Installing Homebrew for you."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew update

# Install homebrew packages.
brew install grc coreutils spark macvim calc npm cowsay sl cmake scons \
  curl ack homebrew/games/nethack caskroom/cask/brew-cask python \
  reattach-to-user-namespace

# Install more stuf using cask.
brew-cask install karabiner seil

# Install fancy fonts needed by vim through pip, the Python package manager.
pip install --user powerline-status

exit 0
