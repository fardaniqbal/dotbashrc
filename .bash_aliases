# -*- shell-script -*-
# Fardan's ~/.bash_aliases
# This file should should be sourced by ~/.bashrc or ~/.bash_profile.
alias la='ls -A'
alias ll='ls -lh'
alias dir='ll'
ls_opts=''

# Make ls output colored.
if ls --color=auto /dev/null > /dev/null 2>&1; then
  # On Mac OS Monterey and later, ls accepts --color (in addition to -G),
  # but --color=auto doesn't take effect unless COLORTERM is non-empty.
  ls_opts="$ls_opts --color=auto"
elif ls -G ~/.bashrc > /dev/null 2>&1; then # bsd, mac os x
  ls_opts="$ls_opts -G"
fi

# Make ls group directories first.
if ls --group-directories-first ~/.bashrc > /dev/null 2>&1; then
  ls_opts="$ls_opts --group-directories-first"
fi
alias ls="ls $ls_opts"
unset -v ls_opts

# Do the same for gls (not a problem if gls isn't available on the system).
alias gls='gls --color=auto --group-directories-first'

alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias ln='ln -i'

alias less='less -R'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias rgrep='rgrep --color=auto'

if (unalias nvim; unset -f nvim; command -v nvim) >/dev/null 2>&1; then
  case "$OSTYPE" in
    win*|msys*|cygwin*) # Neovim breaks on Windows when bash sets SHELL.
      alias nvim='SHELL="" run-with-winpath.sh '"$(expand_alias nvim)";;
  esac
  alias vim='nvim'
fi

alias gsh='groovysh --color=true -q'
alias vi='vim'
alias octave='octave -q'  # inhibit octave startup message
alias mvndep='mvn dependency:tree -Dverbose=true'
alias tree='tree -C'

diff() {
  unset -f diff
  if diff --color=auto /dev/null /dev/null >/dev/null 2>&1; then
    alias diff='diff --color=auto'
    diff --color=auto "$@"
  else
    diff "$@"
  fi
}

# git-graph annoyingly doesn't switch to alt-screen or use $PAGER...
if (unalias git-graph; unset -f git-graph; command -v git-graph) >/dev/null 2>&1; then
  git-graph() {
    local mystyle=(--style=round)
    local mycolor=(--color=auto)
    local idx='' i='' altscrn=true skipnext=false

    # Determine if we should switch to alt screen based on args.
    for (( idx=1; idx<=$#; idx++ )); do
      if $skipnext; then skipnext=false; continue; fi
      skipnext=false
      local arg="${@:$idx:1}"
      if [[ "$arg" != '-'*  ]]; then      # positional arg
        altscrn=true; continue
      elif [[ "$arg" != '--'* ]]; then    # short options
        for (( i=1; i<${#arg}; i++ )); do
          [[   "${arg:$i:1}" =~ [rldS]     ]] && continue            # flag
          { [[ ! "${arg:$i:1}" =~ [pnmswf] ]] && altscrn=false; } || # bad opt
          { [ $((i+1)) -lt ${#arg} ]          && :;             } || # eg -oARG
          { [ $((idx+1)) -le $# ]             && skipnext=true; } || # eg -o ARG
          altscrn=false                                              # no ARG
          [ "${arg:$i:1}" = "s" ] && mystyle=()
          break
        done
        continue
      fi
      case "$arg" in  # --long option
        --path=*|--max-count=*|--model=*|--color=*|--style=*|--wrap=*|--format=*|\
        --path|--max-count|--model|--color|--style|--wrap|--format)
          { [[ "$arg" == *'='* ]] && :; }             || # --longopt=ARG
          { [ $((idx+1)) -le $# ] && skipnext=true; } || # --longopt ARG
          altscrn=false                                  # missing opt arg
          [[ "$arg" == '--style'* ]] && mystyle=()
          [[ "$arg" == '--color'* ]] && mycolor=()
          ;;
        --no-color) mycolor=();;
        --no-pager) altscrn=false;;
        --reverse|--local|--svg|--debug|--sparse|--skip-repo-owner-validation);;
        *) altscrn=false;;
      esac
    done
    [ -t 1 ] || altscrn=false
    $altscrn && [ ${#mycolor[@]} -gt 0 ] && mycolor=(--color=always)
    local myargs=("${mystyle[@]}" "${mycolor[@]}" "$@")
    if ! $altscrn; then command git-graph "${myargs[@]}"; return $?; fi
    local output= status=

    if true; then         # use external pager
      output="$(command git-graph "${myargs[@]}")"; status=$?
      [ $status -eq 0 ] && ${PAGER:-less -Ri} <<< "$output"
    else                  # use git-graph's built-in pager
      printf '\e[?1049h'  # enter alternate screen
      command git-graph "${myargs[@]}"; status=$?
      printf '\e[?1049l'  # leave alternate screen
      [ $status -eq 0 ] && return 0
      command git-graph "${myargs[@]}"  # re-run to see error message
    fi
    return $status
  }
fi

# On many systems the default 'clear' command doesn't clear the scrollback,
# so instead explicitly instruct the terminal to do exactly what we want:
#     \e[H  - move cursor to home position (0,0)
#     \e[2J - erase entire screen
#     \e[3J - erase scrollback - default 'clear' often misses this part
alias clear="printf '\e[H\e[2J\e[3J'"
alias cls='clear'

# If emacs has been set up to use a GUI window, make an alias that forces
# it to run inside the terminal.
if (command -v emacs &&
    emacs --help | grep -E $'[ \t]-nw[, \t]') > /dev/null 2>&1; then
  alias emacs='emacs -nw'
fi
alias emacsclient='emacsclient -a "" -t'
alias em='emacsclient'

#[ "$TERM" != "screen" ] && alias screen='screen -dRR'
[ "$TERM" != "screen" ] && alias screen='screen -dR'
alias tmux="tmux-select.sh"
