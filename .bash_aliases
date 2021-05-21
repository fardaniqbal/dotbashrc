# -*- shell-script -*-
# Fardan's ~/.bash_aliases
# Last updated 2016.12.15
# This file should should be sourced by ~/.bashrc or ~/.bash_profile.

alias l='ls'
alias sl='ls'
alias la='l -A'
alias ll='l -lh'
alias dir='ll'
ls_options=''

# Make ls output colored.
if ls --color=auto ~ > /dev/null 2>&1; then
  ls_options="$ls_options --color=auto"
elif ls -G ~ > /dev/null 2>&1; then # bsd, mac os x
  ls_options="$ls_options -G"
fi

# Make ls group directories first.
if ls --group-directories-first ~ > /dev/null 2>&1; then
  # Directory grouping supported "natively".
  ls_options="$ls_options --group-directories-first"
elif /usr/bin/which lx > /dev/null 2>&1; then
  # Use the lx wrapper for directory grouping.
  alias lx='lx --color=auto'
  alias l='lx'
fi

ls_options=$(echo "$ls_options" | sed 's/^ *//' | sed 's/ *$//')
alias ls="ls $ls_options"
unset -v ls_options

alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias ln='ln -i'

alias less='less -R'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias rgrep='rgrep --color=auto'

alias gsh='groovysh --color=true -q'

alias vi='vim'
alias view='emacs -view'

# Inhibit octave startup message
if /usr/bin/which octave > /dev/null 2>&1; then
  alias octave='octave -q'
fi

# If emacs has been set up to use a GUI window, make an alias that forces it to
# run inside the terminal.
if (emacs --help | grep -E '[[:space:]]-nw[,[:space:]]') > /dev/null 2>&1; then
  alias emacs='emacs -nw'
fi
alias emacsclient='emacsclient -a "" -t'
alias em='emacsclient'

#[ "$TERM" != "screen" ] && alias screen='screen -dRR'
[ "$TERM" != "screen" ] && alias screen='screen -dR'
