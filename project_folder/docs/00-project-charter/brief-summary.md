# Brief summary - Project 2 (Capstone)

## Client

**LedgerPoint**, a boutique accounting firm. Staff upload client financial statements and send a link to external auditors who have no company account.

## Stated requirements

1. External auditors can open a shared file from a link **without login**.
2. Files are sensitive: **never discoverable by search engines**, **never guessable by URL**, and **not accessible indefinitely**.
3. **Every upload, download, and share** action is logged with **who** did it and **when**.
4. Cheap to run and easy for a non-technical office manager to operate.

## The contradiction to resolve

Anonymous access is required, but public access is forbidden. The design must give a stranger a temporary, unguessable capability while the storage resource itself stays private. Making the container/bucket public is **not** an acceptable solution.

## Core skill being tested

Access-control tradeoffs for storage - knowing when **not** to make something public.

## Stack allowed by the brief

Azure CLI **or** AWS CLI, Bash, Blob Storage **or** S3, IAM.

**Chosen for this implementation:** Azure CLI, Bash, Azure Blob Storage, Microsoft
Entra ID (Azure RBAC) and user delegation SAS. The AWS option was not used.
