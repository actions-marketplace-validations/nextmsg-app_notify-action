#!/usr/bin/env bash
# Sends one message to the NextMsg API. Inputs come from environment variables (never interpolated
# into the script), the key goes in the Authorization header (never in a URL or the log).
set -uo pipefail

fail() {
  if [ "${NEXTMSG_FAIL_ON_ERROR:-false}" = "true" ]; then echo "::error::$1"; exit 1; fi
  echo "::warning::$1"; exit 0
}

key="${NEXTMSG_KEY:-}"
if [ -z "$key" ]; then fail "NextMsg: no send key. Add it as a secret and pass key: \${{ secrets.NEXTMSG_KEY }}"; fi
echo "::add-mask::$key"

message="${NEXTMSG_MESSAGE:-}"
if [ -z "$message" ]; then
  case "${NEXTMSG_STATUS:-}" in
    success) icon="✅"; word="passed" ;;
    failure) icon="❌"; word="failed" ;;
    cancelled) icon="⚪"; word="was cancelled" ;;
    "") icon="🔔"; word="finished" ;;
    *) icon="🔔"; word="${NEXTMSG_STATUS}" ;;
  esac
  ref="${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-}}"
  message="${icon} ${GITHUB_WORKFLOW:-Workflow} ${word} on \`${ref}\` (${GITHUB_REPOSITORY:-}, run #${GITHUB_RUN_NUMBER:-})"
fi

body="$(jq -cn --arg m "$message" --arg c "${NEXTMSG_CHANNEL:-ci}" '{message: ($m | .[0:640]), channel: $c}')" \
  || fail "NextMsg: could not build the request (is jq installed?)"

out="$(mktemp)"
code="$(curl -sS -o "$out" -w '%{http_code}' --max-time 20 --retry 2 --retry-delay 2 \
  -X POST "${NEXTMSG_API:-https://api.nextmsg.app}/v1/send" \
  -H "Authorization: Bearer $key" -H 'Content-Type: application/json' --data "$body")" || code="000"

echo "http-status=$code" >> "${GITHUB_OUTPUT:-/dev/null}"
if [ "$code" = "200" ]; then
  id="$(jq -r '.id // empty' "$out" 2>/dev/null)"
  echo "id=$id" >> "${GITHUB_OUTPUT:-/dev/null}"
  echo "NextMsg: sent to #${NEXTMSG_CHANNEL:-ci}"
  exit 0
fi

err="$(jq -r '.error // empty' "$out" 2>/dev/null)"
case "$code" in
  401) hint="the send key is invalid, was rotated, or its inbox was deleted; update the secret" ;;
  402) hint="the free plan's monthly limit is reached; upgrade in the app" ;;
  429) hint="rate limited; try again later" ;;
  000) hint="network error" ;;
  *) hint="${err:-unexpected response}" ;;
esac
fail "NextMsg: message not sent (HTTP $code): $hint"
