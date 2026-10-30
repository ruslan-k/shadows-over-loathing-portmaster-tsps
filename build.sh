#!/bin/bash
# Builds the port from the game's Windows/Unity data: convert -> patches -> IL2CPP -> apk.
# Env: UNITY_DATA (…/Shadows Over Loathing_Data), UNITY_PLAYER (Android player package),
#      TOOLKIT (portmaster-unity checkout), DLCPATCH (built dlcpatch tool), OUT, JOBS.
set -euo pipefail

UNITY_DATA=${UNITY_DATA:?set UNITY_DATA to the path to "…_Data"}
UNITY_PLAYER=${UNITY_PLAYER:?set UNITY_PLAYER to the unpacked Android player package}
TOOLKIT=${TOOLKIT:?set TOOLKIT to the portmaster-unity checkout}
DLCPATCH=${DLCPATCH:?set DLCPATCH to the built dlcpatch tool (see docs/technical.md §4)}
OUT=${OUT:-$PWD/out}
JOBS=${JOBS:-$(nproc)}
export PMUNITY_IL2CPP_HOME=${PMUNITY_IL2CPP_HOME:-$HOME/.cache/pmunity/il2cpp}
export PMUNITY_ANDROID_PLAYER=$UNITY_PLAYER

rm -rf "$OUT"; mkdir -p "$OUT"

echo "== convert"
(cd "$TOOLKIT/convert" && python -m pmunity convert "$UNITY_DATA" "$OUT/conv" --config "$PWD/sol.build.json")

echo "== data tree (full: level0, resources.assets, ScriptingAssemblies.json come from here)"
cp -a "$UNITY_DATA" "$OUT/src"
cp -a "$OUT/conv/." "$OUT/src/"
rm -rf "$OUT/src/Managed"; cp -a "$UNITY_DATA/Managed" "$OUT/src/Managed"

echo "== engine assemblies: the player's, not the desktop ones"
cp -f "$UNITY_PLAYER/Variations/il2cpp/Managed/UnityEngine"*.dll "$OUT/src/Managed/"

echo "== Steamworks + Rewired INPUT stubs"
"$DLCPATCH" "$OUT/src/Managed" "$OUT/patched"
cp "$OUT/patched"/*.dll "$OUT/src/Managed/"

echo "== asmpatch (Rewired platform + StreamingAssets reads)"
dotnet "$TOOLKIT/tools/asmpatch/out/any/asmpatch.dll" --only=rewired-android,streaming-assets \
    "$OUT/src/Managed" "$OUT/asmp"
cp "$OUT/asmp"/*.dll "$OUT/src/Managed/"

echo "== IL2CPP (no stripping: the data asks for engine types the linker drops)"
(cd "$TOOLKIT/convert" && python -m pmunity il2cpp "$OUT/src" "$OUT/il2cpp" \
    --abi arm64-v8a --pkg "$UNITY_PLAYER" --strip none --jobs "$JOBS")

echo "== pack"
(cd "$TOOLKIT/convert" && python -m pmunity android-data --src "$OUT/src" --pkg "$UNITY_PLAYER" \
    --il2cpp "$OUT/il2cpp" --out "$OUT/pack" --name ShadowsofLoathing \
    --package com.pmunity.sol --streaming-assets both --pack all)

echo "done: $OUT/pack"
