#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -Eeuo pipefail
binary=$(realpath -e "${1:?Paint executable}")
binary_dir=$(dirname -- "$binary")
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
    set +e
    timeout 16 env QT_QPA_PLATFORM=offscreen QT_FORCE_STDERR_LOGGING=1 \
        XDG_CONFIG_HOME="$evidence/config" XDG_DATA_HOME="$evidence/data" \
        XDG_CACHE_HOME="$evidence/cache" \
        LD_PRELOAD="$evidence/probe.so" \
        LD_LIBRARY_PATH="$binary_dir:$dialog_prefix/lib:$ribbon_library" \
        AERO7_QA_DIALOG_SCENARIO="$scenario" AERO7_QA_DIALOG_IMAGE="$image" \
        "$binary" > "$evidence/$scenario.log" 2>&1
    status=$?
    set -e
    if ((status != 0)) || ! grep -F "AERO7_NATIVE_DIALOG_PASS: $scenario" "$evidence/$scenario.log"; then
        printf 'Paint dialog scenario failed: %s (status %s)\n' "$scenario" "$status" >&2
        sed -n '1,240p' "$evidence/$scenario.log" >&2
        exit 1
    fi
done
printf 'AERO7_NATIVE_PAINT_DIALOG_TESTS_PASSED\n'
