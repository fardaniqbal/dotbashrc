# ~/.bash_profile: executed by bash(1) for login shells.

# include .bashrc if it exists
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi
# XXX: mitigate log4j RCE exploit!
export JAVA_TOOLS_OPTIONS="-Dlog4j2.formatMsgNoLookups=true"
