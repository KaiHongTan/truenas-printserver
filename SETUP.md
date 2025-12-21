# GitHub Setup Guide

Complete guide to setting up your TrueNAS Print Server repository on GitHub.

## Repository Structure

Your repository follows TrueNAS Scale's catalog structure:

```
truenas-printserver/
├── catalog.json                    # Catalog metadata (REQUIRED)
├── trains/
│   ├── charts.json                # Train index
│   └── charts/
│       └── truenas-printserver/
│           ├── app.yaml           # App metadata
│           ├── Chart.yaml         # Latest version symlink
│           ├── values.yaml        # Latest version symlink
│           ├── questions.yaml     # Latest version symlink
│           ├── templates/         # Latest version symlink
│           └── 1.0.0/            # Versioned release
│               ├── Chart.yaml
│               ├── values.yaml
│               ├── questions.yaml
│               ├── ix_values.yaml
│               ├── templates/
│               ├── app-readme.md
│               └── item.yaml
├── docker/                        # Docker image source
└── .github/workflows/             # Auto-build configuration
```

## Quick Start

```bash
# 1. Extract and navigate
tar -xzf truenas-printserver-github.tar.gz
cd github-repo

# 2. Replace KaiHongTan with your GitHub username
find . -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.json" -o -name "*.md" \) \
  -exec sed -i 's/KaiHongTan/your-github-username/g' {} +

# 3. Initialize and push to GitHub
git init
git add .
git commit -m "Initial commit: TrueNAS Print Server"
git remote add origin https://github.com/your-github-username/truenas-printserver.git
git push -u origin main

# 4. Enable GitHub Actions in repository settings
# 5. Make container package public after first build
# 6. Add catalog to TrueNAS
```

See full instructions below for detailed steps.

## Step-by-Step Setup

### Step 1: Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `truenas-printserver`
3. Visibility: **Public** (required)
4. Do NOT initialize with README
5. Click **Create repository**

### Step 2: Update KaiHongTan

```bash
cd github-repo
find . -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.json" -o -name "*.md" \) \
  -exec sed -i 's/KaiHongTan/your-actual-username/g' {} +
```

### Step 3: Push to GitHub

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/KaiHongTan/truenas-printserver.git
git branch -M main
git push -u origin main
```

### Step 4: Enable GitHub Actions

1. Repository → **Actions** tab
2. Click "I understand my workflows, go ahead and enable them"
3. Wait for Docker build to complete (~5 minutes)

### Step 5: Make Package Public

1. Profile → **Packages** → **truenas-printserver**
2. **Package settings** → **Change visibility** → **Public**

### Step 6: Add to TrueNAS

**In TrueNAS:**
```
Apps → Manage Catalogs → Add Catalog
Name: TrueNAS Print Server
Repository: https://github.com/KaiHongTan/truenas-printserver
Branch: main
Preferred Trains: charts
```

### Step 7: Install from Catalog

```
Apps → Discover Apps → Search "print"
Install → Configure → Install
```

## Troubleshooting

### Catalog shows "Invalid catalog"

**Fix**: Ensure `catalog.json` exists in repository root:
```bash
curl https://raw.githubusercontent.com/KaiHongTan/truenas-printserver/main/catalog.json
```

### App not appearing in Discover Apps

**Fix**: Verify trains structure:
```bash
# Should return valid JSON
curl https://raw.githubusercontent.com/KaiHongTan/truenas-printserver/main/trains/charts.json
```

### Docker image not pulling

**Fix**: Ensure package is Public (Step 5)

## File Checklist

Required files:
- ✅ `catalog.json` (root)
- ✅ `trains/charts.json`
- ✅ `trains/charts/truenas-printserver/app.yaml`
- ✅ `trains/charts/truenas-printserver/1.0.0/Chart.yaml`
- ✅ `trains/charts/truenas-printserver/1.0.0/values.yaml`
- ✅ `trains/charts/truenas-printserver/1.0.0/questions.yaml`
- ✅ `trains/charts/truenas-printserver/1.0.0/templates/*.yaml`

## Support

For detailed troubleshooting, see full documentation in repository.
