# port/

What goes on the SD card:

```
port/
  Shadows Over Loathing.sh    launcher (SpruceOS Ports menu)
  port.env                    runtime options (pad name)
  shadowsofloathing/          game directory, filled from the build output
```

After `build.sh` + `package.sh`, `shadowsofloathing/` holds:

```
ua_host                       host runtime (arm64)
ShadowsofLoathing.apk         data container: Game_Data/ + manifest
lib/libil2cpp.so              compiled game assemblies
Game_Data/StreamingAssets     anims, bootstrap, FMOD banks, …
data/external/                saves
```

The launcher switches to KMSDRM, stops MainUI (it holds the panel and the ALSA device), runs
`ua_host`, and brings MainUI back on exit. Log: `shadowsofloathing/log.txt`.

Environment: `SDL_AUDIODRIVER=alsa`, `AUDIODEV=plughw:0,0`, `UA_AUDIO_SINK=pipe` — one sink only,
two leave ALSA in `PREPARED` and the game is silent.
