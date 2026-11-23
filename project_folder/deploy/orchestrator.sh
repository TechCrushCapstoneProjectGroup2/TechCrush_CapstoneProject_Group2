#!/usr/bin/env bash

# Runs each step-*.sh function in order. Each step file defines one step_* function.

set -Eeuo pipefail
IFS=$'\n\t'
umask 077

DEPLOY_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "$DEPLOY_DIR/common.sh"

for step_file in \
    "$DEPLOY_DIR/step-00-prerequisites.sh" \
    "$DEPLOY_DIR/step-01-resource-group.sh" \
    "$DEPLOY_DIR/step-02-storage-account.sh" \
    "$DEPLOY_DIR/step-03-rbac.sh" \
    "$DEPLOY_DIR/step-04-container.sh" \
    "$DEPLOY_DIR/step-05-log-analytics.sh" \
    "$DEPLOY_DIR/step-06-diagnostics.sh" \
    "$DEPLOY_DIR/step-07-verify.sh" \
    "$DEPLOY_DIR/step-08-summary.sh"; do
    # shellcheck source=/dev/null
    source "$step_file"
done

trap handle_error ERR

main() {
    step_prerequisites
    step_resource_group
    step_storage_account
    step_rbac
    step_container
    step_log_analytics
    step_diagnostics
    step_verify
    step_summary
}

main "$@"
