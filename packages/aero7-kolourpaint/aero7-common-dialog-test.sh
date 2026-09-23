#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -Eeuo pipefail
binary=$(realpath -e "${1:?Paint executable}")
ribbon_library=$(realpath -e "${2:?SARibbon library directory}")
dialog_prefix=$(realpath -e "${3:?Common-dialog SDK prefix}")
inputs=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
evidence=$(mktemp -d "${TMPDIR:-/tmp}/aero7-native-paint.XXXXXX")
printf 'Native Paint evidence: %s\n' "$evidence"
read -r -a qt_flags <<< "$(pkg-config --cflags --libs Qt6Widgets)"
c++ -std=c++17 -fPIC -shared "$inputs/aero7-common-dialog-probe.cpp" \
    -I"$dialog_prefix/include/Aero7CommonDialogs" \
    -L"$dialog_prefix/lib" -laero7commondialogs \
    "${qt_flags[@]}" -o "$evidence/probe.so"
mkdir -p "$evidence/config/aero7" "$evidence/data" "$evidence/cache" "$evidence/documents"
# No default host libraries are materialized by this isolated QA profile.
printf '{"libraries":[{"id":"documents","name":"Documents","locations":["%s/documents"],"saveLocation":"%s/documents"}]}\n' \
    "$evidence" "$evidence" > "$evidence/config/aero7/libraries.json"
for scenario in save open cancel remote-cancel; do
    image="$evidence/drawing.png"
    if [[ $scenario == *cancel ]]; then image="$evidence/$scenario.png"; fi
    timeout 16 env QT_QPA_PLATFORM=offscreen QT_FORCE_STDERR_LOGGING=1 \
        XDG_CONFIG_HOME="$evidence/config" XDG_DATA_HOME="$evidence/data" \
        XDG_CACHE_HOME="$evidence/cache" \
        LD_PRELOAD="$evidence/probe.so" \
        LD_LIBRARY_PATH="$dialog_prefix/lib:$ribbon_library" \
        AERO7_QA_DIALOG_SCENARIO="$scenario" AERO7_QA_DIALOG_IMAGE="$image" \
        "$binary" > "$evidence/$scenario.log" 2>&1
    grep -F "AERO7_NATIVE_DIALOG_PASS: $scenario" "$evidence/$scenario.log"
done
printf 'AERO7_NATIVE_PAINT_DIALOG_TESTS_PASSED\n'
