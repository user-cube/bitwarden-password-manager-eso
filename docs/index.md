# Bitwarden Password Manager ESO

Welcome to the documentation for the Bitwarden Password Manager integration with External Secrets Operator (ESO).

This Helm chart deploys a Bitwarden CLI instance that can be used by ESO to fetch secrets from your Bitwarden vault.

## Key Features

- **Bitwarden CLI Integration**: Connects directly to your Bitwarden vault.
- **External Secrets Operator Support**: Seamlessly integrates with ESO via `ClusterSecretStore`.
- **Secure Secret Management**: Encourages the use of SOPS for encrypting sensitive credentials within your GitOps repository.

## Architecture

1. **Bitwarden CLI Pod**: Runs the Bitwarden CLI in "serve" mode, exposing a local API on port 8087.
2. **Kubernetes Service**: Provides a stable endpoint for the CLI Pod.
3. **ClusterSecretStore**: Configured as a Webhook provider that queries the CLI Pod's API.
4. **External Secrets Operator**: Orchestrates the sync between the Bitwarden "API" and your Kubernetes Secrets.

## Getting Started

To get started, you'll need to:

1. Configure your Bitwarden credentials.
2. Encrypt those credentials using SOPS.
3. Deploy the Helm chart.

Check the [SOPS Secrets](sops-secrets.md) page for detailed instructions on encrypting your credentials.
