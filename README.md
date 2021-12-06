Repo for my personal .bashrc file and related files (.bash_aliases,
etc).  Several years of accumulated cruft so don't take this as an
example.

To use, clone this repo into something like `~/dotfiles/dotbashrc` and
symlink files in your home directory to the corresponding files here:

```bash
mkdir ~/dotfiles
cd ~/dotfiles
git clone git://github.com/fardaniqbal/dotbashrc.git
cd
ln -s dotfiles/dotbashrc/.bashrc .bashrc
ln -s dotfiles/dotbashrc/.bash_aliases .bash_aliases
...etc...
```

Symlink `~/.dircolors` to _one_ of the dircolors files in this repo.
For example:

```bash
ln -s dotfiles/dotbashrc/dircolors/solarized.ansi-universal .dircolors
```

## See also

* My personal [`.inputrc`](inputrc): controls how bash interprets user
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
