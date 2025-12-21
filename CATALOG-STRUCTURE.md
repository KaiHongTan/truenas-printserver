# TrueNAS Scale Catalog Structure

This document explains the catalog structure required by TrueNAS Scale.

## Directory Structure

```
truenas-printserver/              (GitHub repository root)
│
├── catalog.json                  ← REQUIRED: Catalog metadata
│
├── trains/                       ← Contains all trains (chart collections)
│   │
│   ├── charts.json              ← REQUIRED: Train index file
│   │
│   └── charts/                  ← The "charts" train
│       │
│       └── truenas-printserver/  ← Your application
│           │
│           ├── app.yaml          ← App metadata (name, icon, categories)
│           │
│           ├── Chart.yaml        ← Symlink or copy of latest version
│           ├── values.yaml       ← Symlink or copy of latest version
│           ├── questions.yaml    ← Symlink or copy of latest version  
│           ├── templates/        ← Symlink or copy of latest version
│           │
│           └── 1.0.0/           ← Version directory (semver format)
│               │
│               ├── Chart.yaml            ← Helm chart metadata
│               ├── values.yaml           ← Default values
│               ├── questions.yaml        ← TrueNAS UI form definition
│               ├── ix_values.yaml        ← TrueNAS-specific overrides
│               ├── app-readme.md         ← Shown in TrueNAS UI
│               ├── item.yaml             ← Additional metadata
│               │
│               └── templates/            ← Kubernetes templates
│                   ├── deployment.yaml
│                   ├── service.yaml
│                   ├── pvc.yaml
│                   └── _helpers.tpl
│
├── docker/                      ← Docker image source code
│   ├── Dockerfile
│   └── ...
│
├── .github/                     ← GitHub Actions
│   └── workflows/
│       └── docker-build.yml
│
├── README.md
├── SETUP.md
├── LICENSE
└── icon.svg
```

## Key Files Explained

### catalog.json (Root)
```json
{
  "name": "TrueNAS Print Server Catalog",
  "description": "Network print server catalog",
  "maintainers": [...],
  "home": "https://github.com/KaiHongTan/truenas-printserver"
}
```
**Purpose**: Identifies this as a valid TrueNAS catalog.

### trains/charts.json
```json
{
  "truenas-printserver": {
    "name": "truenas-printserver",
    "latest_version": "1.0.0",
    "location": "trains/charts/truenas-printserver",
    "categories": ["networking", "media"],
    ...
  }
}
```
**Purpose**: Indexes all apps in the "charts" train.

### trains/charts/truenas-printserver/app.yaml
```yaml
name: truenas-printserver
categories:
  - networking
  - media
icon_url: https://...
app_readme: |
  Description shown in TrueNAS UI...
```
**Purpose**: Metadata displayed in TrueNAS Discover Apps.

### trains/charts/truenas-printserver/1.0.0/Chart.yaml
```yaml
apiVersion: v2
name: truenas-printserver
version: 1.0.0
appVersion: "1.0.0"
description: Network print server
```
**Purpose**: Standard Helm chart metadata.

### trains/charts/truenas-printserver/1.0.0/questions.yaml
```yaml
groups:
  - name: "Network Configuration"
    description: "Configure network settings"
questions:
  - variable: networking.hostNetwork
    label: "Use Host Network"
    schema:
      type: boolean
      default: true
```
**Purpose**: Defines the TrueNAS UI installation form.

### trains/charts/truenas-printserver/1.0.0/ix_values.yaml
```yaml
# TrueNAS-specific value overrides
image:
  repository: ghcr.io/KaiHongTan/truenas-printserver
  tag: latest
```
**Purpose**: Default values specifically for TrueNAS installations.

## How TrueNAS Uses This Structure

1. **Add Catalog**: TrueNAS reads `catalog.json` to validate the catalog
2. **Sync Catalog**: TrueNAS reads `trains/charts.json` to find all apps
3. **Display Apps**: TrueNAS reads `app.yaml` for each app to show in UI
4. **Install App**: TrueNAS uses files from `1.0.0/` directory to deploy
5. **Show UI Form**: TrueNAS reads `questions.yaml` to build installation form
6. **Deploy**: TrueNAS uses Helm to install using `Chart.yaml`, `values.yaml`, and `templates/`

## Version Management

Each version of your app should have its own directory:

```
trains/charts/truenas-printserver/
├── 1.0.0/
├── 1.0.1/
└── 1.1.0/
```

TrueNAS will show the latest version (from `charts.json: latest_version`)

## Adding New Versions

To add version 1.0.1:

1. Copy `1.0.0/` to `1.0.1/`
2. Update `1.0.1/Chart.yaml` version to `1.0.1`
3. Update `trains/charts.json` latest_version to `1.0.1`
4. Update root-level files (Chart.yaml, values.yaml, etc.) to point to 1.0.1
5. Commit and push

## Common Mistakes

❌ **Missing catalog.json in root**
```
Error: Not a valid catalog
```

❌ **Missing trains/charts.json**
```
Error: Train not found
```

❌ **Version mismatch**
```yaml
# Directory name: 1.0.0
# But Chart.yaml says: version: 1.0.1
Error: Version mismatch
```

❌ **Package not public**
```
Error: Failed to pull image ghcr.io/...
```

## Validation

Before pushing to GitHub:

```bash
# Check catalog.json is valid JSON
cat catalog.json | python3 -m json.tool

# Check trains/charts.json is valid JSON
cat trains/charts.json | python3 -m json.tool

# Check Chart.yaml version matches directory
cat trains/charts/truenas-printserver/1.0.0/Chart.yaml | grep "version:"

# Check all required files exist
ls -la trains/charts/truenas-printserver/1.0.0/
```

## Testing Locally

You can test the Helm chart before pushing:

```bash
# Lint the chart
helm lint trains/charts/truenas-printserver/1.0.0/

# Template the chart (see what will be deployed)
helm template test trains/charts/truenas-printserver/1.0.0/ --values trains/charts/truenas-printserver/1.0.0/values.yaml

# Install locally (requires Kubernetes cluster)
helm install test trains/charts/truenas-printserver/1.0.0/
```

## Resources

- TrueNAS Scale Documentation: https://www.truenas.com/docs/scale/
- TrueNAS Community Catalog: https://github.com/truenas/charts
- Helm Documentation: https://helm.sh/docs/
