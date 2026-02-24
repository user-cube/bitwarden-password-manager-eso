# Bitwarden Password Manager ESO

[![MkDocs](https://img.shields.io/badge/docs-MkDocs-blue.svg)](docs/index.md)

A Helm chart to deploy a Bitwarden CLI bridge for [External Secrets Operator (ESO)](https://external-secrets.io/).

## Overview

This project provides a simple way to bridge Bitwarden with Kubernetes using ESO. It deploys the Bitwarden CLI in a way that allows ESO's `ClusterSecretStore` to interact with it, enabling you to manage your Kubernetes secrets directly from Bitwarden.

## Documentation

Comprehensive documentation is available in the `docs/` directory or can be viewed via MkDocs.

- [Getting Started](docs/index.md)
- [Usage Guide](docs/usage.md)
- [Configuration & Security](docs/configuration.md)
- [SOPS Secrets Configuration](docs/sops-secrets.md)
- [Development & Contributions](docs/development.md)

## Quick Start

1. Add your Bitwarden credentials to a SOPS-encrypted file.
2. Install the Helm chart:

```bash
helm install bitwarden-eso . -f values.yaml -f secrets.enc.yaml
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
