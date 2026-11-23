# Incident response

When something breaks or an access-control concern appears:

1. **Contain**: revoke the affected link, disable public access if accidentally enabled, rotate any exposed credential.
2. **Preserve evidence**: copy command output and screenshots into `evidence/` before changing state further (redact tokens).
3. **Open an issue** with the Bug or Security template.
4. **Investigate in order**, writing down what each check ruled in or out.
5. **Fix**, then prove before/after with commands and screenshots.
6. **Write the report** using `docs/04-incident-reports/_TEMPLATE.md`. All five sections are mandatory:
   Symptom, Investigation trail, Root cause, Fix, Design reflection.
7. **Update the design** if the failure exposed a design weakness, not just a bad fix. Add a line to the relevant ADR.

The brief explicitly requires this report even after the system is working and demoed.
