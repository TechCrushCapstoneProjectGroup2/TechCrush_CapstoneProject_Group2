# Command implementations

Each file implements exactly one verb dispatched by `../dispatcher.sh`:
`upload.sh`, `download.sh`, `list.sh`, `delete.sh`, `share.sh`, `revoke-share.sh`
and `audit-log.sh`.

Keep them thin: validate -> storage operation -> audit write -> human-readable
output. No credential handling here.
