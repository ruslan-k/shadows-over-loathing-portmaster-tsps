# Shadows Over Loathing — native Unity port for TrimUI Smart Pro (SpruceOS)

Native arm64 port built from the Windows Steam/GOG release (Unity **2020.3.33f1**) and run on the
device's Mali-G57 through SDL2 + KMSDRM. The game's managed assemblies are compiled to IL2CPP for
Android arm64 with the matching Unity player; `ua_host` supplies display, input, audio and paths.

## Status

- Build pipeline complete: data converted (ASTC, GLES3 shaders), `libil2cpp.so` 50.9 MiB
  (metadata v27, 20 data files), APK 291 MB.
- Device launch under test — this file will say "verified" only after a real on-device run.

## Install

Copy `port/` to `/mnt/SDCARD/Roms/PORTS/`; the launcher shows up as **Shadows Over Loathing**.
Game data is not distributed here — build it with `build.sh`:

```
/mnt/SDCARD/Roms/PORTS/shadowsofloathing/
  ua_host                    host runtime (arm64)
  ShadowsofLoathing.apk      data container (Game_Data/ + manifest)
  lib/libil2cpp.so           compiled game assemblies
  Game_Data/StreamingAssets  core bundles, anims, banks, …
  data/external/             saves
```

## Build

Needs an x86_64 Linux host, the game files, and the `portmaster-unity` toolkit (Unity editor
2020.3.33f1 + Android player, IL2CPP, Mono.Cecil).

```sh
UNITY_DATA="/path/Shadows Over Loathing_Data" UNITY_PLAYER="/path/android-player" ./build.sh
DEVICE=tsps ./package.sh
```

Timings on 8 cores: convert ~3 min (ASTC), IL2CPP ~220 s, pack ~32 s.

## Licence

Port code: GPL-3.0 (`LICENSE`). Game data, art and text belong to Asymmetric Publications; nothing
from the game is distributed here.
