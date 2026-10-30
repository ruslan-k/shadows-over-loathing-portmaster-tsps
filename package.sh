#!/bin/bash
# Copies a built port to the handheld. Env: OUT (build output), DEVICE (ssh host), DEST.
set -euo pipefail
OUT=${OUT:-$PWD/out}
DEVICE=${DEVICE:-tsps}
DEST=${DEST:-/mnt/SDCARD/Roms/PORTS/shadowsofloathing}
PLAYER=${PLAYER:-$PWD/player}

mkdir -p "$OUT"/{apkdest,lib}
tar -C "$OUT/pack/zip" -cf - . | ssh "$DEVICE" "tar -xf - -C $DEST"
for so in libil2cpp.so libmain.so libunity.so; do
    src=$(ls "$OUT/il2cpp/lib/arm64-v8a/$so" "$PLAYER/Variations/il2cpp/Release/Libs/arm64-v8a/$so" 2>/dev/null | head -1)
    scp -q "$src" "$DEVICE:$DEST/lib/$so"
done
scp -q "port/Shadows Over Loathing.sh" "$DEVICE:/mnt/SDCARD/Roms/PORTS/Shadows Over Loathing.sh"
ssh "$DEVICE" "chmod +x '/mnt/SDCARD/Roms/PORTS/Shadows Over Loathing.sh'; sha256sum $DEST/ShadowsofLoathing.apk $DEST/lib/libil2cpp.so | cut -c1-16"
