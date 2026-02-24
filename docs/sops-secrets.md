# SOPS Encrypted Secrets

This guide explains how to create and use SOPS-encrypted secrets with this Helm chart.

## Prerequisites

- [SOPS](https://github.com/getsops/sops) installed.
- An encryption key (Age, PGP, AWS KMS, GCP KMS, or Azure Key Vault).

## Encrypting Bitwarden Credentials

The Helm chart expects Bitwarden credentials in your `values.yaml`. To keep these secure, you should use SOPS to encrypt a separate secrets file (e.g., `secrets.dec.yaml`) and only commit the encrypted version (`secrets.enc.yaml`).

### 1. Create your decrypted secrets file

Create a file named `secrets.dec.yaml` with your credentials:

```yaml
bitwarden:
  username: "your-email@example.com"
  password: "your-master-password"
  clientId: "your-client-id"
  clientSecret: "your-client-secret"
```

### 2. Encrypt the file

You can encrypt the file using various methods. It is highly recommended to use a `.sops.yaml` configuration file to manage your keys.

#### Using Age (Recommended for simple setups)
```bash
sops --encrypt --age <your-age-public-key> secrets.dec.yaml > secrets.enc.yaml
```

#### Using PGP
```bash
sops --encrypt --pgp <your-pgp-fingerprint> secrets.dec.yaml > secrets.enc.yaml
```

#### Using AWS KMS
```bash
sops --encrypt --kms <your-kms-arn> secrets.dec.yaml > secrets.enc.yaml
```

#### Using GCP KMS
```bash
sops --encrypt --gcp-kms <your-gcp-kms-resource-id> secrets.dec.yaml > secrets.enc.yaml
```

### 3. Using a .sops.yaml configuration (Best Practice)

Instead of passing flags every time, create a `.sops.yaml` file in the root of your project. This allows you to define which keys to use for which files.

Example `.sops.yaml`:

```yaml
creation_rules:
  - path_regex: .*\.enc\.yaml$
    # Use multiple keys for redundancy (Multi-key encryption)
    age: >-
      age1ql3z7hjy54pw3ul4lshj32atxy9690s3at38f699as898v68s9ps9sh72y,
      age123...
    pgp: >-
      1234567890ABCDEF1234567890ABCDEF12345678
    kms: 'arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012'
```

With this file in place, you can simply run:
```bash
sops --encrypt secrets.dec.yaml > secrets.enc.yaml
```

### 4. Using the encrypted secrets with Helm

The most efficient way to use SOPS-encrypted secrets with Helm is the [helm-secrets](https://github.com/jkroepke/helm-secrets) plugin.

#### Install helm-secrets

```bash
helm plugin install https://github.com/jkroepke/helm-secrets
```

#### Common Commands

| Action | Command |
| :--- | :--- |
| **Install** | `helm secrets install bitwarden-password-manager-eso . -f values.yaml -f secrets.enc.yaml` |
| **Upgrade** | `helm secrets upgrade bitwarden-password-manager-eso . -f values.yaml -f secrets.enc.yaml` |
| **Template** | `helm secrets template bitwarden-password-manager-eso . -f values.yaml -f secrets.enc.yaml` |
| **Edit** | `helm secrets edit secrets.enc.yaml` (Decrypts, opens in editor, re-encrypts on save) |
| **View** | `helm secrets view secrets.enc.yaml` (Shows decrypted content in stdout) |

#### Alternative: Manual decryption

If you cannot use the plugin, you can decrypt the file on the fly:

```bash
sops exec-file secrets.enc.yaml 'helm install bitwarden-password-manager-eso . -f values.yaml -f {}'
```

## Security Best Practices

- **Never commit `secrets.dec.yaml`** to your repository. Add it to `.gitignore`.
- **Commit `.sops.yaml`** to your repository so other contributors (and CI/CD) know which keys to use for decryption.
- Rotate your Bitwarden credentials and encryption keys periodically.
- Use a dedicated Bitwarden account with minimal permissions for this integration.
