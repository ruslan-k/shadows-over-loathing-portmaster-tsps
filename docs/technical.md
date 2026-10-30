# Technical notes

Verified on the device (TrimUI Smart Pro, SpruceOS, Mali-G57, GLES 3.2).

## 1. Source

Windows build (`UnityPlayer.dll`, `Shadows Over Loathing.exe`), Unity **2020.3.33f1**, Mono
scripting. Data lives in `Shadows Over Loathing_Data`; content is files in `StreamingAssets`
(`anims`, `bootstrap`, `core`, `*.bank`). Engine code links `fmodstudio`, `steam_api`,
`sdkencryptedappticket`, `Rewired_DirectInput`.

## 2. Pipeline

```sh
pmunity convert       # shaders -> GLES3, textures -> ASTC, settings, audio, quality=handheld
dlcpatch              # Steamworks stubs (Mono.Cecil), see §4
asmpatch              # rewired-android, streaming-assets
pmunity il2cpp        # 2020.3.33f1 player, --abi arm64-v8a --strip none
pmunity android-data  # --src <full data tree> --pkg <player> --il2cpp … --pack all
```

Three details cost most of the debugging time:

1. **`--src` must be the full data tree.** The converter's output holds only the assets it
   rewrote; packing from it ships an APK without `level0`, `resources.assets`, `app.info`,
   `ScriptingAssemblies.json` and `RuntimeInitializeOnLoads.json`. Unity 2020.2+ reads the last two
   from `assets/bin/Data/`; without them the engine cannot resolve types and dies on the first
   frame. Build the source as `src (full) + conv overlaid + src/Managed`.
2. **IL2CPP must compile against the player's `UnityEngine.*.dll`**, not the desktop ones the game
   ships. Copy `player/Variations/il2cpp/Managed/UnityEngine*.dll` (62 files) over
   `<src>/Managed/`. Symptom otherwise: hundreds of `Unable to find type
   [UnityEngine.CoreModule.dll]…` and SIGSEGV in `nativeRender` on frame 1.
3. **`--strip none`.** With UnityLinker enabled the metadata lost engine types the serialized data
   asks for (same messages). Also pass `--pkg` so the correct player version is used.

Timings on 8 cores: convert 192 s (ASTC search over 647 MB), IL2CPP 462 s without stripping,
pack 32 s. `libil2cpp.so` 95 MiB, APK 313 MB, install 626 MB.

## 3. Unity player package

Unity's Windows module installer for 2020.3 is NSIS and does not unpack with `7z` or
`innoextract` (“Not a supported Inno Setup installer”). The macOS module is a plain XAR package
whose payload is the same Android player:

```sh
curl -o android.pkg https://download.unity3d.com/download_unity/915a7af8b0d5/MacEditorTargetInstaller/UnitySetup-Android-Support-for-Editor-2020.3.33f1.pkg
7z x android.pkg -opkg
cd pkg/TargetSupport.pkg.tmp && bsdtar -xf Payload -C ../../player
```

`player/` then holds `Variations/il2cpp/Release/Libs/arm64-v8a/{libmain.so,libunity.so}`,
`Variations/il2cpp/Managed/UnityEngine*.dll`, `Apk/`, `Data/`, `Source/`, `Tools/` — that directory
is the `--pkg` argument. `libmain.so` and `libunity.so` must be copied into the port's `lib/` next
to `libil2cpp.so`; missing `libmain.so` is reported as
`[host] …/lib/libmain.so: No such file or directory`.

## 4. Steamworks

A stub Steam client never initialises, and the game calls `InteropHelp.TestIfAvailableClient` on
the title path — `InvalidOperationException: Steamworks is not initialized` repeats every frame and
the game never leaves the splash. Patch `com.rlabrecque.steamworks.net.dll` in one Mono.Cecil pass:
`TestIfAvailableClient` / `TestIfAvailableServer` become plain `ret`, the boolean platform queries
(`SteamUtils.IsSteamRunningOnSteamDeck`, `IsSteamInBigPictureMode`) return false, and the DLC/ownership
queries (`GetDLCCount` → 1, `BIsDlcInstalled`, `BIsSubscribed`, `BIsSubscribedApp`,
`BIsAppInstalled` → true, `BGetDLCDataByIndex` fills its out parameters) answer as if the add-on
were owned — harmless here, the game has no DLC. In `Assembly-CSharp` the same pass stubs
`Rewired.Utils.ExternalTools.LinuxInput_*` and redirects `AssetBundleManager` /
`ModelLoader.get_versionJsonPath` / `StartupState.get_buildVersionFile` to
`Game_Data/StreamingAssets/` beside the APK. Never write an assembly twice — the second pass
produces a 0-byte file.

## 5. FMOD

`fmodstudio` is a hard dependency; without it `DllNotFoundException` → `SystemNotInitializedException`
every frame and the game exits after the splash. Windows ships `Plugins/x86_64/fmodstudio.dll` only,
so the ARM64 pair has to come from another build of the same FMOD major. Two pairs were tried:

| source | result |
|---|---|
| Celeste port (`libfmod.so.13`, `libfmodstudio.so.13`) | `ERR_PLUGIN_VERSION` at `System.setOutput` |
| Carrion port (`libfmod.so`, `libfmodstudio.so`) | works |

Both names matter: `libfmodstudio.so` needs `libfmod.so.13`, so ship the pair as
`libfmod.so`, `libfmod.so.13`, `libfmodstudio.so`, `libfmodstudio.so.13`.

## 6. Runtime

SDL2 KMSDRM 1280×720, ALSA via `aplay … -D plughw:0,0` (`UA_AUDIO_SINK=pipe`), saves in
`data/external/`. The launcher takes `.run.lock` with `flock -n`: a second `ua_host` fights the
first for DRM (`Could not queue pageflip: -16`) and doubles memory use, which is the difference
between a steady 60 fps and constant stutter.

## 7. Measured

| state | fps | frame avg | p99 | RSS | VmSwap |
|---|---|---|---|---|---|
| menu | 60.0 | 16.7 ms | 20.5 ms | 712 MB | 0.4 MB |
| combat, steady | 60.0 | 16.7 ms | 21 ms | 728 MB | 185 MB |
| combat start (asset load) | 33 for one interval | 30 ms | 220 ms | 720 MB | — |

Worst single frame in combat load: 1.79 s. Memory is the limit: the working set is ~900 MB of
963 MB, so the kernel keeps ~185 MB in the SD swap; every swap-in during a load shows as a
200 ms–1.8 s stall. RSS is flat over time (no leak). The large `ambience.bank` (105 MB) is the most
obvious thing to stream if more headroom is needed.
