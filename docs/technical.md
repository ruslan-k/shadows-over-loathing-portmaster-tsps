# Technical notes

Verified on the build host; device numbers go here after the first real run.

## 1. Source

Windows build (`UnityPlayer.dll`, `Shadows Over Loathing.exe`), Unity **2020.3.33f1**, Mono
scripting. Data lives in `Shadows Over Loathing_Data`; content bundles are files in
`StreamingAssets` (`anims`, `bootstrap`, `*.bank` banks for FMOD).

## 2. Pipeline

```sh
pmunity convert      # shaders -> GLES3, textures -> ASTC, settings, audio, quality=handheld
asmpatch             # rewired-android, streaming-assets
pmunity il2cpp       # 2020.3.33f1 -> libil2cpp.so (arm64, metadata v27)
pmunity android-data --pkg <android player> --il2cpp … --pack all
```

`convert` needs `Managed/` in its output before `android-data` runs — the converted directory has
assets only, so copy `Managed` across (the pack step otherwise stops with
`no managed assemblies (Managed/*.dll)`).

Timings: convert 192 s (ASTC search over 647 MB of data), IL2CPP 220 s, pack 32 s.
`libil2cpp.so` 50.9 MiB, APK 291 MB.

## 3. Unity player package

Unity's Windows module installer for 2020.3 is NSIS and does not unpack with `7z` or
`innoextract` (“Not a supported Inno Setup installer”). The macOS module is a plain XAR package,
and its payload is the same Android player:

```sh
curl -o android.pkg https://download.unity3d.com/download_unity/915a7af8b0d5/MacEditorTargetInstaller/UnitySetup-Android-Support-for-Editor-2020.3.33f1.pkg
7z x android.pkg -opkg
cd pkg/TargetSupport.pkg.tmp && bsdtar -xf Payload -C ../../player
```

`player/` then holds `Variations/il2cpp/Release/Libs/arm64-v8a/{libmain.so,libunity.so}` plus
`Apk/`, `Data/`, `Source/`, `Tools/` — that directory is the `--pkg` argument.

## 4. Runtime

Same host runtime as the West of Loathing port: SDL2 KMSDRM 1280×720, ALSA through
`aplay … -D plughw:0,0` (`UA_AUDIO_SINK=pipe`), saves in `data/external/`.

## 5. Open points

- Steamworks: no patches applied yet. The Windows build links `libsteam_api` /
  `sdkencryptedappticket`; `plugins.map` stubs both. If the game refuses to boot without Steam,
  neutralise `InteropHelp.TestIfAvailableClient` and the platform queries in one Mono.Cecil pass.
- Rewired: `asmpatch --only=rewired-android,streaming-assets` changed `Assembly-CSharp.dll`; which
  of the two patches applied is not yet confirmed (the Windows Rewired variant has no
  `LinuxInput_*` methods, so the Android platform flip may be a no-op here).
