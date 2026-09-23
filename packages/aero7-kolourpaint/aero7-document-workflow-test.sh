#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -Eeuo pipefail
binary=$(realpath -e "${1:?Paint executable}")
binary_dir=$(dirname -- "$binary")
ribbon_library=$(realpath -e "${2:?SARibbon library directory}")
dialog_prefix=$(realpath -e "${3:?Common-dialog SDK prefix}")
inputs=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
evidence=$(mktemp -d "${TMPDIR:-/tmp}/aero7-document-workflow.XXXXXX")
printf 'Paint document workflow evidence: %s\n' "$evidence"
read -r -a qt_flags <<< "$(pkg-config --cflags --libs Qt6Widgets)"
c++ -std=c++17 -fPIC -shared "$inputs/aero7-document-workflow-probe.cpp" \
    -I"$dialog_prefix/include/Aero7CommonDialogs" -L"$dialog_prefix/lib" \
    -laero7commondialogs "${qt_flags[@]}" -o "$evidence/probe.so"
for scenario in same-window separate-window unsaved-cancel unsaved-discard unsaved-save; do
    profile="$evidence/$scenario"
    mkdir -p "$profile/config/aero7" "$profile/data" "$profile/cache" "$profile/documents"
    printf '{"libraries":[{"id":"documents","name":"Documents","locations":["%s/documents"],"saveLocation":"%s/documents"}]}\n' \
        "$profile" "$profile" > "$profile/config/aero7/libraries.json"
    if [[ $scenario == separate-window ]]; then
        printf '[General Settings]\nOpen Images in the Same Window=false\n' > "$profile/config/kolourpaintrc"
    fi
    set +e
    timeout 16 env QT_QPA_PLATFORM=offscreen QT_FORCE_STDERR_LOGGING=1 \
        XDG_CONFIG_HOME="$profile/config" XDG_DATA_HOME="$profile/data" \
        XDG_CACHE_HOME="$profile/cache" LD_PRELOAD="$evidence/probe.so" \
        LD_LIBRARY_PATH="$binary_dir:$dialog_prefix/lib:$ribbon_library" \
        AERO7_QA_WORKFLOW="$scenario" \
        AERO7_QA_START_IMAGE="$profile/documents/start.png" \
        AERO7_QA_TARGET_IMAGE="$profile/documents/target.png" \
        "$binary" "$profile/documents/start.png" > "$profile/test.log" 2>&1
    status=$?
    set -e
    if ((status != 0)) || ! grep -F "AERO7_DOCUMENT_WORKFLOW_PASS: $scenario" "$profile/test.log"; then
        printf 'Paint document scenario failed: %s (status %s)\n' "$scenario" "$status" >&2
        sed -n '1,240p' "$profile/test.log" >&2
        exit 1
    fi
done
printf 'AERO7_DOCUMENT_WORKFLOW_TESTS_PASSED\n'
