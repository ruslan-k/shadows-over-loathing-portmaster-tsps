#!/bin/bash
# Builds the port from the game's Windows/Unity data: convert -> IL2CPP -> Game_Data + apk.
# Env: UNITY_DATA (…/Shadows Over Loathing_Data), UNITY_PLAYER (Android player package),
#      TOOLKIT (portmaster-unity checkout), OUT, JOBS.
set -euo pipefail

UNITY_DATA=${UNITY_DATA:?set UNITY_DATA to the path to "…_Data"}
UNITY_PLAYER=${UNITY_PLAYER:?set UNITY_PLAYER to the unpacked Android player package}
TOOLKIT=${TOOLKIT:?set TOOLKIT to the portmaster-unity checkout}
OUT=${OUT:-$PWD/out}
JOBS=${JOBS:-$(nproc)}
export PMUNITY_IL2CPP_HOME=${PMUNITY_IL2CPP_HOME:-$HOME/.cache/pmunity/il2cpp}

rm -rf "$OUT"; mkdir -p "$OUT"

echo "== convert"
(cd "$TOOLKIT/convert" && python -m pmunity convert "$UNITY_DATA" "$OUT/conv" --config sol.build.json)

echo "== asmpatch (Rewired platform + StreamingAssets reads)"
cp -a "$UNITY_DATA" "$OUT/src"
dotnet "$TOOLKIT/tools/asmpatch/out/any/asmpatch.dll" --only=rewired-android,streaming-assets \
    "$OUT/src/Managed" "$OUT/asmp"
cp "$OUT/asmp"/*.dll "$OUT/src/Managed/"

echo "== IL2CPP"
(cd "$TOOLKIT/convert" && python -m pmunity il2cpp "$OUT/src" "$OUT/il2cpp" \
    --abi arm64-v8a --pkg "$UNITY_PLAYER" --jobs "$JOBS")

echo "== pack"
# android-data reads Managed from --src: the converted tree has assets only.
cp -a "$OUT/src/Managed" "$OUT/conv/Managed"
(cd "$TOOLKIT/convert" && python -m pmunity android-data --src "$OUT/conv" --pkg "$UNITY_PLAYER" \
    --il2cpp "$OUT/il2cpp" --out "$OUT/pack" --name ShadowsofLoathing \
    --package com.pmunity.sol --streaming-assets both --pack all)

echo "done: $OUT/pack"
