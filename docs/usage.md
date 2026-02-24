# Usage Guide

This guide explains how to use the `ClusterSecretStore` created by this chart to fetch secrets from Bitwarden into your Kubernetes namespace.

## How it works

The Helm chart deploys a Bitwarden CLI instance and automatically creates several `ClusterSecretStore` resources. These stores use the [ESO Webhook Provider](https://external-secrets.io/latest/provider/webhook/) to talk to the Bitwarden CLI bridge.

## Default ClusterSecretStores

By default, the chart creates the following `ClusterSecretStore` resources:

- `bitwarden-login`: For fetching usernames.
- `bitwarden-password`: For fetching passwords.
- `bitwarden-fields`: For fetching custom fields.
- `bitwarden-notes`: For fetching notes.
- `bitwarden-attachments`: For fetching attachments.

## Creating an ExternalSecret

To fetch a secret from Bitwarden, create an `ExternalSecret` resource in your namespace.

### Example: Fetching a Login (Username and Password)

The `remoteRef.key` should be the **ID** of the item in your Bitwarden vault. You can find this ID in the Bitwarden web vault URL or via the CLI.

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-app-credentials
spec:
  refreshInterval: "1h"
  secretStoreRef:
    name: bitwarden-password # Use the appropriate store
    kind: ClusterSecretStore
  target:
    name: my-app-k8s-secret # The name of the Secret to create in K8s
    creationPolicy: Owner
  data:
    - secretKey: password
      remoteRef:
        key: "your-bitwarden-item-uuid"
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-app-username
spec:
  refreshInterval: "1h"
  secretStoreRef:
    name: bitwarden-login
    kind: ClusterSecretStore
  target:
    name: my-app-k8s-username
  data:
    - secretKey: username
      remoteRef:
        key: "your-bitwarden-item-uuid"
```

## Finding the Bitwarden Item UUID

1. Log in to the Bitwarden Web Vault.
2. Click on the item you want to use.
3. Look at the URL in your browser. It will look like: `https://vault.bitwarden.com/#/vault?itemID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`.
4. The string after `itemID=` is your UUID.

## Periodic Vault Sync

The Bitwarden CLI bridge needs to be synced with the Bitwarden cloud to pick up changes (e.g., when you update a password in the web vault).

This chart includes an optional `CronJob` that can trigger this sync periodically.

### Enabling Sync

To enable the sync CronJob, update your `values.yaml`:

```yaml
sync:
  enabled: true
  schedule: "0 * * * *" # Every hour (standard cron expression)
```

### Manual Sync

You can also trigger a sync manually at any time by running a curl command from within the cluster:

```bash
kubectl run curl --image=curlimages/curl -i --tty --rm -- \
  curl -X POST http://bitwarden-password-manager-eso.default.svc.cluster.local:8087/sync
```
