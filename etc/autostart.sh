#!/usr/bin/env bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version       : 021320212341-git
# @Author        : Jason Hempstead
# @Contact       : jason@casjaysdev.pro
# @License       : WTFPL
# @ReadME        : autostart.sh --help
# @Copyright     : Copyright: (c) 2021 Jason Hempstead, CasjaysDev
# @Created       : Saturday, Feb 13, 2021 23:41 EST
# @File          : autostart.sh
# @Description   : autostart script for qtile
# @TODO          :
# @Other         :
# @Resource      :
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
PROG="autostart.sh"
USER="${SUDO_USER:-$USER}"
HOME="${USER_HOME:-$HOME}"
PATH="$HOME/.local/bin:$PATH"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#set opts
# set desktop session
DESKTOP_SESSION="${DESKTOP_SESSION:-qtile}"
# set config dir
DESKTOP_SESSION_CONFDIR="$HOME/.config/$DESKTOP_SESSION"
# set resolution
if __does_cmd_exist xrandr && [ -n "$DISPLAY" ]; then
  RESOLUTION="$(xrandr --current | grep '*' | uniq | awk '{print $1}')"
fi
# export setting
export SUDO_ASKPASS DESKTOP_SESSION DESKTOP_SESSION_CONFDIR RESOLUTION
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set functions
__is_running() { __get_pid "$1" &>/dev/null && return 0 || return 1; }
__is_stopped() { __get_pid "$1" &>/dev/null && return 1 || return 0; }
__desktop_name() { [[ "$DESKTOP_SESSION" = "$1" ]] && return 0 || return 1; }
__get_pid() { ps -ux | grep " $1" | grep -v 'grep ' | awk '{print $2}' | grep '^' || return 1; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# kill running
__silent_kill() {
  if [[ $# -gt 1 ]]; then
    eval "$*" &>/dev/null
    exitCode=$?
    sleep .5
  else
    __is_running "$1" && kill -9 "$(__get_pid "$1")" >/dev/null 2>&1
    exitCode=$?
    sleep .5
  fi
  return ${exitCode:-$?}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Check if command exists
__does_cmd_exist() {
  unalias "$1" >/dev/null 2>&1
  command -v "$1" >/dev/null 2>&1 && true || false
  return $?
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start command
__silent_start() {
  local CMD="$1" && shift 1
  local ARGS="$*" && shift $#
  sleep .2
  eval $CMD $ARGS &>/dev/null &
  disown
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Help
if [[ "$1" = *help ]]; then
  printf "\n\t\t%s\n" "Usage: $PROG" "Starts applications for qtile window manager"
  exit
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# sudo password using dmenu
#__does_cmd_exist ask_for_password && SUDO_ASKPASS="/usr/local/bin/ask_for_password"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Panel - not needed for awesome i3 qtile sway xmonad
if __desktop_name "awesome" || __desktop_name "i3" || __desktop_name "qtile" || __desktop_name "sway" || __desktop_name "xmonad"; then
  true
else
  if __is_stopped xfce4-panel; then
    if __does_cmd_exist polybar; then
      __silent_kill polybar
      __silent_start "$HOME/.config/polybar/launch.sh"
    elif __does_cmd_exist tint2; then
      __silent_kill tint2
      __silent_start tint2 -c "$HOME/.config/tint2/tint2rc"
    elif __does_cmd_exist lemonbar; then
      __silent_kill lemonbar
      __silent_start "$HOME/.config/lemonbar/lemonbar.sh"
    else
      PANEL="none"
    fi
    if [ "$PANEL" = "none" ] && __does_cmd_exist xfce4-session && __does_cmd_exist xfce4-panel; then
      __silent_kill xfce4-panel
      __silent_start xfce4-panel
    fi
  fi
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# key bindings via sxhkd
if __does_cmd_exist sxhkd && __does_cmd_exist run_sxhkd; then
  __silent_kill sxhkd
  __silent_start run_sxhkd --start
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# setup keyboard
if __does_cmd_exist ibus-daemon; then
  __silent_kill ibus-daemon
  __silent_start ibus-daemon --xim -d
elif __does_cmd_exist ibus; then
  __silent_kill ibus
  __silent_start ibus
elif __does_cmd_exist fcitx; then
  __silent_kill fcitx
  __silent_start fcitx
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# enable control+alt+backspace
if __does_cmd_exist setxkbmap; then
  __silent_kill setxkbmap
  __silent_start setxkbmap -model pc104 -layout us -option "terminate:ctrl_alt_bksp"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start window compositor
if __does_cmd_exist picom; then
  __silent_kill picom
  __silent_start picom -b --config "$DESKTOP_SESSION_CONFDIR/compton.conf"
elif __does_cmd_exist compton; then
  __silent_kill compton
  __silent_start compton -b --config "$DESKTOP_SESSION_CONFDIR/compton.conf"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# test for an existing dbus daemon, just to be safe
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
  if __does_cmd_exist dbus-launch; then
    dbus_args="--sh-syntax --exit-with-session "
    case "$DESKTOP_SESSION" in
    awesome) dbus_args+="awesome" ;;
    bspwm) dbus_args+="bspwm" ;;
    i3 | i3wm) dbus_args+="i3 --shmlog-size 0" ;;
    dwm) dbus_args+="dwm" ;;
    jwm) dbus_args+="jwm" ;;
    lxde) dbus_args+="startlxde" ;;
    lxqt) dbus_args+="lxqt-session" ;;
    openbox) dbus_args+="openbox-session" ;;
    sway) dbus_args+="sway" ;;
    xfce) dbus_args+="xfce4-session" ;;
    xmonad) dbus_args+="xmonad" ;;
    *) dbus_args+="$DEFAULT_SESSION" ;;
    esac
    __silent_kill dbus-launch
    __silent_start dbus-launch "${dbus_args[*]}"
  fi
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# xsettings
if __does_cmd_exist xsettingsd; then
  __silent_kill xsettingsd
  __silent_start xsettingsd -c "$DESKTOP_SESSION_CONFDIR/xsettingsd.conf"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Authentication dialog
