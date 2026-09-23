#!/usr/bin/env bash
set -Eeuo pipefail

event="${1:-}"
build_id="${2:-unknown}"
detail="${3:-}"
config="${AERO7_NOTIFICATION_CONFIG:-${HOME:?}/.config/aero7-builder/notifications.conf}"
curl_command="${AERO7_CURL:-curl}"

case "$event" in
  build-failed|repository-published|configuration-test) ;;
  *)
    printf 'notify-release: unsupported event: %s\n' "$event" >&2
    exit 2
    ;;
esac

[[ -r "$config" ]] || {
  printf 'notify-release: notification config is not readable: %s\n' "$config" >&2
  exit 1
}

permissions="$(stat -c '%a' "$config")"
if (( (8#$permissions & 8#077) != 0 )); then
  printf 'notify-release: refusing config with group/other permissions: %s (%s)\n' \
    "$config" "$permissions" >&2
  exit 1
fi

config_value() {
  local canonical="$1"
  local friendly="$2"
  awk -F= -v canonical="$canonical" -v friendly="$friendly" '
    {
      key=$1
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
      if (key == canonical || key == friendly) {
        value=substr($0, index($0, "=") + 1)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
        if ((value ~ /^".*"$/) || (value ~ /^'\''.*'\''$/)) {
          value=substr(value, 2, length(value) - 2)
        }
        print value
        exit
      }
    }
  ' "$config"
}

AERO7_DISCORD_UPDATES_WEBHOOK="$(config_value AERO7_DISCORD_UPDATES_WEBHOOK aero7-updates)"
AERO7_DISCORD_BUILDER_FAILURES_WEBHOOK="$(config_value AERO7_DISCORD_BUILDER_FAILURES_WEBHOOK builder-failures)"
AERO7_DISCORD_REPOSITORY_PUBLISHED_WEBHOOK="$(config_value AERO7_DISCORD_REPOSITORY_PUBLISHED_WEBHOOK repository-published)"
AERO7_NTFY_BASE_URL="$(config_value AERO7_NTFY_BASE_URL ntfy-base-url)"
AERO7_NTFY_TOPIC="$(config_value AERO7_NTFY_TOPIC ntfy-topic)"
AERO7_NTFY_TOKEN="$(config_value AERO7_NTFY_TOKEN ntfy-token)"

require_url() {
  local name="$1"
  local value="${!name:-}"
  [[ "$value" == https://discord.com/api/webhooks/* || \
     "$value" == https://discordapp.com/api/webhooks/* ]] || {
    printf 'notify-release: %s is missing or is not a Discord webhook URL\n' "$name" >&2
    return 1
  }
}

json_payload() {
  local title="$1"
  local body="$2"
  TITLE="$title" BODY="$body" python - <<'PY'
import json
import os
print(json.dumps({
    "username": "Aero7 Builder",
    "content": f"**{os.environ['TITLE']}**\n{os.environ['BODY']}",
}, separators=(",", ":")))
PY
}

post_json() {
  local url="$1"
  local payload="$2"
  local request_config
  request_config="$(mktemp)"
  chmod 600 "$request_config"
  trap 'rm -f -- "$request_config"' RETURN
  printf 'url = "%s"\n' "$url" > "$request_config"
  "$curl_command" --silent --show-error --fail-with-body \
    --config "$request_config" \
    --header 'Content-Type: application/json' \
    --data-binary "$payload" >/dev/null
  rm -f -- "$request_config"
  trap - RETURN
}

post_ntfy() {
  local title="$1"
  local body="$2"
  local base="${AERO7_NTFY_BASE_URL:-}"
  local topic="${AERO7_NTFY_TOPIC:-}"
  local token="${AERO7_NTFY_TOKEN:-}"
  [[ -n "$base" && -n "$topic" && -n "$token" ]] || return 0
  [[ "$base" == https://* && "$topic" =~ ^[-_A-Za-z0-9]+$ ]] || {
    printf 'notify-release: invalid ntfy destination\n' >&2
    return 1
  }
  local request_config
  request_config="$(mktemp)"
  chmod 600 "$request_config"
  trap 'rm -f -- "$request_config"' RETURN
  {
    printf 'url = "%s/%s"\n' "${base%/}" "$topic"
    printf 'header = "Authorization: Bearer %s"\n' "$token"
    printf 'header = "Title: %s"\n' "$title"
    printf 'header = "Tags: package,computer"\n'
    printf 'header = "Click: https://aero7.org/news"\n'
  } > "$request_config"
  "$curl_command" --silent --show-error --fail-with-body \
    --config "$request_config" --data-binary "$body" >/dev/null
  rm -f -- "$request_config"
  trap - RETURN
}

timestamp="$(date -u '+%Y-%m-%d %H:%M UTC')"
case "$event" in
  build-failed)
    require_url AERO7_DISCORD_BUILDER_FAILURES_WEBHOOK
    title="Aero7 package build failed"
    body="Build: \`$build_id\`\nTime: $timestamp"
    [[ -z "$detail" ]] || body="$body\n$detail"
    post_json "$AERO7_DISCORD_BUILDER_FAILURES_WEBHOOK" \
      "$(json_payload "$title" "$body")"
    ;;
  repository-published)
    require_url AERO7_DISCORD_REPOSITORY_PUBLISHED_WEBHOOK
    require_url AERO7_DISCORD_UPDATES_WEBHOOK
    title="Aero7 package repository updated"
    body="Build \`$build_id\` passed public verification and is now available.\n$timestamp"
    [[ -z "$detail" ]] || body="$body\n$detail"
    payload="$(json_payload "$title" "$body")"
    post_json "$AERO7_DISCORD_REPOSITORY_PUBLISHED_WEBHOOK" "$payload"
    post_json "$AERO7_DISCORD_UPDATES_WEBHOOK" "$payload"
    post_ntfy "$title" "Build $build_id is now available. Open Aero7 Control Panel > Software Update to review updates."
    ;;
  configuration-test)
    require_url AERO7_DISCORD_BUILDER_FAILURES_WEBHOOK
    require_url AERO7_DISCORD_REPOSITORY_PUBLISHED_WEBHOOK
    require_url AERO7_DISCORD_UPDATES_WEBHOOK
    title="Aero7 notification test"
    body="Notification routing is configured on the package builder.\n$timestamp"
    payload="$(json_payload "$title" "$body")"
    post_json "$AERO7_DISCORD_BUILDER_FAILURES_WEBHOOK" "$payload"
    post_json "$AERO7_DISCORD_REPOSITORY_PUBLISHED_WEBHOOK" "$payload"
    post_json "$AERO7_DISCORD_UPDATES_WEBHOOK" "$payload"
    post_ntfy "$title" "Public Aero7 package-update notifications are configured."
    ;;
esac

printf 'notify-release: delivered %s for %s\n' "$event" "$build_id"
