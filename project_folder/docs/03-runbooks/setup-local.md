# Local setup

1. Install Git, Bash, Azure CLI (`az`) and `shellcheck`.
2. Clone the repo and run `cp .env.example .env`.
3. Set `STORAGE_ACCOUNT` to a globally unique Azure name. Never commit `.env`.
4. Run `az login` with the project subscription/account.
5. Run `bash scripts/ledgerpoint-cli.sh help`.
6. Confirm the storage account/container name is globally unique and that public access is disabled before deploying.
