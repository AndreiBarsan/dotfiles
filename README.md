# ~~holman~~ andrei does dotfiles

## dotfiles

Your dotfiles are how you personalize your system. These are mine. This
repository is inspired by (and a fork of) [@holman's dotfile
repository](https://github.com/holman/dotfiles).

If you're interested in the philosophy behind why projects like these are
awesome, you might want to [read @holman's post on the
subject](http://zachholman.com/2010/08/dotfiles-are-meant-to-be-forked/).

## install

Run this:

```sh
git clone https://github.com/AndreiBarsan/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
script/bootstrap
```

This will symlink the appropriate files in `.dotfiles` to your home directory.
Everything is configured and tweaked within `~/.dotfiles`.

The main file you'll want to change right off the bat is `zsh/zshrc.symlink`,
which sets up a few paths that'll be different on your particular machine.

`dot` is a simple script that installs some dependencies, sets sane OS X
defaults, and so on. Tweak this script, and occasionally run `dot` from
time to time to keep your environment fresh and up-to-date. You can find
this script in `bin/`.

## this fork

There are several major differences between this (obviously personalized) fork
and @holman's upstream version.

First, I'm a vim user so my vimrc has way more stuff in it, and I've removed
all the atom configs and utilities.

Second, I use tmux extensively, so I've added a `tmux.conf` with a lot of
goodies like plugin support via [tpm](https://github.com/tmux-plugins/tpm).

I also added many things to the `bin/` directory, such as quick-and-dirty
single-word commands for ssh-ing to things defined in my (private)
`.ssh/config`, as well as some CUDA and OpenCV helpers.

There's also some scripts for checking one's writing for things like weasel
words, repetitions, etc. See `bin/passive.sh`, `bin/dups.pl`, and
`bin/weasel.sh`.

Apart from these major differences, there are also lots of other tiny tweaks
all over the place. Feel free to open up an issue if you're interested in
something but it doesn't seem to be working right!


## topical

Everything's built around topic areas. If you're adding a new area to your
forked dotfiles — say, "Java" — you can simply add a `java` directory and put
files in there. Anything with an extension of `.zsh` will get automatically
included into your shell. Anything with an extension of `.symlink` will get
symlinked without extension into `$HOME` when you run `script/bootstrap`.

## what's inside

A lot of stuff. Seriously, a lot of stuff. Check them out in the file browser
above and see what components may mesh up with you.
[Fork it](https://github.com/holman/dotfiles/fork), remove what you don't
use, and build on what you do use.

## components

There's a few special files in the hierarchy.

- **bin/**: Anything in `bin/` will get added to your `$PATH` and be made
  available everywhere.
- **Brewfile**: This is a list of applications for [Homebrew Cask](http://caskroom.io) to install: things like Chrome and 1Password and Adium and stuff. Might want to edit this file before running any initial setup.
- **topic/\*.zsh**: Any files ending in `.zsh` get loaded into your
  environment.
- **topic/path.zsh**: Any file named `path.zsh` is loaded first and is
  expected to setup `$PATH` or similar.
- **topic/completion.zsh**: Any file named `completion.zsh` is loaded
  last and is expected to setup autocomplete.
- **topic/install.sh**: Any file named `install.sh` is executed when you run `script/install`. To avoid being loaded automatically, its extension is `.sh`, not `.zsh`.
- **topic/\*.symlink**: Any file ending in `*.symlink` gets symlinked into
  your `$HOME`. This is so you can keep all of those versioned in your dotfiles
  but still keep those autoloaded files in your home directory. These get
  symlinked in when you run `script/bootstrap`.

## bugs

I want this to work for everyone; that means when you clone it down it should
work for you even though you may not have `rbenv` installed, for example. That
said, I do use this as *my* dotfiles, so there's a good chance I may break
something if I forget to make a check for a dependency.

If you're brand-new to the project and run into any blockers, please
[open an issue](https://github.com/holman/dotfiles/issues) on this repository
and I'd love to get it fixed for you!

## thanks

Thanks to [Zach Holman](https://github.com/holman), whose repository I
originally forked. I learned a **ton** from your repo, and still use many of
the little helpers and aliases you added to it. Thank you!
