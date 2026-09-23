#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Runs the real Paint executable with a QA-only observation library.
set -Eeuo pipefail
binary=$(realpath -e "${1:?Paint executable}")
library_dir=$(realpath -e "${2:?SARibbon library directory}")
inputs=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
evidence=$(mktemp -d "${TMPDIR:-/tmp}/aero7-paint-layout.XXXXXX")
printf 'Paint layout evidence: %s\n' "$evidence"
read -r -a qt_flags <<< "$(pkg-config --cflags --libs Qt6Widgets)"
c++ -std=c++17 -fPIC -shared "$inputs/aero7-ribbon-layout-probe.cpp" \
    "${qt_flags[@]}" -o "$evidence/probe.so"
mkdir -p "$evidence/default/config" "$evidence/classic/config"
cp "$inputs/aero7-classic-layout.conf" "$evidence/classic/config/kolourpaintrc"
for scenario in default default-reopen classic classic-reopen; do
    mode=${scenario%-reopen}
    expected=1
    [[ $mode != classic ]] || expected=0
    set +e
    timeout 15 env QT_QPA_PLATFORM=offscreen QT_FORCE_STDERR_LOGGING=1 \
        XDG_CONFIG_HOME="$evidence/$mode/config" \
        XDG_DATA_HOME="$evidence/$mode/data" \
        XDG_CACHE_HOME="$evidence/$mode/cache" \
        LD_PRELOAD="$evidence/probe.so" LD_LIBRARY_PATH="$library_dir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
        AERO7_QA_EXPECT_RIBBON="$expected" \
        "$binary" > "$evidence/$scenario.log" 2>&1
    status=$?
    set -e
    if ((status != 0)) || ! grep -F 'AERO7_LAYOUT_PASS:' "$evidence/$scenario.log"; then
        printf 'Paint layout scenario failed: %s (status %s)\n' "$scenario" "$status" >&2
        sed -n '1,240p' "$evidence/$scenario.log" >&2
        exit 1
    fi
done
printf 'AERO7_RIBBON_LAYOUT_TESTS_PASSED\n'
