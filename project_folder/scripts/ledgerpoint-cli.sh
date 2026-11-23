#!/usr/bin/env bash

# Entry point for the LedgerPoint CLI.
# Layout and configuration: scripts/README.md

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/dispatcher.sh" "$@"
