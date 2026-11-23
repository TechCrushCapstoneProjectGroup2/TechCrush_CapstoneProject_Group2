# Office manager guide (plain English)

This guide is deliberately jargon-free. It is for the person who will actually run the tool after the team hands over.

## Upload a statement

1. Open a terminal in the project folder.
2. Type: `bash scripts/ledgerpoint-cli.sh upload "path/to/statement.pdf"`
3. Write down the **file ID** shown on the screen. You will need it to share the file.

## Share a file with an auditor

1. Type: `bash scripts/ledgerpoint-cli.sh share <blob-name> [hours]`
2. The tool prints a **one-time link**. Copy it and email it to the auditor.
3. The link stops working automatically after the agreed number of hours. Do not reuse or forward it.

## Stop a link early

If you sent a link to the wrong person, type: `bash scripts/ledgerpoint-cli.sh revoke-share` and ask the team to confirm the link no longer works (see `revoke-share.md`).

## See what has happened

Type `bash scripts/ledgerpoint-cli.sh list` to see files, or ask the team to show you the audit log (see `log-review.md`).

## What never to do

- Never turn on "public access" for the storage container/bucket.
- Never paste a share link into a team chat, document, or screenshot without redacting it.
- Never email the tool's configuration file.
