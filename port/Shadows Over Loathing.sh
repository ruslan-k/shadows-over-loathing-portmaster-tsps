#!/bin/bash
# Shadows Over Loathing — SpruceOS launcher (standalone: no PortMaster control.txt needed).
P=/mnt/SDCARD/Roms/PORTS/shadowsofloathing
cd "$P" || exit 1
# one instance only: a second ua_host fights the first for DRM (pageflip -16) and doubles RAM use
exec 9>"$P/.run.lock"
flock -n 9 || exit 0
exec >"$P/log.txt" 2>&1

for pid in $(pgrep -x MainUI); do kill -TERM "$pid"; done
sleep 2

export SDL_VIDEODRIVER=kmsdrm
export SDL_AUDIODRIVER=alsa
export AUDIODEV=plughw:0,0
export UA_AUDIO_SINK=pipe
. ./port.env   # runtime options (pad name); a variable already set in the environment wins

./ua_host "$P"

pgrep -x MainUI >/dev/null || setsid /mnt/SDCARD/spruce/flip/bin/MainUI >/dev/null 2>&1 &
