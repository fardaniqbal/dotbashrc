# Fardan's ~/.bashrc
# Keep this as portable as possible so I don't have to have a different
# bashrc file for every machine I use.
profile_last=${EPOCHREALTIME/./}

# If not running interactively, don't do anything.
[[ $- == *i* ]] || return

# For profiling the bottlenecks of this script.
profile_time() {
  local now=${EPOCHREALTIME/./}
  [ -z "$profile_last" ] && profile_last=$now && return
  printf -- '%5d ms %s\n' $((($now - $profile_last) / 1000)) "$1"
  profile_last=$now
}

#### MISC DEFS ####

# VT normal color codes
vtnor='\033[00m';     vtblk='\033[00;30m';  vtred='\033[00;31m'
vtgrn='\033[00;32m';  vtyel='\033[00;33m';  vtblu='\033[00;34m'
vtprp='\033[00;35m';  vtcya='\033[00;36m';  vtwht='\033[00;37m'

# VT bold colors codes
vtnorb='\033[01m';    vtblkb='\033[01;30m'; vtredb='\033[01;31m'
vtgrnb='\033[01;32m'; vtyelb='\033[01;33m'; vtblub='\033[01;34m'
vtprpb='\033[01;35m'; vtcyab='\033[01;36m'; vtwhtb='\033[01;37m'

#### ENV INIT: set env vars, options, etc that affect everying else ####

# Git Bash doesn't set $USER, so use a custom variable here instead.  See
# [this answer](https://stackoverflow.com/a/23931327) for why we use `id`.
[ -n "$USER" ] && my_user="$USER" || my_user="$(id -u -n)"

urlencode() {
  while read byte; do
    local chr=$(xxd -r -p <<< "$byte")
    [ -z "$chr" ] && break
    [[ "$chr" == [A-Za-z0-9.~_-] ]] && printf "$chr" || printf "%%$byte"
  done <<< "$(xxd -p -c 1 <<< "$1")"
}

urldecode() { local tmp="${1//+/ }"; printf -- '%b' "${tmp//%/\\x}"; }

