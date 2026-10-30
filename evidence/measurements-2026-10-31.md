# Device measurements — 2026-10-31

Handheld: TrimUI Smart Pro, SpruceOS, Mali-G57, 963 MB RAM + 2 GB swap on SD, CPU preset Performance
(1992 MHz). Port: `/mnt/SDCARD/Roms/PORTS/shadowsofloathing`, APK 313 MB, `libil2cpp.so` 95 MiB
(2020.3.33f1, `--strip none`), FMOD pair from another Unity 2.x build.

## Why the first runs felt janky

Two `ua_host` processes were alive at once (double launch). They fought over DRM
(`ERROR: Could not queue pageflip: -16`) and each held a full copy of the game:

| | two instances | one instance |
|---|---|---|
| MemAvailable | 78 MB | 308 MB after the second one exited |
| VmSwap (game) | 343 MB | 0.4 MB in menu |
| fps | 42 with 42 hitches, 500–750 ms each | 60 |

The launcher now holds `.run.lock` (`flock -n`), so a second start is a no-op.

## Menu (single instance, after reboot)

```
60.0 fps, frame 16.7 avg / 20.5 p99 / 21.7 worst ms, late 0, hitch 0
RSS 712 MB, VmSwap 436 kB
MemAvailable 90 MB, swap used 8 MB of 2017
```

## Combat

```
steady:        60.0 fps, 16.7 ms avg, p99 21 ms, hitch 0
combat start:  33.2 fps for one interval, 30.2 ms avg, p99 220 ms, worst 1786 ms
RSS 720–728 MB (flat over 45 s), VmSwap 185 MB
MemAvailable 75–79 MB, swap used 208 MB
40 hitches over ~7 minutes, clustered at asset loads
```

## Reading

The working set is ~900 MB against 963 MB of RAM, so ~185 MB lives in the SD swap and every swap-in
during a load becomes a 200 ms–1.8 s stall. No leak: RSS is flat. The obvious headroom lever is the
105 MB `ambience.bank` (stream it instead of loading it whole); GC heap and quality settings are the
next levers if a build-time change is preferred.
