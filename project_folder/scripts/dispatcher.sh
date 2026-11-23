#!/usr/bin/env bash

# Routes CLI commands to one cmd_* function per file in commands/.

set -Eeuo pipefail
IFS=$'\n\t'
umask 077

CLI_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "$CLI_DIR/common.sh"

for command_file in \
    "$CLI_DIR/commands/upload.sh" \
    "$CLI_DIR/commands/download.sh" \
    "$CLI_DIR/commands/list.sh" \
    "$CLI_DIR/commands/delete.sh" \
    "$CLI_DIR/commands/share.sh" \
    "$CLI_DIR/commands/revoke-share.sh" \
    "$CLI_DIR/commands/audit-log.sh"; do
    # shellcheck source=/dev/null
    source "$command_file"
done

main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        upload|download|list|delete|share|revoke-share)
            require_environment
            ;;
        audit-log)
            init_audit_log
            ;;
        help|-h|--help)
            usage
            exit 0
            ;;
        *)
            usage >&2
            fail "Unknown command: $command"
            ;;
    esac

    case "$command" in
        upload)       cmd_upload "$@" ;;
        download)     cmd_download "$@" ;;
        list)         cmd_list "$@" ;;
        delete)       cmd_delete "$@" ;;
        share)        cmd_share "$@" ;;
        revoke-share) cmd_revoke_share "$@" ;;
        audit-log)    cmd_audit_log "$@" ;;
    esac
}

main "$@"
