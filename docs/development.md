# Development & Contributions

This project uses **Semantic Release** to automate versioning and package publishing.

## Conventional Commits

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification for all pull requests and commits. This allows us to automatically:

1.  Determine the next version number (patch, minor, or major).
2.  Generate a `CHANGELOG.md` file.
3.  Publish GitHub releases.

### Commit Message Format

Each commit message should consist of a **header**, a **body**, and a **footer**. The header has a special format that includes a **type**, a **scope**, and a **subject**:

```text
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

### Common Types

-   `feat`: A new feature (triggers a **minor** release).
-   `fix`: A bug fix (triggers a **patch** release).
-   `docs`: Documentation only changes.
-   `style`: Changes that do not affect the meaning of the code.
-   `refactor`: A code change that neither fixes a bug nor adds a feature.
-   `perf`: A code change that improves performance.
-   `test`: Adding missing tests or correcting existing tests.
-   `chore`: Changes to the build process or auxiliary tools and libraries.

### Breaking Changes

A breaking change must be indicated by a `!` after the type/scope or by adding `BREAKING CHANGE:` in the footer. This triggers a **major** release.

Example:
```text
feat!: overhaul the secret store configuration
```

## Release Workflow

When a commit is pushed to the `main` or `master` branch, a GitHub Action is triggered that utilizes reusable workflows from `user-cube/reusable-cicd`.

The release pipeline will:
1.  Analyze the commits using Conventional Commits.
2.  Update the `version` in `Chart.yaml` (via `semantic-release-helm`).
3.  Generate/update the chart `CHANGELOG.md` and the root `CHANGELOG.md`.
4.  Commit those changes back to the repository using a dedicated GitHub App identity.
5.  Create a GitHub Tag and Release.
6.  Package and publish the Helm chart to the `gh-pages` branch and to GHCR (via the `helm-releaser` reusable workflow).
7.  Rebuild and publish the MkDocs documentation into `gh-pages/docs` (via the `helm-docs-publish` reusable workflow) whenever a new release is created.

## Artifact Hub Integration

To list this chart on [Artifact Hub](https://artifacthub.io/):

1.  **Hosting**: The chart is automatically packaged and hosted on the `gh-pages` branch of this repository by the `Release Charts` workflow.
2.  **Registration**:
    - Go to Artifact Hub and log in.
    - Click **Control Panel** > **Add Repository**.
    - Kind: **Helm charts**.
    - Name: `bitwarden-password-manager-eso`.
    - URL: `https://bitwarden-password-manager-eso.ruicoelho.dev/`.
3.  **Metadata**: Branding, maintainer info, and categories are managed via the `artifacthub-pkg.yml` file in the root of the repository.

### Updating Changes

Artifact Hub will automatically pick up changes from the `artifacthub.io/changes` annotation in `artifacthub-pkg.yml`.

### Required Secrets

To function correctly, the repository must have the following secrets configured (used by the reusable workflow):
- `DEVOPS_BUDDY_APP_ID`: The ID of the GitHub App used for automation.
- `DEVOPS_BUDDY_PRIVATE_KEY`: The private key of the GitHub App.
