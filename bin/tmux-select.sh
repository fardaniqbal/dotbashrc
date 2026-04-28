#!/usr/bin/env bash
# Select a tmux session from an interactive list and attach to it.  If no
# tmux sessions are running, then just start tmux normally.  Typical way to
# use this script is to alias it to `tmux` in your shell.
#
# Requires fzf for the interactive session selector.  For instructions on
# how to install fzf, see https://github.com/junegunn/fzf.

# Run tmux normally if we have command line args.
[ $# -gt 0 ] && exec tmux "$@"

ls_fmt='#{=40:#{p40:session_name}}| #{session_windows} windows#{?session_attached, (attached),}'
sessions="$(tmux list-sessions -F "$ls_fmt" 2>/dev/null)"

# Start a new session if tmux isn't running.
[ $? -ne 0 ] && exec tmux

# Don't need user to select a session if only one session exists.
[ "$(printf '%s\n' "$sessions" | wc -l)" -eq 1 ] && exec tmux a

# If already inside a tmux session, then switch to the selected session.
[ -z "$TMUX" ] && tmux_cmd="tmux a -t" || tmux_cmd="tmux switch-client -t"

# Be helpful if fzf isn't available.
if ! (command -v fzf >/dev/null); then
  [ -n "$TMUX" ] && exec tmux choose-tree -Zs
  vtnrm=$'\033[0m'; vtcmd=$'\033[1;95m'; vtarg=$'\033[1;92m'
  printf 'The following tmux sessions are available:\n' >&2
  printf '%s\n' "$sessions" |
    sed -E "s#^(.+?)([ ]*\\|[^|]*)\$#  - $vtarg\1$vtnrm\2#" >&2
  printf '\nRun `%stmux a -t %sNAME%s` to attach to one of the above,\n' \
    $vtcmd $vtarg $vtnrm >&2
  printf 'or `%stmux new [-s %sNAME%s]%s` to start a new session.\n' \
    $vtcmd $vtarg $vtcmd $vtnrm >&2
  exit 1
fi

# Can't just pipe fzf's output into `xargs tmux` because tmux will think
# it's not in a terminal.  Instead, save fzf's output to a temp file.
tmpfile="$(mktemp -t "$(basename "$0").XXXXXX")" || exit 1
trap "rm -f \"$tmpfile\"" 0 1 2 3 15

# Fuzzy find over the session list.
printf '%s\n' "$sessions" | fzf --cycle -n1 -d'\|' --info=inline-right \
  --height=~100% --layout=reverse --border=rounded --border-label-pos=3 \
  --border-label="Select tmux session (ENTER to confirm, ESC to cancel)" \
  > "$tmpfile"

[ $? -eq 0 ] && user_cancelled=false || user_cancelled=true
selected_session="$(cat "$tmpfile" | sed -E 's/ *\|.*$//')"
rm -f "$tmpfile"

$user_cancelled || exec $tmux_cmd "$selected_session"
