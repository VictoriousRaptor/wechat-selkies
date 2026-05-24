#!/bin/bash

# clean up stale dbus pid file to prevent startup failures after container restart
rm -f /run/dbus/pid

# configure default window behavior: open WeChat/QQ as normal windows instead of maximized
OB_RC="/config/.config/openbox/rc.xml"
if [ -f "$OB_RC" ] && ! grep -q '<application class="wechat"' "$OB_RC"; then
    sed -i '/<\/openbox_config>/i \
  <applications>\
    <application class="wechat">\
      <maximized>no</maximized>\
    </application>\
    <application class="QQ">\
      <maximized>no</maximized>\
    </application>\
  </applications>' "$OB_RC"
    openbox --reconfigure 2>/dev/null || true
fi

# generate openbox menu from defaults + ~/Desktop/*.desktop files
/scripts/refresh-menu.sh

# watch ~/Desktop/ for .desktop file changes and auto-refresh menu
mkdir -p "$HOME/Desktop"
if command -v inotifywait >/dev/null 2>&1; then
    (while inotifywait -q -e create -e delete -e modify "$HOME/Desktop/" --include '\.desktop$'; do
        sleep 1
        /scripts/refresh-menu.sh
    done) >/dev/null 2>&1 &
fi

# copy default tint2 config if not present
if [ ! -f "$HOME/.config/tint2/tint2rc" ]; then
    mkdir -p "$HOME/.config/tint2"
    cp /defaults/tint2rc "$HOME/.config/tint2/tint2rc"
fi
nohup tint2 > /dev/null 2>&1 &

# register chromium as default URL handler
gio mime x-scheme-handler/http chromium.desktop
gio mime x-scheme-handler/https chromium.desktop

# start WeChat application in the background if exists and auto-start enabled
if [ "$AUTO_START_WECHAT" = "true" ]; then
    if [ -f /usr/bin/wechat ]; then nohup /usr/bin/wechat > /dev/null 2>&1 & fi
fi

# start QQ application in the background if exists and auto-start enabled
if [ "$AUTO_START_QQ" = "true" ]; then
    if [ -f /usr/bin/qq ]; then nohup /usr/bin/qq --no-sandbox > /dev/null 2>&1 & fi
fi

# !deprecated: start window switcher application in the background
# start window switcher application in the background
# nohup sleep 2 && python /scripts/window_switcher.py > /dev/null 2>&1 &
