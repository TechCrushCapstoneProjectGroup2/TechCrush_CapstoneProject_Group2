# Access policy (as built)

| Principal | Permission on files | Permission on audit log | Reason |
| --- | --- | --- | --- |
| Staff / office manager (via CLI) | upload, download, list, delete, share, revoke | read | Operate the tool with Entra login + RBAC |
| Auditor (via link) | read **one object** until expiry | none | Brief requires no account and no trail access |
| Anonymous internet | none | none | Must stay private / non-discoverable |

## RBAC assigned by the deployment

| Role | Scope | Why |
| --- | --- | --- |
| Storage Blob Data Contributor | storage account | lets the CLI upload/download/list/delete with `--auth-mode login` |
| Storage Blob Delegator | storage account | lets the issuer create user delegation SAS with `--as-user` |
| Additional principals from `TEAM_BLOB_CONTRIBUTOR_IDS` | storage account | other staff who need data access |
| Additional principals from `SAS_ISSUER_PRINCIPAL_IDS` | storage account | other staff allowed to issue links |

## Assertions to run after provisioning

1. Anonymous `list` on the container -> **denied (403)**.
2. Anonymous `GET` on a random object name -> **denied (403)**.
3. Public blob access setting -> **off**; container public access -> **null/private**.
4. Shared key access -> **off**; HTTPS-only -> **on**; minimum TLS -> **1.2**.
5. A generated SAS link opens one blob anonymously -> **200**.
6. After `revoke-share`, the same link -> **denied (403)**.

Steps 1 and 3-6 are automated by `bash tests/integration/run.sh`. Save manual outputs
to `evidence/logs/deploy/` and redact them before committing.