# SSH ENV HACK: when we ssh into a remote host, there's no standard way to
# pass arbitrary env vars to that host without root access to it.  However,
# ssh _does_ pass the TERM env var to the host by default.  We can exploit
# this to pass other env vars to the ssh host:
# 1. On the client, encode env vars into TERM right before running the ssh
#    client (URL-style, e.g. TERM="xterm?SSH_VAR_1=foo&SSH_VAR_2=bar".)
# 2. On the host, decode the env vars out of TERM in the host's bashrc.
decode_env_from_TERM() {
  local bare_term=${TERM%%\?*}
  local var_string=${TERM:$((${#bare_term} + 1))}
  export TERM=$bare_term
  IFS='&' read -r -a var_array <<< "$var_string"
  for var in "${var_array[@]}"; do
    local var_name=${var%%=*}
    export "$var_name=$(urldecode "${var/#$var_name=}")"
  done
}
decode_env_from_TERM

# Call this before running ssh to encode ssh-related env vars into TERM.
# Example usage: alias ssh='TERM=$(encode_env_into_TERM) ssh'.
encode_env_into_TERM() {
  local result=$TERM sep='?'
  while read var; do
    [[ "$var" == SSH_CLIENT_* ]] || continue
    local var_name=${var%%=*}
    result="$result$sep$var_name=$(urlencode "${var/#$var_name=}")"
    sep='&'
  done <<< "$(/usr/bin/env)"
  printf -- "%s\n" "$result"
}

ssh_envhack_wrapper() {
  SSH_CLIENT_OSTYPE=${SSH_CLIENT_OSTYPE:-$OSTYPE} \
  SSH_CLIENT_COLORTERM=${SSH_CLIENT_COLORTERM:-$COLORTERM} \
  SSH_CLIENT_TERM_PROGRAM=${SSH_CLIENT_TERM_PROGRAM:-$TERM_PROGRAM} \
  TERM=$(encode_env_into_TERM) ssh "$@"
}
alias ssh='ssh_envhack_wrapper'

#### MISC UTILITY FUNCTIONS ####

# Adds the given path to $PATH, unless it's already in $PATH.
path_pre_munge()  { [[ ":${PATH}:" == *":$1:"* ]] || PATH="$1:${PATH}"; }
path_post_munge() { [[ ":${PATH}:" == *":$1:"* ]] || PATH="${PATH}:$1"; }

path_munge() {
  local sort_flag= do_sort=false munge_func=path_pre_munge
  while [[ "$1" == -* ]]; do
    [ "$1" = "--after"   ] && munge_func=path_post_munge
    [ "$1" = "--sort"    ] && do_sort=true
    [ "$1" = "--revsort" ] && do_sort=true sort_flag=-r
    shift
  done
  local dirs="$(printf '%s\n' "$@")"
  $do_sort && dirs="$(printf '%s\n' "$@" | sort $sort_flag)"
  while read i; do [ -d "$i" ] && $munge_func "$i"; done <<< "$dirs"
}

# Output the bottom-level command to which the arg(s) are aliased.  E.g.,
# if `ll` is aliased to `ls -lh` and `ls` is aliased to `ls -G`, then
# `expand_alias ll -A` will output `ls -G -lh -A`.
expand_alias() {
  firstarg() { printf "%s" "$1"; }
  restargs() { shift; printf "%s" "$*"; }
  local cmd=$(firstarg $@) cmd_prev="" args=$(restargs $@)
  while alias "$cmd" >/dev/null 2>&1 && [ "$cmd" != "$cmd_prev" ]; do
    cmd_prev=$cmd
    cmd=$(alias "$cmd")
    cmd=${cmd#*\'}
    cmd=${cmd%\'}
    args="$(restargs $cmd) $args"
    cmd=$(firstarg $cmd)
  done
  printf "%s\n" "$cmd $args" | sed 's/ *$//' # trim trailing spaces
}

#### BEGIN BASHRC PROPER ####

export HISTCONTROL=ignoredups # don't put duplicate lines in history
export HISTSIZE=1000
export HISTFILESIZE=2000

shopt -s histappend   # append to history file, don't overwrite it
set -o ignoreeof      # prevent Ctrl+D from quitting the shell
shopt -s cdspell      # fix typos
shopt -s checkwinsize # update $LINES and $COLUMNS on window resize
umask 0022            # mask out these permission bits when creating files
mesg n                # people have way too much fun with this...

# Make less more friendly for non-text input files, see lesspipe(1).
[ -x /usr/bin/lesspipe ] && eval "$(lesspipe)"

# Enable color support for ls.
if [ "$TERM" != "dumb" ] && (which dircolors >/dev/null 2>&1); then
  if [ -f "$HOME/.dircolors" ]; then
    eval "$(dircolors -b "$HOME/.dircolors")"
  else
    TERM='xterm' eval "`dircolors -b`" # use xterm colors if no custom db
  fi
fi

# Set PS1 to "[user@host: directory]$ ", but with color escape codes based
# on the terminal type and whether or not we're root.
[ $UID -eq 0 ] && scheme=${vtredb} || scheme=${vtcya}
[ $UID -eq 0 ] && prompt='#'       || prompt='\$'

if [ "$OSTYPE" = "Darwin" ]; then
  # Escape codes in PS1 mess up the terminal on older versions of Mac OS X.
  PS1="[\\u@\\h: \\W]$prompt "
else
  # Most terminals want escape codes in PS1 to be surrounded by \[ and \].
  [ "$TERM" != "dumb" ] && eb='\[' ee='\]'
  PS1="$eb$vtnor$ee[$eb$scheme$ee\\u@\\h$eb$vtnor$ee"
  PS1="$PS1: $eb$vtblub$ee\\W$eb$vtnor$ee]$eb$scheme$ee$prompt$eb$vtnor$ee "
fi
unset -v scheme prompt eb ee

# If this is an xterm or rxvt set the window title.
case "${TERM}" in
xterm*|rxvt*) # make window title show current dir's basename
  PROMPT_COMMAND='
    [ "$PWD" = "$HOME" ] && ps1_pwd="~" || ps1_pwd="${PWD##*/}"
    echo -ne "\033]0;$my_user@$HOSTNAME: $ps1_pwd\007"'
  ;;
esac

path_munge --sort ~/local/*/bin
path_munge "${HOME}/bin" "${HOME}/local/bin"
path_munge --after --revsort /opt/*/bin /opt/*/*/bin
path_munge --after /usr/local/sbin /usr/sbin /sbin

# Make sure ~/.inputrc gets processed.
[ -f "$HOME/.inputrc" ] && export INPUTRC="$HOME/.inputrc"

# Define your own aliases here.
[ -f ~/.bash_aliases ] && . ~/.bash_aliases

# Set up EDITOR and related variables.
export EDITOR="$(expand_alias vim)"
export SVN_EDITOR="$EDITOR"
export CVSEDITOR="$EDITOR"
export GIT_SEQUENCE_EDITOR="$EDITOR"
export CVS_RSH
export PATH
export JAVA_TOOLS_OPTIONS="-Dlog4j2.formatMsgNoLookups=true" # log4j vuln.

# Colorize man pages.
export LESS_TERMCAP_mb=$'\e[0;31m'      # begin bold
export LESS_TERMCAP_md=$'\e[0;32m'      # begin blink
export LESS_TERMCAP_so=$'\e[0;42;30m'   # begin standout colors
export LESS_TERMCAP_us=$'\e[0;36m'      # begin underline
export LESS_TERMCAP_me=$'\e[0m'         # end bold/blink
export LESS_TERMCAP_se=$'\e[0m'         # end standout colors
export LESS_TERMCAP_ue=$'\e[0m'         # end underline
export GROFF_NO_SGR=1   # for compatibility with some terminal emulators

# Host-specific settings.
[ -f ~/.bashrc.local ] && . ~/.bashrc.local

# Enable programmable completion features (you don't need to enable
# this if it's already enabled in /etc/bash.bashrc, and /etc/profile
# sources /etc/bash.bashrc).
# !!! MIGHT PREMATURELY EXIT, SO PUT IT AT THE END OF YOUR ~/.BASHRC !!!
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  elif [ -f /usr/local/etc/bash_completion ]; then
    . /usr/local/etc/bash_completion
  fi
  [ -f ~/.bash_completion ] && . ~/.bash_completion
fi
#[ -f /etc/bash_completion ] && . /etc/bash_completion
true # make exit code be 0 (for debugging this script)