# ubuntu
if [ -f /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 ]; then
  __silent_kill polkit-gnome-authentication-agent-1
  __silent_start /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1
# Fedora
elif [ -f /usr/libexec/polkit-gnome-authentication-agent-1 ]; then
  __silent_kill polkit-gnome-authentication-agent-1
  __silent_start /libexec/polkit-gnome-authentication-agent-1
# Arch
elif [ -f /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 ]; then
  __silent_kill polkit-gnome-authentication-agent-1
  __silent_start /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#Notification daemon
if [ -f /usr/lib/xfce4/notifyd/xfce4-notifyd ]; then
  __silent_kill xfce4-notifyd
  __silent_start /usr/lib/xfce4/notifyd/xfce4-notifyd
elif [ -f /usr/lib/x86_64-linux-gnu/xfce4/notifyd/xfce4-notifyd ]; then
  __silent_kill xfce4-notifyd
  __silent_start /usr/lib/x86_64-linux-gnu/xfce4/notifyd/xfce4-notifyd
elif __does_cmd_exist dunst; then
  __silent_kill dunst
  __silent_start dunst
elif __does_cmd_exist deadd-notification-center; then
  __silent_kill deadd-notification-center
  __silent_start deadd-notification-center
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# vmware tools
if __does_cmd_exist vmware-user-suid-wrapper && ! __is_running vmware-user-suid-wrapper; then
  __silent_kill vmware-user-suid-wrapper
  __silent_start vmware-user-suid-wrapper
fi
if __does_cmd_exist vmware-user && ! __is_running vmware-user; then
  __silent_kill vmware-user
  __silent_start vmware-user
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# start conky
if __does_cmd_exist conky; then
  __silent_kill conky
  __silent_start conky -c "$DESKTOP_SESSION_CONFDIR/conky.conf"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Wallpaper manager
if __does_cmd_exist randomwallpaper; then
  __silent_kill randomwallpaper bg stop
  __silent_start randomwallpaper bg start
elif __does_cmd_exist variety; then
  __silent_kill variety
  __silent_start variety
elif __does_cmd_exist feh; then
  __silent_kill feh
  __silent_start feh --bg-fill "${WALLPAPER_DIR:-$HOME/.local/share/wallpapers}/system/default.jpg"
elif __does_cmd_exist nitrogen; then
  __silent_kill nitrogen
  __silent_start nitrogen --restore
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Network Manager
if __does_cmd_exist nm-applet; then
  __silent_kill nm-applet
  __silent_start nm-applet
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Package Manager
if __does_cmd_exist check-for-updates; then
  __silent_kill check-for-updates
  __silent_start check-for-updates
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# bluetooth
if __does_cmd_exist blueberry-tray; then
  __silent_kill blueberry-tray
  __silent_start blueberry-tray
elif __does_cmd_exist blueman-applet; then
  __silent_kill blueman-applet
  __silent_start blueman-applet
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# num lock activated
if __does_cmd_exist numlockx; then
  __silent_kill numlockx
  __silent_start numlockx on
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# volume
if __does_cmd_exist volumeicon; then
  __silent_kill volumeicon
  __silent_start volumeicon
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# clipman
if __does_cmd_exist xfce4-clipman; then
  __silent_kill xfce4-clipman
  __silent_start xfce4-clipman
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# PowerManagement
if __does_cmd_exist xfce4-power-manager; then
  __silent_kill xfce4-power-manager
  __silent_start xfce4-power-manager
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Session used if you want xfce4
if __does_cmd_exist xfce4-session && __desktop_name "xfce4"; then
  __silent_kill xfce4-session
  __silent_start xfce4-session
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Screenkey
#if __does_cmd_exist screenkey ; then
#    __silent_kill screenkey
#    __silent_start screenkey
#fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# mpd
if { [[ -z "$MPDSERVER" ]] || [[ "$MPDSERVER" = "localhost" ]]; } && __does_cmd_exist mpd && ! __is_running mpd; then
  __silent_kill mpd
  __silent_start mpd
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# transmission
if __does_cmd_exist mytorrent; then
  __silent_kill mytorrent
  __silent_start mytorrent
elif __does_cmd_exist transmission-daemon && ! __is_running transmission-daemon; then
  __silent_start transmission-daemon
elif __does_cmd_exist transmission-gtk && ! __is_running transmission-gtk; then
  __silent_start transmission-gtk -m
elif __does_cmd_exist transmission-remote-gtk && ! __is_running transmission-remote-gtk && __is_running transmission-daemon; then
  __silent_start transmission-remote-gtk -m
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Welcome Message
if __does_cmd_exist notifications; then
  sleep 90 && notifications "$DESKTOP_SESSION" "Welcome $USER to the $DESKTOP_SESSION Desktop" &
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# final
sleep 10
unset -f __does_cmd_exist __silent_kill __silent_start __get_pid
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exit 0
# End
