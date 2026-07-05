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

# Assume we have nerd font and truecolor terminal if on local machine.  If
# ssh'd into a remote host, pass these env vars through our ssh wrapper.
if [ -z "$SSH_TTY" ]; then
  export NERDFONTS=true NERD_FONT=1 COLORTERM=truecolor
elif [[ "$TERM" =~ (truecolor|24bit) ]]; then
  export COLORTERM=truecolor
else
  export COLORTERM=${COLORTERM:-${SSH_CLIENT_COLORTERM:-yes}}
fi

#### ENV INIT: set env vars, options, etc that affect everying else ####

# Try to create real symlinks if we're on MSYS/MinGW/etc.  NOTE: to create
# real symlinks, we must either be admin, or the developer-mode setting to
# allow non-admins to create symlinks must be enabled.  NOTE 2: we detect
# Windows by checking common Windows env vars instead of `uname` because,
# even though `uname` is more accurate, it's also yet another thing that
# slows down bash startup.
if [ -n "$WINDIR$USERPROFILE$PROGRAMFILES" ]; then
  export MSYS='winsymlinks:nativestrict'
fi

# Git Bash doesn't set $USER, so use a custom variable here instead.  See
# [this answer](https://stackoverflow.com/a/23931327) for why we use `id`.
[ -n "$USER" ] && bashrc_user="$USER" || bashrc_user="$(id -u -n)"

