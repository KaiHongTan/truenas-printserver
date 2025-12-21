# Setup Instructions for GitHub

Follow these steps to set up your TrueNAS Print Server repository on GitHub.

## 1. Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `truenas-printserver`
3. Description: "All-in-one network print server for TrueNAS Scale"
4. Public repository (required for GitHub Container Registry)
5. Click "Create repository"

## 2. Clone and Push This Code

```bash
# Initialize git in this directory
cd /path/to/github-repo
git init
git add .
git commit -m "Initial commit: TrueNAS Print Server"

# Add your GitHub repository as remote
# Replace KaiHongTan with your GitHub username
git remote add origin https://github.com/KaiHongTan/truenas-printserver.git

# Push to GitHub
git branch -M main
git push -u origin main
```

## 3. Update Repository URLs

After creating your repository, update these files with your GitHub username:

**Files to update:**
- `.github/workflows/docker-build.yml` - Already configured to use your repo
- `charts/truenas-printserver/Chart.yaml` - Update home URL
- `charts/truenas-printserver/values.yaml` - Update image repository
- `charts/truenas-printserver/questions.yaml` - Update image repository
- `charts/truenas-printserver/item.yaml` - Update icon URL
- `charts/truenas-printserver/app-readme.md` - Update links
- `README.md` - Update all KaiHongTan placeholders
- `trains.yaml` - Update all URLs

**Find and replace:**
```bash
# Replace KaiHongTan with your actual GitHub username
find . -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.md" \) -exec sed -i 's/KaiHongTan/your-actual-username/g' {} +
```

## 4. Enable GitHub Actions

1. Go to your repository on GitHub
2. Click "Actions" tab
3. Click "I understand my workflows, go ahead and enable them"

The Docker image will automatically build and push to GitHub Container Registry (ghcr.io) when you push code.

## 5. Make Repository Package Public

After the first GitHub Actions run:

1. Go to your GitHub profile
2. Click "Packages"
3. Find "truenas-printserver"
4. Click on the package
5. Click "Package settings" (right sidebar)
6. Scroll to "Danger Zone"
7. Click "Change visibility" → "Public"
8. Confirm

## 6. Add to TrueNAS Scale

### Option A: Add as Custom Catalog (Recommended)

1. In TrueNAS Scale, go to **Apps** → **Manage Catalogs**
2. Click **Add Catalog**
3. Fill in:
   - **Name**: `TrueNAS Print Server`
   - **Repository**: `https://github.com/KaiHongTan/truenas-printserver`
   - **Branch**: `main`
   - **Preferred Trains**: `charts`
4. Click **Save**
5. Wait for catalog to sync (check status in catalog list)
6. Go to **Discover Apps**
7. Search for "TrueNAS Print Server"
8. Click **Install**

### Option B: Install via Helm (Advanced)

```bash
# SSH to TrueNAS
ssh root@truenas-ip

# Add repository
helm repo add truenas-printserver https://KaiHongTan.github.io/truenas-printserver
helm repo update

# Install
helm install printserver truenas-printserver/truenas-printserver \
  --namespace ix-printserver \
  --create-namespace \
  --set image.repository=ghcr.io/KaiHongTan/truenas-printserver
```

## 7. Verify Installation

1. Check that the Docker image is building:
   - Go to "Actions" tab in your GitHub repository
   - You should see a workflow running
   - Wait for it to complete (usually 2-5 minutes)

2. Verify the image exists:
   - Go to your repository
   - Click "Packages" in the right sidebar
   - You should see "truenas-printserver"

3. Test deployment in TrueNAS:
   - Install the app from catalog
   - Check pod status: `kubectl get pods -n ix-printserver`
   - Check logs: `kubectl logs -n ix-printserver -l app.kubernetes.io/name=truenas-printserver`

## 8. Configure Your Printer

1. Access CUPS web interface:
   - Host Network mode: `http://[NAS-IP]:631`
   - NodePort mode: `http://[NAS-IP]:30631`

2. Add printer:
   - Administration → Add Printer
   - Select your USB printer
   - ✅ Check "Share This Printer"
   - Choose appropriate driver
   - Done!

## Troubleshooting

### GitHub Actions failing?
- Make sure your repository is public
- Check Actions logs for specific errors
- Ensure workflow file is in `.github/workflows/` directory

### Docker image not building?
- Check GitHub Actions tab for errors
- Verify you're pushing to main/master branch
- Check workflow triggers in `.github/workflows/docker-build.yml`

### Can't pull image in TrueNAS?
- Make sure package is set to "Public" in GitHub
- Verify image name in values.yaml matches your repository
- Check: `docker pull ghcr.io/KaiHongTan/truenas-printserver:latest`

### Catalog not showing in TrueNAS?
- Verify repository URL is correct
- Check catalog status in "Manage Catalogs"
- Make sure branch is set to "main"
- Wait a few minutes for sync to complete

### App not appearing in Discover Apps?
- Refresh the catalog in "Manage Catalogs"
- Clear TrueNAS cache: `midclt call catalog.sync_all`
- Check catalog logs: `kubectl logs -n ix -l app=catalog`

## Optional: Enable GitHub Pages (for Helm repository)

1. Go to repository **Settings** → **Pages**
2. Source: "GitHub Actions"
3. This allows using `helm repo add` commands

## Support

If you encounter issues:
1. Check GitHub Actions logs
2. Check TrueNAS catalog sync status
3. Review pod logs in TrueNAS
4. Open an issue on GitHub with details

## Next Steps

After successful setup:
- ⭐ Star your repository
- 📝 Customize README.md with your details
- 🎨 Create a custom icon (replace icon.svg)
- 📢 Share with the community!
