#!/usr/bin/env bash

# Show recent local audit log entries.

cmd_audit_log() {
    local lines="${1:-20}"
    [[ "$lines" =~ ^[0-9]+$ ]] || fail "audit-log lines must be a positive integer."
    [[ -f "$LOG_FILE" ]] || fail "Audit log not found at $LOG_FILE"

    echo "Recent audit log entries ($LOG_FILE):"
    echo "timestamp	actor	action	target	status	details"
    tail -n "$lines" "$LOG_FILE"
}
