# Fardan's ~/.bashrc
# Keep this as portable as possible so I don't have to have a different bashrc
# file for every machine I use.
profile_last=${EPOCHREALTIME/./}

# If not running interactively, don't do anything.
case $- in
  *i*) ;;
  *) return ;;
esac

# For profiling the bottlenecks of this script.
profile_time ()
{\
  local now=${EPOCHREALTIME/./}
  [ -z "$profile_last" ] && profile_last=$now && return

  printf -- '%5d ms %s\n' $((($now - $profile_last) / 1000)) "$1"
  profile_last=$now
}
#profile_time
profile_time "defined profile_time()"

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
    if ! echo ":${PATH}:" | (/bin/grep -F ":${1}:" &>/dev/null); then
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

# Make less more friendly for non-text input files, see lesspipe(1).
[ -x /usr/bin/lesspipe ] && eval "$(lesspipe)"

# Determine which host I'm logged on to, and set misc host-dependent things.
if [ "`echo \"${HOSTNAME}\" | sed 's/.*\\.rlogin\|.*\\.cslab\$/vtcslab/'`" = "vtcslab" ]; then
    # If we are logged into a VT CS lab machine.
    umask 0066
    alias gterm='/home/ugrads/f/fiqbal/bin/gterm'
    alias which='alias | /usr/bin/which --tty-only --read-alias --show-dot --show-tilde'
    CVS_RSH="/usr/bin/ssh"
    path_munge "${HOME}/code/cs3204/bin" after
    mesg n  # People have way too much fun with this at the VT CS labs...
fi

# Enable color support for ls.
if [ "$TERM" != "dumb" ] && [ -x /usr/bin/dircolors ]; then
    # If we're going to use colors, make sure we always use xterm colors.
    temp_term=$TERM
    export TERM='xterm'
    eval "`dircolors -b`"
    export TERM=$temp_term
    unset -v temp_term
fi

# Set PS1 to "[user@host: directory]$ ", but with color escape codes based on
# the terminal type and whether or not we're root.
[ "`id -ru`" -eq 0 ] && scheme=${vtredb} || scheme=${vtcya}
[ "`id -ru`" -eq 0 ] && prompt='#'       || prompt='\$'
PS1="$vtnor[$scheme\\u@\\h$vtnor: $vtblub\\W$vtnor]$scheme$prompt$vtnor "
unset -v scheme prompt

# Most terminals want escape codes in PS1 to be surrounded by \[ and \].
if [ "${TERM}" != "dumb" ]; then
    # ASCII character between '@' and '~', inclusive, terminate escape
    # sequences.  That is, these characters: ][@A-Za-z^_`{|}~\
    endc=']\[@A-Za-z^_`{|}~'
    PS1=$(echo -n "$PS1" | sed 's,\\[0-9]\+\[[^'$endc']*['$endc'],\\[&\\],g')
    unset -v endc

   # HACK: for some reason, using the above escape codes in PS1 messes up Mac
   # OS X's terminal app, so hackishly check if we're on a Mac here.
    if [ "$(uname -s)" = "Darwin" ]; then
        txtblu_bold="$(tput setaf 12)"
        txtcyn="$(tput setaf 6)"
        txtrst="$(tput sgr0)"
        unset -v txtblu_bold txtcyn txtrst # or just don't use colors at all...
        PS1="$txtrst[$txtcyn\\u@\\h$txtrst: $txtblu_bold\\W$txtrst]$txtcyn\$$txtrst "
        unset -v txtblu_bold txtcyn txtrst
    fi
fi

# If this is an xterm or rxvt set the window title.
case "${TERM}" in
xterm*|rxvt*)
    # Set the title to show only the working directory (NOT the full path).
    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: `pwd_short`\007"'
    ;;
*)
    ;;
esac

profile_time "begin path munge"
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

profile_time "end path munge"

# If we want EDITOR, SVN_EDITOR, etc to be emacs, make sure we use
# terminal -mode emacs.  !!! Significantly slows down bash startup !!!
#if (emacs --help | grep -E '[[:space:]]-nw[,[:space:]]') > /dev/null 2>&1; then
#  emacs_nw_flag='-nw'
#else
#  emacs_nw_flag=''
#fi

profile_time "end emacs -nw setup"

export EDITOR="emacs $emacs_nw_flag"
export SVN_EDITOR="emacs $emacs_nw_flag"
export CVSEDITOR="emacs $emacs_nw_flag"
export CVS_RSH
export PATH

profile_time "end EDITOR setup"

# Make sure ~/.inputrc gets processed.
[ -f "$HOME/.inputrc" ] && export INPUTRC="$HOME/.inputrc"

profile_time "end INPUTRC setup"

# Define your own aliases here.
[ -f ~/.bash_aliases ] && . ~/.bash_aliases

profile_time "end .bash_aliases parsing"

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
profile_time "end bash completion parsing"
