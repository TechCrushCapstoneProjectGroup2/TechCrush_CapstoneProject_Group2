# Deploy (automated, end-to-end)

1. Confirm Phase 0 ADRs are accepted and `.env` is filled in locally.
2. `bash deploy/deploy.sh` - creates resource group/storage and the private audit destination.
3. Verify private-by-default: anonymous request to the container/bucket must be **denied**. Save output to `evidence/logs/deploy/`.
4. `bash tests/integration/run.sh` - private check -> upload -> share -> download -> revoke -> denied.
5. `bash tests/evidence-scripts/capture-expired-link.sh` - expired-link proof.
6. Capture the three mandatory screenshots into `evidence/screenshots/`.
7. Copy a redacted full upload-to-share audit cycle into `audit/samples/`.
8. Record the deploy output/version in `evidence/logs/deploy/` and link it from the demo doc.

If any step fails, stop and open an issue using the Bug or Security template before continuing.
