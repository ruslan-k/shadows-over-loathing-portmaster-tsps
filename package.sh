#!/bin/bash
# Copies a built port to the handheld. Env: OUT (build output), DEVICE (ssh host), DEST,
# PLAYER (unpacked Android player package, for libmain/libunity), FMOD (dir with the FMOD pair).
set -euo pipefail
OUT=${OUT:-$PWD/out}
DEVICE=${DEVICE:-tsps}
DEST=${DEST:-/mnt/SDCARD/Roms/PORTS/shadowsofloathing}
PLAYER=${PLAYER:-$PWD/player}
FMOD=${FMOD:-}

# --hard-dereference: the pack tree hardlinks assets/ to Game_Data/StreamingAssets/
tar --hard-dereference -C "$OUT/pack/zip" -cf - . | ssh "$DEVICE" "tar -xf - -C $DEST"
for so in libil2cpp.so libmain.so libunity.so; do
    src=$(ls "$OUT/il2cpp/lib/arm64-v8a/$so" "$PLAYER/Variations/il2cpp/Release/Libs/arm64-v8a/$so" 2>/dev/null | head -1)
    scp -q "$src" "$DEVICE:$DEST/lib/$so"
done
if [ -n "$FMOD" ]; then
    # the FMOD Studio pair must match the game's FMODUnity build; .13 are the sonames libfmodstudio asks for
    scp -q "$FMOD/libfmod.so" "$DEVICE:$DEST/lib/libfmod.so"
    scp -q "$FMOD/libfmod.so" "$DEVICE:$DEST/lib/libfmod.so.13"
    scp -q "$FMOD/libfmodstudio.so" "$DEVICE:$DEST/lib/libfmodstudio.so"
    scp -q "$FMOD/libfmodstudio.so" "$DEVICE:$DEST/lib/libfmodstudio.so.13"
fi
scp -q "port/Shadows Over Loathing.sh" "$DEVICE:/mnt/SDCARD/Roms/PORTS/Shadows Over Loathing.sh"
ssh "$DEVICE" "chmod +x '/mnt/SDCARD/Roms/PORTS/Shadows Over Loathing.sh'; sha256sum $DEST/ShadowsofLoathing.apk $DEST/lib/libil2cpp.so | cut -c1-16"
