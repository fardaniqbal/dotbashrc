Repo for my personal .bashrc file and related files (.bash_aliases,
etc).  Several years of accumulated cruft so don't take this as an
example.

## Installation

Recursively clone this repo into something like `~/dotfiles/dotbashrc`, and
symlink the dotfiles to the corresponding files in your home directory:

```bash
mkdir -p ~/dotfiles
cd ~/dotfiles
git clone --recurse-submodules https://github.com/fardaniqbal/dotbashrc
# Or git clone --recurse-submodules git@github.com:fardaniqbal/dotbashrc.git
# to clone through ssh.

ln -s dotfiles/dotbashrc/.bashrc ~/.bashrc
ln -s dotfiles/dotbashrc/.bash_profile ~/.bash_profile
```

Optionally, if you're using GNU `ls` but you don't like the colors it uses
by default, then you can symlink _one_ of the files in this repo's
`dircolors` directory to `~/.dircolors`.  For example:

```bash
ln -s dotfiles/dotbashrc/dircolors/solarized.ansi-universal ~/.dircolors
```

## See also

* My personal [`.inputrc`][inputrc]: controls how bash interprets user
  input (e.g., emacs-vs-vi key bindings, case-(in-)sensitive completion,
  etc).  Although this file is obviously relevant to bash's UX, I keep it
  in a seperate repo because it affects the UX of _all_ programs that use
  the `readline` library, including but not limited to bash.

[inputrc]: https://github.com/fardaniqbal/dotmisc/blob/master/.inputrc

## Copying

This repo may contain (or have submodules of) 3rd-party content.  The
copyrights of said 3rd-party content belong to their respective authors,
and their licenses can be found in their containing subdirectories or
source files.  Unless mentioned otherwise, my ([Fardan
Iqbal's](https://github.com/fardaniqbal)) own content in this repo is
public domain.