# SSH ENV HACK: with ssh, there's no standard way to pass arbitrary env
# vars to the remote host without root access to it.  A workaround is to
# tell ssh to run a command on the host that sets the env vars we want,
# then explicitly run a login shell:
#
#     ssh -t HOST "/bin/sh -c 'export FOO=asdf; export BAR=fdsa; bash -l'"
#
# This function does this automatically for select environment variables.
ssh_envhack_wrapper() {
  # Must duplicate ssh's arg parsing logic to keep ssh's expected behavior.
  local flags=() dst='' cmds=()
  while [ $# -gt 0 ]; do
    if [ ${#cmds} -gt 0 ]; then
      cmds+=( "$1" ); shift; continue
    fi
    case "$1" in
      # NOTE: ssh does NOT treat "--" specially.
      -*)
        for (( i=1; i<${#1}; i++ )); do
          flags+=( "-${1:$i:1}" )
          [[ "${1:$i:1}" =~ [BbcDEeFIiJLlmOoPpQRSWw] ]] || continue
          if [ $((i + 1)) -lt "${#1}" ]; then
            flags+=( "${1:$((i + 1))}" )  # e.g. -oARG
          elif [ $# -gt 1 ]; then
            shift; flags+=( "$1" )        # e.g. -o ARG
          fi
          break
        done
        ;;
      *) [ -z "$dst" ] && dst="$1" || cmds+=( "$1" );;
    esac
    shift
  done

  # Run ssh normally if dst was unspecified or commands were given.
  if [ -z "$dst" ]; then
    [ ${#cmds} -eq 0 ] || echo '!!! BUG !!!' >&2
    command ssh "${flags[@]}"
    return $?
  elif [ ${#cmds} -gt 0 ]; then
    command ssh "${flags[@]}" "$dst" "${cmds[@]}"
    return $?
  fi

  # Build export command to pass select env vars to remote host.
  local var='' exports='true'
  for var in COLORTERM TERM_PROGRAM MY_SSH_TEST_VAR NERDFONTS NERD_FONT TMUX; do
    local val="${!var}"
    # Escape quotes.  Note that older bash versions (Mac OS) don't support
    # ${var//foo/bar} syntax, so use sed.
    val="$(sed 's|'\''|'\'\"\'\"\''|g' <<<  "$val")"
    exports="$exports; export $var='$val'"
  done

  # Carry this function itself over to the remote login shell.  Credit to
  # [backpack](https://github.com/sineemore/backpack/) for inspiration.
  local self_src="$(declare -f "${FUNCNAME[0]}")"
  command -v base64 >/dev/null 2>&1 &&
    local self_src_enc="$(base64 <<< "$self_src" | tr -d $'\n')" ||
    local self_src_enc="$(openssl base64 -A <<< "$self_src")"
  local remote_cmd="$(cat <<EOF
    exec "\$BASH" --rcfile <(
      cat <<'INTERNAL_EOF'
      $exports
      # Source same files that bash --login is documented to source.
      [ -f /etc/profile ] && . /etc/profile
      for _rcfile in ~/.bash_profile ~/.bash_login ~/.profile; do
        if [ -f "\$_rcfile" ]; then . "\$_rcfile"; break; fi
      done
      unset -v _rcfile

      # XXX: to replace characters with a newline in POSIX/Solaris/BSD sed,
      # specify the replacement as a backslash followed by literal newline.
      command -v base64 >/dev/null 2>&1 &&
        _decode() { sed 's|.\\{64\\}|&\\'\$'\\n|g' | base64 -d; } ||
        _decode() { sed 's|.\\{64\\}|&\\'\$'\\n|g' | openssl base64 -d; }
      eval "\$(_decode <<< "$self_src_enc")"
      unset -f _decode
      $exports
      alias ssh="${FUNCNAME[0]}"
INTERNAL_EOF
    ) -i ||
    # exec failed; try fallbacks...
    [ -x "\$SHELL" ] && exec "\$SHELL" -l
    exec /bin/sh -i
EOF
  )"
  # Escape again for ssh.  Avoid ${foo//bar/baz} syntax for compatibility.
  remote_cmd="$(sed 's|'\''|'\'\"\'\"\''|g' <<<  "$remote_cmd")"
  [ -t 0 ] && [ -t 1 ] && [ -t 2 ] && flags+=( '-t' )
  command ssh "${flags[@]}" "$dst" "\"\`which bash\`\" -c '$remote_cmd'"
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
  expand_firstarg_() { printf "%s" "$1"; }
  expand_restargs_() { shift; printf "%s" "$*"; }
  local cmd=$(expand_firstarg_ $@) cmd_prev="" args=$(expand_restargs_ $@)
  while alias "${cmd%%=*}" >/dev/null 2>&1 && [ "$cmd" != "$cmd_prev" ]; do
    cmd_prev=$cmd
    cmd=$(alias "$cmd")
    cmd=${cmd#*\'}
    cmd=${cmd%\'}
    args="$(expand_restargs_ $cmd) $args"
    cmd=$(expand_firstarg_ $cmd)
  done
  cmd="$cmd $args"
  printf "%s\n" "${cmd%"${cmd##*[^[:space:]]}"}" # trim trailing spaces
}

# Follow symlink $1 until it points to a non-symlink.
follow_symlinks() {
  if type realpath >/dev/null 2>&1; then realpath -- "$1"; return; fi
  if type readlink >/dev/null 2>&1; then readlink -f -- "$1"; return; fi

  # Native tools aren't available, so do it the slow way.
  local dir="$(cd "$(dirname "$1")" && pwd)"
  if [ $? -ne 0 ]; then printf '%s\n' "$1"; return; fi
  local file="$dir/$(basename "$1")"
  local max_count=100
  while [ -L "$file" ] && [ $max_count -gt 0 ]; do
    file="$(ls -lad "$file")"
    file="${file#*-> }"
    dir="$(cd "$(dirname "$file")" && pwd)"
    if [ $? -ne 0 ]; then printf '%s\n' "$file"; return; fi
    file="$dir/$(basename "$file")"
    max_count=$(($max_count - 1))
  done
  printf '%s\n' "$file"
}
bashrc_dir="$(dirname "$(follow_symlinks "$BASH_SOURCE")")"

# Run make and colorize its output if stdout/stderr are terminals.
colormake() {
  # Run make the normal way if we're not outputting to a terminal.
  [ "x$MAKE" = "x" ] && MAKE=make
  if [ ! -t 1 ] || [ ! -t 2 ]; then "$MAKE" "$@"; return $?; fi

  # Force compiler to color errors/warnings if supported.
  echo | cc -Werror -fdiagnostics-color -o /dev/null -c -E - 2>/dev/null &&
    local colorflag='-fdiagnostics-color' || local colorflag=''
  type 'gsed' >/dev/null 2>&1 && local SED='gsed' || local SED='sed'

  local info="$(echo -e '\033[01;35m')"
  local warn="$(echo -e '\033[01;33m')"
  local err="$(echo  -e '\033[01;31m')"
  local out="$(echo  -e '\033[00;36m')"
  local nor="$(echo  -e '\033[00m')"
  CFLAGS="$CFLAGS $colorflag"     \
  CXXFLAGS="$CXXFLAGS $colorflag" \
  CCFLAGS="$CCFLAGS $colorflag"   \
  CPPFLAGS="$CPPFLAGS $colorflag" \
  "$MAKE" "$@" 2>&1 | "$SED" -E   \
    -e $'s,([ \t]-o[ \t]*[^ \t]+),'$out'\1'$nor',g' \
    -e $'s,(>>?[^>]+)$,'$out'\1'$nor',g'            \
    -e $'s,^[^:]+:.*[Ee]rror.*,'$err'&'$nor','      \
    -e $'s,^[^:]+:.*[Ww]arn.*,'$warn'&'$nor','      \
    -e $'s,^[^:\033]*make[^:]*:,'$info'&'$nor','
  return ${PIPESTATUS[0]}
}
alias make='colormake'

#### BEGIN BASHRC PROPER ####

export HISTCONTROL=ignoredups # don't put duplicate lines in history
export HISTSIZE=1000
export HISTFILESIZE=2000

shopt -s histappend   # append to history file, don't overwrite it
set -o ignoreeof      # prevent Ctrl+D from quitting the shell
shopt -s cdspell      # fix typos
shopt -s checkwinsize # update $LINES and $COLUMNS on window resize
umask 0022            # mask out these permission bits when creating files
mesg n 2>/dev/null    # people have way too much fun with this...

# Make less more friendly for non-text input files, see lesspipe(1).
[ -x /usr/bin/lesspipe ] && eval "$(lesspipe)"

# Enable color support for ls.
if [ "$TERM" != "dumb" ] && (type dircolors >/dev/null 2>&1); then
  if ! [ -f "$HOME/.dircolors" ]; then
    # If no custom db, generate one based on default xterm dircolors.
    _dircolors=$(TERM=xterm-256color dircolors -p)
    _dircolors=${_dircolors//4[0-7];/40;} # remove hard-to-read bg colors
    _dircolors=${_dircolors//;4[0-7]/;40}
    printf '%s\n' "$_dircolors" > "$HOME/.dircolors"
    unset -v _dircolors
  fi
  eval "$(dircolors -b "$HOME/.dircolors")"
fi

# Set PS1 to "[user@host: directory]$ ", but with color escape codes based
# on the terminal type and whether or not we're root.
[ $UID -eq 0 ] && scheme=${vtredb} || scheme=${vtcya}
[ $UID -eq 0 ] && prompt='#'       || prompt='\$'
[[ "$OSTYPE" == *solaris* ]]       && scheme=${vtprp}

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
xterm*|rxvt*|screen*|tmux*)
  # make window title show current dir's basename
  # !!! subprocesses in PROMPT_COMMAND are expensive !!!
  PROMPT_COMMAND='
    [ "$PWD" = "$HOME" ] && bashrc_pwd="~" || bashrc_pwd="${PWD##*/}"
    echo -ne "\033]0;$bashrc_user@$HOSTNAME: $bashrc_pwd\007"'
  ;;
*) PROMPT_COMMAND=':'   # noop on unknown $TERM (prevents error on prompt)
  ;;
esac

# Print message $1 if previous command's output didn't have a trailing
# newline.  Implementation based on https://stackoverflow.com/a/20156527.
_prompt_check_eol() {
  local row col
  stty -echo                        # disable echoing
  echo -ne '\033[6n'                # control code to get cursor pos
  IFS='[;' read -s -d R _ row col   # read cursor pos into $row and $col
  stty echo                         # reenable echoing
  ((col > 1)) && (echo; echo -e "$eb$vtredb$ee$1$eb$vtnor$ee")
}
PROMPT_COMMAND="$PROMPT_COMMAND;
  _prompt_check_eol '(no newline at end of output)'"

# Include Homebrew's PATH additions before sourcing .bash_aliases.
[ -x /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"
#path_munge /usr/local/bin
path_munge "$HOME/.local/bin"
path_munge --sort ~/local/*/bin
path_munge "$HOME/bin" "$HOME/local/bin"
path_munge --after --revsort /opt/*/bin /opt/*/*/bin
path_munge --after /usr/local/sbin /usr/sbin /sbin
path_munge --after "$bashrc_dir/bin"
export PATH

# Make sure ~/.inputrc gets processed.
[ -f "$HOME/.inputrc" ] && export INPUTRC="$HOME/.inputrc"

# Define your own aliases here.
[ -f "$bashrc_dir/.bash_aliases" ] && . "$bashrc_dir/.bash_aliases"

# Set up EDITOR and related variables.
export EDITOR="$(expand_alias vim)"
export SVN_EDITOR="$EDITOR"
export CVSEDITOR="$EDITOR"
export GIT_SEQUENCE_EDITOR="$EDITOR"
export CVS_RSH
export JAVA_TOOLS_OPTIONS="-Dlog4j2.formatMsgNoLookups=true" # log4j vuln.
export NPM_PACKAGES="$HOME/local/npm-packages"

# Colorize man pages.
[ -n "$PAGER" ] || export PAGER="$(expand_alias less)"
export LESS_TERMCAP_mb=$'\e[01;31m'     # begin bold
export LESS_TERMCAP_md=$'\e[01;33m'     # begin blink
export LESS_TERMCAP_so=$'\e[01;42;30m'  # begin standout colors
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
  [ -f "$bashrc_dir/.bash_completion" ] && . "$bashrc_dir/.bash_completion"
fi
#[ -f /etc/bash_completion ] && . /etc/bash_completion

# THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="${SDKMAN_DIR:-"$HOME/.sdkman"}"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
