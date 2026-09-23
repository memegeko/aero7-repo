#!/usr/bin/env bash
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT

config="$tmp/notifications.conf"
cat > "$config" <<'EOF'
aero7-updates = https://discord.com/api/webhooks/1/updates
builder-failures = https://discord.com/api/webhooks/2/failures
repository-published = https://discord.com/api/webhooks/3/published
ntfy-base-url = https://notify.example.test
ntfy-topic = aero7-updates
ntfy-token = test-token-placeholder
EOF
chmod 600 "$config"

cat > "$tmp/fake-curl" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
config_file=""
while (($#)); do
  if [[ "$1" == --config ]]; then
    config_file="$2"
    shift 2
  else
    shift
  fi
done
[[ -r "$config_file" ]]
printf 'call\n' >> "${AERO7_TEST_CALLS:?}"
EOF
chmod +x "$tmp/fake-curl"

export AERO7_NOTIFICATION_CONFIG="$config"
export AERO7_CURL="$tmp/fake-curl"
export AERO7_TEST_CALLS="$tmp/calls"

"$repo/scripts/notify-release.sh" configuration-test test >/dev/null
[[ "$(wc -l < "$AERO7_TEST_CALLS")" -eq 4 ]]

: > "$AERO7_TEST_CALLS"
"$repo/scripts/notify-release.sh" build-failed build-1 test >/dev/null
[[ "$(wc -l < "$AERO7_TEST_CALLS")" -eq 1 ]]

: > "$AERO7_TEST_CALLS"
"$repo/scripts/notify-release.sh" repository-published build-2 test >/dev/null
[[ "$(wc -l < "$AERO7_TEST_CALLS")" -eq 3 ]]

chmod 644 "$config"
if "$repo/scripts/notify-release.sh" build-failed bad-permissions 2>/dev/null; then
  printf 'test-notifications: insecure config unexpectedly accepted\n' >&2
  exit 1
fi

if "$repo/scripts/notify-release.sh" unknown-event test 2>/dev/null; then
  printf 'test-notifications: unknown event unexpectedly accepted\n' >&2
  exit 1
fi

printf 'test-notifications: ok\n'
