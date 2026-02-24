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
