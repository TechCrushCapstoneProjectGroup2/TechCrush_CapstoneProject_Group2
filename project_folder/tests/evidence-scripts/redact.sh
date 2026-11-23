#!/usr/bin/env bash

# Redact SAS tokens, signed URLs, emails, object IDs and account names.
# Usage:
#   redact.sh <file> [file ...]
#   cat input.log | redact.sh
#   redact.sh -o output.txt input.log

set -Eeuo pipefail

usage() {
    echo "Usage: redact.sh [-o output] [file ...]" >&2
}

output=""
if [[ "${1:-}" == "-o" ]]; then
    output="${2:-}"
    [[ -n "$output" ]] || { usage; exit 1; }
    shift 2
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

if (( $# > 0 )); then
    cat "$@" > "$tmp"
else
    cat > "$tmp"
fi

sed_args=(
    -E
    -e 's#https?://[^[:space:]]*[?&]sig=[^[:space:]]+#<REDACTED-SAS-URL>#g'
    -e 's#([?&](sig|se|sp|sv|sr|st|skoid|sktid|ske|skt|skv|sip)=)[^&[:space:]]+#\1REDACTED#g'
    -e 's#[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}#<REDACTED-EMAIL>#g'
    -e 's#[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}#<REDACTED-ID>#g'
)

if [[ -n "${STORAGE_ACCOUNT:-}" ]]; then
    sed_args+=( -e "s#${STORAGE_ACCOUNT}#<REDACTED-ACCOUNT>#g" )
fi

sed "${sed_args[@]}" "$tmp" > "$tmp.redacted"
mv "$tmp.redacted" "$tmp"

if [[ -n "$output" ]]; then
    mkdir -p "$(dirname "$output")"
    mv "$tmp" "$output"
    trap - EXIT
else
    cat "$tmp"
fi
