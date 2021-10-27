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
ln -s dotfiles/dotbashrc/dircolors.ansi-universal .dircolors
```
