# Shadows Over Loathing — native Unity port for TrimUI Smart Pro (SpruceOS)

Native arm64 port built from the Windows release (Unity **2020.3.33f1**) and run on the device's
Mali-G57 through SDL2 + KMSDRM. The game's managed assemblies are compiled to IL2CPP for Android
arm64 with the matching Unity player; `ua_host` supplies display, input, audio and paths.

## Status

Verified on the handheld: title screen, main menu and combat.

- 60.0 fps in menu and in combat (16.7 ms average frame, p99 ≈ 21 ms, hitch 0 between loads).
- RSS 712–728 MB, VmSwap 0.4 MB in the menu and ~185 MB in combat; memory, not GPU, is the limit
  (963 MB total) — see [`docs/technical.md`](docs/technical.md) §7.
- Sound works (FMOD Studio), gamepad native, saves in `data/external/`.
- Known: asset loads stall (33 fps for one interval, worst frame 1.79 s at combat start).

## Install

Copy `port/` to `/mnt/SDCARD/Roms/PORTS/`; the launcher shows up as **Shadows Over Loathing**.
Game data is not distributed here — build it with `build.sh`:

```
/mnt/SDCARD/Roms/PORTS/shadowsofloathing/
  ua_host                    host runtime (arm64)
  ShadowsofLoathing.apk      data container (Game_Data/ + manifest)
  lib/libil2cpp.so           compiled game assemblies
  lib/{libmain,libunity}.so  Unity player (from the Android player package)
  lib/libfmod*.so            FMOD Studio pair matching the game's FMODUnity build
  Game_Data/StreamingAssets  core bundles, anims, banks, …
  data/external/             saves
```

## Build

Needs an x86_64 Linux host, the game files, and the `portmaster-unity` toolkit (Unity editor
2020.3.33f1 + Android player, IL2CPP, Mono.Cecil).

```sh
UNITY_DATA="/path/Shadows Over Loathing_Data" UNITY_PLAYER="/path/android-player" ./build.sh
DEVICE=tsps FMOD=/path/to/fmod-pair ./package.sh
```

Timings on 8 cores: convert ~3 min (ASTC), IL2CPP ~8 min (`--strip none`), pack ~32 s. Output:
`libil2cpp.so` 95 MiB, APK 313 MB.

## Notes

Three non-obvious steps are documented in `docs/technical.md`: the Android player is unpacked from
the macOS module package, IL2CPP must compile against the player's `UnityEngine.*` assemblies, and
the APK must be packed from the full data tree (not the converter's output). Steamworks stubs and
the FMOD pair are there too.

## Licence

Port code: GPL-3.0 (`LICENSE`). Game data, art and text belong to Asymmetric Publications; nothing
from the game is distributed here. The FMOD libraries are not part of this repository.
