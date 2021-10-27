# Fardan's ~/.bashrc
# Keep this as portable as possible so I don't have to have a different bashrc
# file for every machine I use.
profile_last=${EPOCHREALTIME/./}

# If not running interactively, don't do anything.
[[ $- == *i* ]] || return

# For profiling the bottlenecks of this script.
profile_time ()
{
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

#### MISC UTILITY FUNCTIONS ####

# Adds the given path to $PATH, unless it's already in $PATH.
path_munge ()
{
  local expr_res=$(expr ":${PATH}:" : ".*:${1}:")
  if [ $expr_res -eq 0 ]; then
    [ "$2" = "after" ] && PATH="${PATH}:${1}" || PATH="${1}:${PATH}"
  fi
}

# Like 'pwd', except it prints only the directory name, NOT the full path.
# Also, if current directory is the home directory, then it prints "~" instead
# of the home directory's actual name.
#
# !!! THIS FUNCTION IS USED BY ${PROMPT_COMMAND} !!!
pwd_short () { [ "${PWD}" = "${HOME}" ] && echo '~' || basename "${PWD}"; }

#### BEGIN BASHRC PROPER ####

# Don't put duplicate lines in the history. See bash(1) for more options.
export HISTCONTROL=ignoredups

# For setting history length see HISTSIZE and HISTFILESIZE in bash(1).
export HISTSIZE=1000
export HISTFILESIZE=2000

# Append to the history file, don't overwrite it.
shopt -s histappend

# Prevent Ctrl+D from quitting the shell.
set -o ignoreeof

# Fix typos
shopt -s cdspell

# Check the window size after each command and, if necessary, update the
# values of LINES and COLUMNS.
shopt -s checkwinsize

# File permission bits to mask out by default when creating new files.
umask 0022

# People have way to much fun with this...
mesg n

# Make less more friendly for non-text input files, see lesspipe(1).
[ -x /usr/bin/lesspipe ] && eval "$(lesspipe)"

# Enable color support for ls.
if [ "$TERM" != "dumb" ] && [ -x /usr/bin/dircolors ]; then
  if [ -f "$HOME/.dircolors" ]; then
    eval "$(dircolors -b "$HOME/.dircolors")"
  else
    # If we're going to use colors, make sure we always use xterm colors.
    temp_term=$TERM
    export TERM='xterm'
    eval "`dircolors -b`"
    export TERM=$temp_term
    unset -v temp_term
  fi
fi

# Set PS1 to "[user@host: directory]$ ", but with color escape codes based on
# the terminal type and whether or not we're root.
[ $UID -eq 0 ] && scheme=${vtredb} || scheme=${vtcya}
[ $UID -eq 0 ] && prompt='#'       || prompt='\$'
#PS1="$vtnor[$scheme\\u@\\h$vtnor: $vtblub\\W$vtnor]$scheme$prompt$vtnor "

# HACK: for some reason, escape codes in PS1 mess up Mac OS X's terminal app,
# so hackishly check if we're on a Mac here.
if [ "$OSTYPE" = "Darwin" ]; then
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
xterm*|rxvt*)
    # Set the title to show only the working directory (NOT the full path).
    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: `pwd_short`\007"'
    ;;
*)
    ;;
esac

# Add ~/bin and ~/local/bin to PATH if they exist.
for i in "${HOME}/bin" "${HOME}/local/bin"; do
    [ -d "$i" ] && path_munge "$i"
done

# Add directories under ~/local/*/bin if they exist.
for i in $(echo ~/local/*/bin | tr ' ' '\n' | sort -r); do
    [ -d "$i" ] && path_munge "$i"
done

# Bin directories under /opt.
for i in $(echo /opt/*/bin /opt/*/*/bin | tr ' ' '\n' | sort); do
    [ -d "$i" ] && path_munge "$i" after
done

# Add directories for system administration tools.
for i in /usr/local/sbin /sbin /usr/sbin; do
    [ -d "$i" ] && path_munge "$i" after
done

# Make sure ~/.inputrc gets processed.
[ -f "$HOME/.inputrc" ] && export INPUTRC="$HOME/.inputrc"

# Define your own aliases here.
[ -f ~/.bash_aliases ] && . ~/.bash_aliases

# Set up EDITOR and related variables.
if ! alias emacs >/dev/null 2>&1; then
  emacs_cmd=emacs
else
  emacs_cmd=$(alias emacs)
  emacs_cmd=${emacs_cmd#*\'}
  emacs_cmd=${emacs_cmd%\'}
fi
export EDITOR="$emacs_cmd"
export SVN_EDITOR="$emacs_cmd"
export CVSEDITOR="$emacs_cmd"
export CVS_RSH
export PATH

# Enable programmable completion features (you don't need to enable
# this if it's already enabled in /etc/bash.bashrc, and /etc/profile
# sources /etc/bash.bashrc).
# !!! MIGHT PREMATURELY EXIT, SO PUT IT AT THE END OF YOUR ~/.BASHRC !!!
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
  [ -f ~/.bash_completion ] && . ~/.bash_completion
fi
#[ -f /etc/bash_completion ] && . /etc/bash_completion
true # make exit return 0 if invoked immediately after startup (for debugging)
