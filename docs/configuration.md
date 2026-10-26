# Configuration & Security

This page explains the security features and configuration options available in this Helm chart.

## ServiceAccount

By default, the chart creates a dedicated `ServiceAccount` for the Bitwarden CLI bridge.

### Why a dedicated ServiceAccount?

Even though the Bitwarden CLI doesn't directly interact with the Kubernetes API, a dedicated identity is crucial for:

1.  **Cloud Identity (IRSA / Workload Identity)**: If you are using SOPS with a cloud provider's KMS (like AWS KMS, GCP KMS, or Azure Key Vault), the Pod needs permission to access that KMS. This is typically achieved by annotating the `ServiceAccount` with an IAM role.
2.  **Security Isolation**: It follows the principle of least privilege. Using the `default` service account is discouraged as it may have broader permissions than intended.
3.  **Auditability**: Actions performed by the Pod are clearly identified in Kubernetes audit logs under the specific `ServiceAccount` name.

### Configuration

```yaml
serviceAccount:
  create: true
  annotations:
    # Example for AWS IRSA
    # eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/my-sops-kms-role
  name: "" # Leave empty to use the fullname template
```

## Security Context

To follow security best practices, you should run the Bitwarden CLI with a restricted security context.

### Hardening Example

You can configure these in your `values.yaml`:

```yaml
podSecurityContext:
  fsGroup: 2000

securityContext:
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000
```

## Resource Management

It is highly recommended to set resource requests and limits to ensure cluster stability. The default values are conservative but should be adjusted based on your vault size and usage.

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    memory: 256Mi
```

## Origin protection (`bw serve`)

Recent Bitwarden CLI versions reject any request whose `Host` header isn't `localhost`. Requests from External Secrets Operator go through the Kubernetes Service, so they all get `403`.

By default the chart starts the container with the same steps as the image's `entrypoint.sh` and adds `--disable-origin-protection` to `bw serve`:

```yaml
bwServe:
  disableOriginProtection: true # default
```

Set it to `false` to run the image's own `entrypoint.sh` unchanged. If you set `command` or `args`, they take precedence and this option is ignored.

Only the Service exposes `bw serve`; restrict who can reach it (for example with a NetworkPolicy that allows only the External Secrets Operator namespace).

## Network policy

`bw serve` returns the unlocked vault to anyone who can reach the Service, without authentication. Enable the bundled NetworkPolicy so only External Secrets Operator (and the sync CronJob) can reach it:

```yaml
networkPolicy:
  enabled: true
  allowedNamespaces:
    - external-secrets # namespace where ESO runs
  extraFrom: []        # extra NetworkPolicyPeer entries
```

It only restricts ingress; egress to your Bitwarden server is untouched. Your CNI must enforce NetworkPolicies.

## Existing credentials Secret

Instead of putting credentials in values (with SOPS), point the chart at a Secret you manage yourself (sealed-secrets, a bootstrap ExternalSecret, Vault, ...):

```yaml
bitwarden:
  existingSecret: bitwarden-credentials
```

The Secret must contain `BW_HOST`, `BW_USER`, `BW_PASSWORD` and optionally `BW_CLIENTID`/`BW_CLIENTSECRET`. With the chart-managed Secret, the Deployment restarts automatically when credentials change; with `existingSecret` it does not, so use a tool such as Reloader.

