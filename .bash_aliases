# -*- shell-script -*-
# Fardan's ~/.bash_aliases
# Last updated 2016.12.15
# This file should should be sourced by ~/.bashrc or ~/.bash_profile.

alias l='ls'
alias sl='ls'
alias la='l -A'
alias ll='l -lh'
alias dir='ll'
ls_opts=''

# Make ls output colored.
if ls --color=auto ~/.bashrc > /dev/null 2>&1; then
  ls_opts="$ls_opts --color=auto"
elif ls -G ~/.bashrc > /dev/null 2>&1; then # bsd, mac os x
  ls_opts="$ls_opts -G"
fi

profile_time "- end ls color options"

# Make ls group directories first.
if ls --group-directories-first ~/.bashrc > /dev/null 2>&1; then
  # Directory grouping supported "natively".
  ls_opts="$ls_opts --group-directories-first"
elif [ -x ~/local/bin/lx ]; then
  # Use the lx wrapper for directory grouping.
  alias lx='lx --color=auto'
  alias l='lx'
fi

profile_time "- end ls directory grouping options"

# Trim whitespace from $ls_opts.
while [ "${ls_opts# }" != "$ls_opts" ]; do ls_opts=${ls_opts# }; done
while [ "${ls_opts% }" != "$ls_opts" ]; do ls_opts=${ls_opts% }; done
profile_time "- end \$ls_opts cleanup"
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
alias view='emacs -view'

profile_time "- end basic aliases"

# Inhibit octave startup message
if /usr/bin/which octave > /dev/null 2>&1; then
  alias octave='octave -q'
fi

profile_time "- end octave alias"

# If emacs has been set up to use a GUI window, make an alias that forces it to
# run inside the terminal.
if (emacs --help | grep -E '[[:space:]]-nw[,[:space:]]') > /dev/null 2>&1; then
  alias emacs='emacs -nw'
fi
profile_time "- end emacs -nw alias"
alias emacsclient='emacsclient -a "" -t'
alias em='emacsclient'

profile_time "- end emacsclient alias"

#[ "$TERM" != "screen" ] && alias screen='screen -dRR'
[ "$TERM" != "screen" ] && alias screen='screen -dR'

profile_time "- end screen alias"
