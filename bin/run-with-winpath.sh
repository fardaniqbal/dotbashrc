#!/bin/bash

if [ $# -eq 0 ]; then
  printf "Usage: %s COMMAND [ARG...]\n" "$(basename "$0")" >&2
  printf "\n" >&2
  printf "Run COMMAND with each file/path ARG converted to Windows-\n" >&2
  printf "style path using \`readlink\` and \`cygpath -w\`.  This is\n" >&2
  printf "intended to be used on Windows under Git Bash or MSYS2 for\n" >&2
  printf "COMMANDs that expect their args to be Windows-style paths.\n" >&2
  printf "\n" >&2
  printf "Example: if \$USERPROFILE/.bashrc is symlinked to\n" >&2
  printf "\$USERPROFILE/dotfiles/dotbashrc/.bashrc, then running\n" >&2
  printf "    %s nvim ~/.bashrc\n" "$(basename "$0")" >&2
  printf "will invoke\n" >&2
  printf "    nvim %s\n" "$USERPROFILE\\dotfiles\\.bashrc" >&2
  printf "\n" >&2
  printf "ARGs that _do not_ refer to files will be passed to\n" >&2
  printf "COMMAND as-is.\n" >&2
  exit 2
fi

command="$1"
shift

args=()
for i in "$@"; do
  if [ -r "$i" ]; then
    args+=("$(cygpath -w -- "$(readlink -f -- "$i")")")
  else
    args+=("$i")
  fi
done

exec "$command" "${args[@]}"
