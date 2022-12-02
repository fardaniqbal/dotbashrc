# -*- shell-script -*-
# Fardan's ~/.bash_aliases
# This file should should be sourced by ~/.bashrc or ~/.bash_profile.
alias la='ls -A'
alias ll='ls -lh'
alias dir='ll'
ls_opts=''

# Make ls output colored.
if ls --color=auto ~/.bashrc > /dev/null 2>&1; then
  # On Mac OS Monterey and later, ls accepts --color (in addition to -G),
  # but --color=auto doesn't take effect unless COLORTERM is non-empty.
  if [[ "$TERM" =~ (truecolor|24bit) ]]; then
    export COLORTERM=${COLORTERM:-${SSH_CLIENT_COLORTERM:-truecolor}}
  else
    export COLORTERM=${COLORTERM:-${SSH_CLIENT_COLORTERM:-yes}}
  fi
  ls_opts="$ls_opts --color=auto"
elif ls -G ~/.bashrc > /dev/null 2>&1; then # bsd, mac os x
  ls_opts="$ls_opts -G"
fi

# Make ls group directories first.
if ls --group-directories-first ~/.bashrc > /dev/null 2>&1; then
  # Directory grouping supported "natively".
  ls_opts="$ls_opts --group-directories-first"
elif [ -x ~/local/bin/lx ]; then
  # Use the lx wrapper for directory grouping.
  alias lx='lx --color=auto'
fi

# Trim whitespace from $ls_opts.
while [ x"${ls_opts# }" != x"$ls_opts" ]; do ls_opts=${ls_opts# }; done
while [ x"${ls_opts% }" != x"$ls_opts" ]; do ls_opts=${ls_opts% }; done
alias ls="ls $ls_opts"
unset -v ls_opts

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
alias octave='octave -q'  # inhibit octave startup message
alias tree='tree -C'

# If emacs has been set up to use a GUI window, make an alias that forces
# it to run inside the terminal.
if (emacs --help | grep -E '[[:space:]]-nw[,[:space:]]') > /dev/null 2>&1; then
  alias emacs='emacs -nw'
fi
alias emacsclient='emacsclient -a "" -t'
alias em='emacsclient'

#[ "$TERM" != "screen" ] && alias screen='screen -dRR'
[ "$TERM" != "screen" ] && alias screen='screen -dR'
