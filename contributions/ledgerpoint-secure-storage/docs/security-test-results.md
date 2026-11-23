# LedgerPoint Security Test Results

## Test Environment

Date: 2026-11-23
Cloud Provider: Microsoft Azure
Storage Account: lpg21795439984
Authentication: Microsoft Entra ID

## SEC-001: Anonymous Access Denial

Expected: Unauthorized requests cannot retrieve the document.

Observed:
HTTP 409
Azure error: PublicAccessNotPermitted

Result: PASS

## SEC-002: Authorized SAS Access

Expected: A valid read-only SAS allows file retrieval.

Observed:
HTTP 200

Result: PASS

## SEC-003: SAS Expiration

Expected: Access is denied after the signed expiry time.

Observed:
Before expiry: HTTP 200
After expiry: HTTP 403

Result: PASS

## SEC-004: Early Share Revocation

Expected: Deleting the temporary sharing copy prevents
further retrieval while preserving the original document.

Observed:
Before deletion: HTTP 200
Temporary blob exists after deletion: false
After deletion: HTTP 404
Original blob exists: true

Result: PASS

## INT-001: File Integrity

Expected: Uploaded and downloaded document contents match.

Observed:
SHA-256 hashes matched.
Byte-for-byte comparison passed.

Result: PASS

## Security Notes

- The original container remains private.
- Shared Key authorization remains disabled.
- SAS tokens are never included in evidence files.
- Deleting a temporary blob does not invalidate its SAS signature.
- Revocation does not erase previously downloaded copies.
- These are manual test results, not Azure diagnostic audit logs.
