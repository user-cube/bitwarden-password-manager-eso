# Bitwarden Password Manager ESO

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/bitwarden-password-manager-eso)](https://artifacthub.io/packages/helm/bitwarden-password-manager-eso/bitwarden-password-manager-eso)
![License](https://img.shields.io/github/license/user-cube/bitwarden-password-manager-eso)

A Helm chart that deploys a [Bitwarden CLI](https://github.com/charlesthomas/bitwarden-cli) bridge and integrates it with the [External Secrets Operator](https://external-secrets.io/) via `ClusterSecretStore`, allowing you to sync secrets from your Bitwarden vault directly into Kubernetes.

## Architecture

```
Bitwarden Vault
      │
      ▼
Bitwarden CLI Pod (port 8087)
      │
      ▼
ClusterSecretStore (ESO Webhook Provider)
      │
      ▼
ExternalSecret → Kubernetes Secret
```

1. **Bitwarden CLI Pod** — runs the CLI in `serve` mode, exposing a local REST API on port 8087.
2. **Kubernetes Service** — provides a stable in-cluster endpoint for the CLI pod.
3. **ClusterSecretStore** — configured as a Webhook provider that queries the CLI API.
4. **External Secrets Operator** — orchestrates syncing from Bitwarden into Kubernetes Secrets.

## Prerequisites

- [External Secrets Operator](https://external-secrets.io/) installed in your cluster.
- A Bitwarden account with API access enabled.

## Installation

```bash
helm repo add bitwarden-password-manager-eso https://user-cube.github.io/bitwarden-password-manager-eso
helm repo update
```

For SOPS-encrypted credentials (recommended):

```bash
helm secrets install bitwarden-password-manager-eso bitwarden-password-manager-eso/bitwarden-password-manager-eso \
  -f values.yaml -f secrets.enc.yaml
```

## Default ClusterSecretStores

| Store | JSONPath | Use case |
|---|---|---|
| `bitwarden-login` | `$.data.login.username` | Usernames |
| `bitwarden-password` | `$.data.login.password` | Passwords |
| `bitwarden-fields` | `$.data.fields` | Custom fields |
| `bitwarden-notes` | `$.data.notes` | Secure notes |
| `bitwarden-attachments` | `$.data.attachments` | Attachments |

## Example ExternalSecret

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-app-credentials
spec:
  refreshInterval: "1h"
  secretStoreRef:
    name: bitwarden-password
    kind: ClusterSecretStore
  target:
    name: my-app-k8s-secret
    creationPolicy: Owner
  data:
    - secretKey: password
      remoteRef:
        key: "your-bitwarden-item-uuid"
```

The `remoteRef.key` is the UUID of the item in your Bitwarden vault (visible in the web vault URL).

## Documentation

Full documentation is available at the project docs site:

- [Getting Started](docs/index.md)
- [Usage Guide](docs/usage.md)
- [SOPS Secrets](docs/sops-secrets.md)
- [Configuration](docs/configuration.md)
- [Development](docs/development.md)

## Helm Chart Reference

For the full values reference see the [chart README](charts/bitwarden-password-manager-eso/README.md) or [ArtifactHub](https://artifacthub.io/packages/helm/bitwarden-password-manager-eso/bitwarden-password-manager-eso).

## License

[Apache 2.0](LICENSE)
